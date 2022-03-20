import "dart:convert";
import "dart:io";
import "dart:typed_data";

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import "package:http/http.dart" as http;
import "package:rpmtw_server/database/models/auth/user.dart";
import 'package:rpmtw_server/database/models/auth_route.dart';
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/data.dart";
import "package:rpmtw_server/utilities/utility.dart";
import "package:shelf/shelf.dart";
import "package:shelf_router/shelf_router.dart";

extension StringCasingExtension on String {
  /// 將字串第一個字轉為大寫
  /// hello world -> Hello world
  String toCapitalized() =>
      isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";

  /// 將字串每個開頭字母轉成大寫
  /// hello world -> Hello World
  String toTitleCase() => replaceAll(RegExp(" +"), " ")
      .split(" ")
      .map((str) => str.toCapitalized())
      .join(" ");

  String toTitleCaseWithSpace() {
    RegExp regExp = RegExp("[A-Z]");
    List<int> matches = regExp.allMatches(this).map((e) => e.start).toList();

    return splitMapJoin(regExp, onMatch: ((match) {
      String str = match.input.substring(match.start, match.end);
      if (matches.indexOf(match.start) == 0) {
        return str;
      } else {
        return " ${str.toLowerCase()}";
      }
    }));
  }

  bool get isEnglish {
    RegExp regExp = RegExp(r"\w+\s*$");
    return regExp.hasMatch(this);
  }

  bool toBool() => this == "true";

  bool get isAllEmpty => isEmpty || trim().isEmpty;
}

extension RequestExtension on Request {
  String get ip {
    String? xForwardedFor = headers["X-Forwarded-For"];
    if (xForwardedFor != null && kTestMode) {
      return xForwardedFor;
    } else {
      String? cfIP = headers["CF-Connecting-IP"];
      if (cfIP != null) {
        return cfIP;
      }

      HttpConnectionInfo connectionInfo =
          context["shelf.io.connection_info"] as HttpConnectionInfo;
      InternetAddress internetAddress = connectionInfo.remoteAddress;
      return internetAddress.address;
    }
  }

  bool isAuthenticated() {
    return context["isAuthenticated"] == true && context["user"] is User;
  }

  User? get user {
    try {
      return context["user"] as User;
    } catch (e) {
      return null;
    }
  }
}

typedef RouteHandler = Future<Response> Function(Request req, RouteData data);

extension RouterExtension on Router {
  void addRoute(String verb, String route, RouteHandler handler,
      List<String> requiredFields, AuthConfig? authConfig) {
    Future<Response> _handler(Request request) async {
      try {
        if (authConfig != null) {
          String path = request.requestedUri.path;
          if (authConfig.path == null ||
              (authConfig.path != null && authConfig.path!.startsWith(path))) {
            String? token = request.headers["Authorization"]
                ?.toString()
                .replaceAll("Bearer ", "");

            if (token == null) {
              return APIResponse.unauthorized();
            }

            try {
              User? user = await User.getByToken(token);
              String clientIP = request.ip;
              if (user == null) {
                return APIResponse.unauthorized();
              } else if (!user.emailVerified && !kTestMode) {
                // 驗證是否已經驗證電子郵件，測試模式不需要驗證
                return APIResponse.unauthorized(
                    message: "Unauthorized (email not verified)");
              }

              List<String> loginIPs = user.loginIPs;

              /// 如果此登入IP尚未被紀錄過
              if (!loginIPs.contains(clientIP)) {
                loginIPs.add(clientIP);
                User _newUser = user.copyWith(loginIPs: loginIPs);

                /// 寫入新的登入IP
                await _newUser.update();
              }

              request = request
                  .change(context: {"user": user, "isAuthenticated": true});

              if (!user.role.permission.hasPermission(authConfig.role)) {
                return APIResponse.forbidden();
              }
            } on JWTError catch (e) {
              logger.e(e.message, null, e.stackTrace);
              return APIResponse.unauthorized();
            } catch (e, stack) {
              logger.e(e, null, stack);
              return APIResponse.internalServerError();
            }
          }
        }

        Uint8List bytes = await http.ByteStream(request.read()).toBytes();
        Map<String, dynamic>? bodyJson;
        try {
          bodyJson = json
              .decode((request.encoding ?? utf8).decode(bytes))
              .cast<String, dynamic>();
        } catch (e) {
          // ignore
        }

        final Map<String, dynamic> fields = Map.from(request.method == "GET"
            ? request.requestedUri.queryParameters
            : bodyJson ?? {})
          ..addAll(request.params);

        final bool validateFields =
            Utility.validateRequiredFields(fields, requiredFields);
        if (!validateFields) {
          return APIResponse.missingRequiredFields();
        } else {
          return await handler(request, RouteData(fields, bytes));
        }
      } catch (e, stack) {
        logger.e(e, null, stack);
        return APIResponse.badRequest();
      }
    }

    add(verb, route, _handler);
  }

  void getRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const [], AuthConfig? authConfig}) {
    return addRoute("GET", route, handler, requiredFields, authConfig);
  }

  void postRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const [], AuthConfig? authConfig}) {
    return addRoute("POST", route, handler, requiredFields, authConfig);
  }

  void patchRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const [], AuthConfig? authConfig}) {
    return addRoute("PATCH", route, handler, requiredFields, authConfig);
  }

  void deleteRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const [], AuthConfig? authConfig}) {
    return addRoute("DELETE", route, handler, requiredFields, authConfig);
  }
}

class RouteData {
  final Map<String, dynamic> fields;
  final Uint8List bytes;

  Stream<List<int>> get byteStream => http.ByteStream.fromBytes(bytes);

  RouteData(this.fields, this.bytes);
}
