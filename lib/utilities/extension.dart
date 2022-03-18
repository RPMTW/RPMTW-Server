import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:http/http.dart" as http;
import "package:rpmtw_server/database/models/auth/user.dart";
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
      List<String> requiredFields) {
    Future<Response> _handler(Request request) async {
      try {
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
      {List<String> requiredFields = const []}) {
    return addRoute("GET", route, handler, requiredFields);
  }

  void postRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute("POST", route, handler, requiredFields);
  }

  void patchRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute("PATCH", route, handler, requiredFields);
  }

  void deleteRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute("DELETE", route, handler, requiredFields);
  }
}

class RouteData {
  final Map<String, dynamic> fields;
  final Uint8List bytes;

  Stream<List<int>> get byteStream => http.ByteStream.fromBytes(bytes);

  RouteData(this.fields, this.bytes);
}
