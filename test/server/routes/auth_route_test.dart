import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/models/auth/ban_category.dart';
import 'package:rpmtw_server/database/models/auth/ban_info.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';
import '../../test_utility.dart';

void main() async {
  final host = TestUttily.host;

  setUpAll(() => TestUttily.setUpAll());
  tearDownAll(() => TestUttily.tearDownAll());

  test('valid password', () async {
    String password = 'passWord123';
    final response =
        await get(Uri.parse(host + '/auth/valid-password?password=$password'));
    Map body = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(body['isValid'], isTrue);
    expect(body['code'], 0);
    expect(body['message'], contains('no issue'));
  });

  test('valid auth code', () async {
    AuthCode code =
        await AuthHandler.generateAuthCode('test@gmail.com', Uuid().v4());

    final response = await get(Uri.parse(host +
        '/auth/valid-auth-code?authCode=${code.code}&email=${code.email}'));
    Map body = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(body['isValid'], isTrue);
  });

  group('User', () {
    final String password = 'passWord123';
    final String email = 'helloworld@gmail.com';
    final String username = 'helloworld';

    late String avatarStorageUUID;
    late User testUser;

    setUpAll(() async {
      testUser = User(
          uuid: Uuid().v4(),
          email: email,
          username: username,
          passwordHash: AuthHandler.generatePasswordHash(password),
          emailVerified: false,
          loginIPs: ['127.0.0.1']);
      await testUser.insert();
    });

    test('create avatar storage', () async {
      Response rpmtwLogoResponse = await get(Uri.parse(
          'https://raw.githubusercontent.com/RPMTW/RPMTW-Data/main/logo/rpmtw-logo.png'));

      final response = await post(Uri.parse(host + '/storage/create'),
          body: rpmtwLogoResponse.bodyBytes,
          headers: {'Content-Type': 'image/png'});

      Map data = json.decode(response.body)['data'];
      avatarStorageUUID = data['uuid'];
      expect(response.statusCode, 200);
    });
    test('create user', () async {
      final response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            'password': password,
            'email': 'helloworld2@gmail.com',
            'username': username,
            'avatarStorageUUID': avatarStorageUUID
          }),
          headers: {'Content-Type': 'application/json'});

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['avatarStorageUUID'], avatarStorageUUID);
      expect(data['email'], 'helloworld2@gmail.com');
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });
    test('view user by uuid', () async {
      final response = await get(
        Uri.parse(host + '/auth/user/${testUser.uuid}'),
      );

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], testUser.uuid);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });

    test('view user by email', () async {
      final response = await get(
        Uri.parse(host + '/auth/user/get-by-email/$email'),
      );

      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], testUser.uuid);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });
    test('get token', () async {
      final response = await post(
        Uri.parse(host + '/auth/get-token'),
        body: json.encode({
          'uuid': testUser.uuid,
          'password': password,
        }),
      );
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], testUser.uuid);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
      expect(data['token'], isNotNull);
    });
    test('view user by token', () async {
      final response = await get(Uri.parse(host + '/auth/user/me'), headers: {
        'Authorization':
            'Bearer ${AuthHandler.generateAuthToken(testUser.uuid)}',
      });
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], testUser.uuid);
      expect(data['email'], email);
      expect(data['username'], username);
      expect(data['emailVerified'], isFalse);
    });

    final String newPassword = 'newPassword123';
    final String newEmail = 'abcd@gmail.com';
    final String newUsername = 'abcd';

    test('update user', () async {
      final response1 = await post(Uri.parse(host + '/auth/user/me/update'),
          body: json.encode({
            'uuid': testUser.uuid,
            'password': password,
            'newPassword': newPassword,
            'newEmail': newEmail,
            'newUsername': newUsername,
            'newAvatarStorageUUID': avatarStorageUUID
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${AuthHandler.generateAuthToken(testUser.uuid)}'
          });

      Map data1 = json.decode(response1.body)['data'];
      expect(response1.statusCode, 200);
      expect(data1['uuid'], testUser.uuid);
      expect(data1['email'], newEmail);
      expect(data1['username'], newUsername);
      expect(data1['emailVerified'], isFalse);

      /// Check if the user info is updated
      final response2 = await get(
        Uri.parse(host + '/auth/user/${testUser.uuid}'),
      );
      Map data2 = json.decode(response2.body)['data'];

      expect(response2.statusCode, 200);
      expect(data2['uuid'], testUser.uuid);
      expect(data2['email'], newEmail);
      expect(data2['username'], newUsername);
      expect(data2['emailVerified'], isFalse);
    });
    test('create user (duplicate email)', () async {
      final response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            'password': newPassword,
            'email': newEmail,
            'username': newUsername,
            'avatarStorageUUID': avatarStorageUUID
          }),
          headers: {'Content-Type': 'application/json'});

      Map data = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(data['message'], contains('already been used'));
    });
    test('user ip is banned', () async {
      /// 由於目前尚未新增任何觸發 Ban 的條件，因此暫時手動新增一個測試用假資料
      final BanInfo banInfo = BanInfo(
          ip: '127.0.0.1',
          reason: 'test ban',
          category: BanCategory.permanent,
          userUUID: [testUser.uuid],
          uuid: Uuid().v4());
      await banInfo.insert();

      final response = await get(Uri.parse(host + '/auth/user/me'), headers: {
        'Authorization':
            'Bearer ${AuthHandler.generateAuthToken(testUser.uuid)}'
      });
      Map data = json.decode(response.body);

      expect(response.statusCode, 403);
      expect(data['message'], contains('Banned'));
      expect(data['data']['reason'], contains('test ban'));
      expect(data['data']['category'], contains('permanent'));
    });
  });
}
