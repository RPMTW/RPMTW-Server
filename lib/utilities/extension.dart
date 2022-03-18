import 'dart:convert';
import 'dart:io';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

extension StringCasingExtension on String {
  /// 將字串第一個字轉為大寫
  /// hello world -> Hello world
  String toCapitalized() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  /// 將字串每個開頭字母轉成大寫
  /// hello world -> Hello World
  String toTitleCase() => replaceAll(RegExp(" +"), " ")
      .split(" ")
      .map((str) => str.toCapitalized())
      .join(" ");

  String toUpperCaseWithSpace() =>
      split(RegExp("[A-Z]")).map((str) => str.toUpperCase()).join(" ");

  bool get isEnglish {
    RegExp regExp = RegExp(r'\w+\s*$');
    return regExp.hasMatch(this);
  }

  bool toBool() => this == "true";
}

extension RequestExtension on Request {
  String get ip {
    String? xForwardedFor = headers['X-Forwarded-For'];
    if (xForwardedFor != null && kTestMode) {
      return xForwardedFor;
    } else {
      String? cfIP = headers['CF-Connecting-IP'];
      if (cfIP != null) {
        return cfIP;
      }

      HttpConnectionInfo connectionInfo =
          context['shelf.io.connection_info'] as HttpConnectionInfo;
      InternetAddress internetAddress = connectionInfo.remoteAddress;
      return internetAddress.address;
    }
  }

  bool isAuthenticated() {
    return context['isAuthenticated'] == true && context['user'] is User;
  }

  User? get user {
    try {
      return context['user'] as User;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> get data async {
    return json.decode(await readAsString());
  }
}

typedef RouteHandler = Future<Response> Function(Request req, RouteData data);

extension RouterExtension on Router {
  void addRoute(String verb, String route, RouteHandler handler,
      List<String> requiredFields) {
    Future<Response> _handler(Request request) async {
      try {
        final Map<String, dynamic> fields = request.params.isEmpty
            ? request.method == "GET"
                ? request.requestedUri.queryParameters
                : await request.data
            : request.params;

        final bool validateFields =
            Utility.validateRequiredFields(fields, requiredFields);

        if (!validateFields) {
          return APIResponse.missingRequiredFields();
        } else {
          return await handler(request, RouteData(fields: fields));
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
    return addRoute('GET', route, handler, requiredFields);
  }

  void postRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute('POST', route, handler, requiredFields);
  }

  void patchRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute('PATCH', route, handler, requiredFields);
  }

  void deleteRoute(String route, RouteHandler handler,
      {List<String> requiredFields = const []}) {
    return addRoute('DELETE', route, handler, requiredFields);
  }
}

class RouteData {
  final Map<String, dynamic> fields;

  RouteData({required this.fields});
}
