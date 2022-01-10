import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';
import '../../test_utility.dart';

void main() async {
  final host = 'http://0.0.0.0:8080';

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test('valid password', () async {
    String password = 'passWord123';
    final response =
        await get(Uri.parse(host + '/auth/valid-password?password=$password'));
    Map body = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(body['isValid'], isTrue);
    expect(body['code'], 0);
    expect(body['message'], contains("no issue"));
  });

  test('valid auth code', () async {
    AuthCode code =
        await AuthHandler.generateAuthCode("test@gmail.com", Uuid().v4());

    final response = await get(Uri.parse(host +
        '/auth/valid-auth-code?authCode=${code.code}&email=${code.email}'));
    Map body = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(body['isValid'], isTrue);
  });

  group("User", () {
    setUpAll(() {
      env['DATA_BASE_SecretKey'] = "testSecretKey";
    });

    final String password = 'passWord123';
    final String email = 'helloworld@gmail.com';
    final String username = 'helloworld';

    late String avatarStorageUUID;
    late String userUUID;
    late String token;
    test("create avatar storage", () async {
      Response rpmtwLogoResponse = await get(Uri.parse(
          "https://raw.githubusercontent.com/RPMTW/RPMTW-Website/main/public/Image/RPMTW_Logo.gif"));

      final response = await post(Uri.parse(host + '/storage/create'),
          body: rpmtwLogoResponse.bodyBytes,
          headers: {'Content-Type': 'image/gif'});
      Map data = json.decode(response.body)['data'];
      avatarStorageUUID = data['uuid'];
      expect(response.statusCode, 200);
    });
    test('create user', () async {
      final response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            "password": password,
            "email": email,
            "username": username,
            "avatarStorageUUID": avatarStorageUUID
          }),
          headers: {'Content-Type': 'application/json'});

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['avatarStorageUUID'], avatarStorageUUID);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);

      userUUID = data['uuid'];
    });
    test("view user by uuid", () async {
      final response = await get(
        Uri.parse(host + '/auth/user/$userUUID'),
      );

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], userUUID);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });
    test("view user by email", () async {
      final response = await get(
        Uri.parse(host + '/auth/user/get-by-email/$email'),
      );

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], userUUID);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });
    test("get token", () async {
      final response = await post(
        Uri.parse(host + '/auth/get-token'),
        body: json.encode({
          "uuid": userUUID,
          "password": password,
        }),
      );
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], userUUID);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
      expect(data['token'], isNotNull);

      token = data['token'];
    });

    final String newPassword = 'newPassword123';
    final String newEmail = 'abcd@gmail.com';
    final String newUsername = 'abcd';

    test("update user", () async {
      final response1 = await post(Uri.parse(host + '/auth/user/me/update'),
          body: json.encode({
            "uuid": userUUID,
            "password": password,
            "newPassword": newPassword,
            'newEmail': newEmail,
            'newUsername': newUsername,
            'newAvatarStorageUUID': avatarStorageUUID
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          });

      Map data1 = json.decode(response1.body)['data'];
      expect(response1.statusCode, 200);
      expect(data1['uuid'], userUUID);
      expect(data1['email'], newEmail);
      expect(data1['username'], newUsername);
      expect(data1['emailVerified'], isFalse);

      /// 檢查使用者資訊是否被更新了
      final response2 = await get(
        Uri.parse(host + '/auth/user/$userUUID'),
      );
      Map data2 = json.decode(response2.body)['data'];

      expect(response2.statusCode, 200);
      expect(data2['uuid'], userUUID);
      expect(data2['email'], newEmail);
      expect(data2['username'], newUsername);
      expect(data2['emailVerified'], isFalse);
    });
    test('create user (duplicate email)', () async {
      final response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            "password": newPassword,
            "email": newEmail,
            "username": newUsername,
            "avatarStorageUUID": avatarStorageUUID
          }),
          headers: {'Content-Type': 'application/json'});

      Map data = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(data['message'], contains("already been used"));
    });
  });
}
