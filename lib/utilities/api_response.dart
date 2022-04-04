import 'dart:convert';

import 'package:rpmtw_server/database/list_model_response.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:rpmtw_server/utilities/messages.dart';
import 'package:shelf/shelf.dart';
import 'dart:io';

class APIResponse {
  static const Map<String, String> _baseHeaders = {
    'content-type': 'application/json'
  };

  static Response badRequest({String message = 'Bad Request'}) =>
      Response(HttpStatus.badRequest,
          body: json.encode({
            'status': HttpStatus.badRequest,
            'message': message,
          }),
          headers: _baseHeaders);

  static Response missingRequiredFields(String fieldName) =>
      badRequest(message: '${Messages.missingRequiredFields} ($fieldName)');

  static Response fieldEmpty(String fieldName) => badRequest(
      message: '${fieldName.toTitleCaseWithSpace()} cannot be empty.');

  static Response success({required Object? data}) {
    Object? _data;
    assert(
        data is Map ||
            data is List ||
            data is ListModelResponse ||
            data == null,
        'Data must be a Map or List or ListModelResponse or null, but it is ${data.runtimeType}');

    if (data is ListModelResponse) {
      _data = data.toMap();
    } else {
      _data = data;
    }

    return Response(HttpStatus.ok,
        body: json.encode({
          'status': HttpStatus.ok,
          'message': 'success',
          if (_data != null) 'data': _data,
        }),
        headers: _baseHeaders);
  }

  static Response internalServerError() =>
      Response(HttpStatus.internalServerError,
          body: json.encode({
            'status': HttpStatus.internalServerError,
            'message': 'Internal Server Error',
          }),
          headers: _baseHeaders);

  static Response unauthorized({String message = 'Unauthorized'}) =>
      Response(HttpStatus.unauthorized,
          body: json.encode({
            'status': HttpStatus.unauthorized,
            'message': message,
          }),
          headers: _baseHeaders);

  static Response forbidden({String message = 'Forbidden'}) =>
      Response(HttpStatus.forbidden,
          body: json.encode({
            'status': HttpStatus.forbidden,
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

  static Response modelNotFound<T>({String? modelName}) =>
      notFound('${modelName ?? T.toString().toTitleCaseWithSpace()} not found');

  static Response banned({required String reason}) =>
      Response(HttpStatus.forbidden,
          body: json.encode({
            'status': HttpStatus.forbidden,
            'message': 'Banned',
            'data': {'reason': reason}
          }),
          headers: _baseHeaders);
}
