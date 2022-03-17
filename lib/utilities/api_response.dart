import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'dart:io';

class APIResponse {
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
