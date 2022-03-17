import 'dart:convert';
import 'dart:io';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

extension StringCasingExtension on String {
  /// 將字串第一個字轉為大寫
  /// hello world -> Hello world
  String toCapitalized() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  /// 將字串每個開頭字母轉成大寫
  /// hello world -> Hello World
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(" ")
      .map((str) => str.toCapitalized())
      .join(" ");

  bool get isEnglish {
    RegExp regExp = RegExp(r'\w+\s*$');
    return regExp.hasMatch(this);
  }

  bool toBool() => this == "true";
}

extension RequestUserExtension on Request {
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

extension RouterExtension on Router {
  void addRoute(String verb, String route, Function handler) {
    Future<Response> _handler(Request request) async {
      try {
        return handler(request);
      } catch (e, stack) {
        logger.e(e, null, stack);
        return APIResponse.badRequest();
      }
    }

    add(verb, route, _handler);
  }

  void getRoute(String route, Function handler) {
    addRoute('GET', route, handler);
  }

  void postRoute(String route, Function handler) {
    addRoute('POST', route, handler);
  }

  void patchRoute(String route, Function handler) {
    addRoute('PATCH', route, handler);
  }
}
