import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

class ResponseExtension {
  static Response badRequest({String message = "Bad Request"}) =>
      Response(HttpStatus.badRequest,
          body: json.encode({
            'status': HttpStatus.badRequest,
            'message': message,
          }),
          headers: {'content-type': 'application/json'});

  static Response success({required Map data}) => Response(HttpStatus.ok,
      body: json.encode(
          {'status': HttpStatus.ok, 'message': 'success', 'data': data}),
      headers: {'content-type': 'application/json'});

  static Response internalServerError() =>
      Response(HttpStatus.internalServerError,
          body: json.encode({
            'status': HttpStatus.internalServerError,
            'message': 'Internal Server Error',
          }),
          headers: {'content-type': 'application/json'});

  static Response unauthorized() => Response(
        HttpStatus.unauthorized,
        body: json.encode({
          'status': HttpStatus.unauthorized,
          'message': 'Unauthorized',
        }),
      );
  static Response notFound([String message = 'Not Found']) => Response(
        HttpStatus.notFound,
        body: json.encode({
          'status': HttpStatus.notFound,
          'message': message,
        }),
      );
}
