import 'dart:convert';
import 'dart:io';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:shelf/shelf.dart';

class ResponseExtension {
  static const Map<String, String> _baseHeaders = {
    'content-type': 'application/json'
  };

  static Response badRequest({String message = "Bad Request"}) =>
      Response(HttpStatus.badRequest,
          body: json.encode({
            'status': HttpStatus.badRequest,
            'message': message,
          }),
          headers: _baseHeaders);

  static Response success({required dynamic data}) {
    assert(data is Map || data is List,
        "Data must be a Map or List, but it is ${data.runtimeType}");
    return Response(HttpStatus.ok,
        body: json.encode(
            {'status': HttpStatus.ok, 'message': 'success', 'data': data}),
        headers: _baseHeaders);
  }

  static Response internalServerError() =>
      Response(HttpStatus.internalServerError,
          body: json.encode({
            'status': HttpStatus.internalServerError,
            'message': 'Internal Server Error',
          }),
          headers: _baseHeaders);

  static Response unauthorized({String message = "Unauthorized"}) =>
      Response(HttpStatus.unauthorized,
          body: json.encode({
            'status': HttpStatus.unauthorized,
            'message': message,
          }),
          headers: _baseHeaders);
  static Response notFound([String message = 'Not Found']) =>
      Response(HttpStatus.notFound,
          body: json.encode({
            'status': HttpStatus.notFound,
            'message': message,
          }),
          headers: _baseHeaders);

  static Response banned({required String reason}) =>
      Response(HttpStatus.forbidden,
          body: json.encode({
            'status': HttpStatus.forbidden,
            'message': "Banned",
            'data': {'reason': reason}
          }),
          headers: _baseHeaders);
}

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
