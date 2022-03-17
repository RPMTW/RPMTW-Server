import 'dart:convert';

import 'package:http/http.dart';
import 'package:intl/locale.dart';
import 'package:rpmtw_server/database/models/translate/translation.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final host = TestUttily.host;
  final String mockTranslationUUID = "0d87bd04-d957-4e7c-a9b7-5eb0bb3a40c1";
  late final String token;
  late final String userUUID;

  setUpAll(() {
    return Future.sync(() async {
      await TestUttily.setUpAll();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test@gmail.com",
            "username": "test",
          }),
          headers: {'Content-Type': 'application/json'});
      Map _body = json.decode(_response.body)['data'];
      token = _body['token'];
      userUUID = _body['uuid'];

      await Translation(
              uuid: mockTranslationUUID,
              content: "你好，世界",
              language: Locale.parse("zh-TW"),
              translatorUUID: userUUID)
          .insert();
    });
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test("add translation vote", () async {
    final String type = "up";
    final response = await post(Uri.parse(host + '/translate/vote'),
        body:
            json.encode({"type": type, "translationUUID": mockTranslationUUID}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        });
    Map data = json.decode(response.body)['data'];

    expect(response.statusCode, 200);
    expect(data["type"], type);
    expect(data["translationUUID"], mockTranslationUUID);
    expect(data["userUUID"], userUUID);
  });
}
