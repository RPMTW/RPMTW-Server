import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/comment/comment.dart';
import 'package:rpmtw_server/database/models/comment/comment_type.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final host = TestUttily.host;

  late final String token;
  late final String userUUID;
  late final String mockSourceTextUUID;

  setUpAll(() {
    return Future.sync(() async {
      await TestUttily.setUpAll();

      /// Create a test user account.
      final user = User(
          passwordHash: 'testPassword1234',
          email: 'test@gmail.com',
          username: 'test',
          emailVerified: true,
          uuid: Uuid().v4(),
          loginIPs: []);
      await user.insert();
      token = AuthHandler.generateAuthToken(user.uuid);
      userUUID = user.uuid;

      /// Add a test source text.
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: 'Hello, World!',
          gameVersions: [],
          key: 'test.title.hello_world',
          type: SourceTextType.general);

      await source.insert();

      mockSourceTextUUID = source.uuid;
    });
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  Future<String> addTestComment() async {
    final Comment comment = Comment(
        uuid: Uuid().v4(),
        content: 'Great translation!',
        type: CommentType.translate,
        userUUID: userUUID,
        parentUUID: mockSourceTextUUID,
        createdAt: RPMTWUtil.getUTCTime(),
        updatedAt: RPMTWUtil.getUTCTime(),
        isHidden: false);

    await comment.insert();

    return comment.uuid;
  }

  group('add comment', () {
    test('add comment (translate type)', () async {
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: 'Hello, World!',
          gameVersions: [],
          key: 'test.title.hello_world',
          type: SourceTextType.general);

      await source.insert();

      final response = await post(Uri.parse(host + '/comment/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': 'Great translation!',
            'parentUUID': source.uuid,
            'type': 'translate',
          }));

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)['data'];
      expect(data['content'], 'Great translation!');
      expect(data['parentUUID'], source.uuid);
      expect(data['type'], 'translate');
      expect(data['userUUID'], userUUID);

      await source.delete();
    });
    test('add comment (translate type, unknown parent uuid)', () async {
      final response = await post(Uri.parse(host + '/comment/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': 'Great translation!',
            'parentUUID': 'test',
            'type': 'translate',
          }));

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('add comment (wiki type)', () async {
      MinecraftMod mod = MinecraftMod(
          uuid: Uuid().v4(),
          name: 'test',
          id: 'test',
          supportVersions: [],
          relationMods: [],
          integration: ModIntegrationPlatform(),
          side: [],
          createTime: RPMTWUtil.getUTCTime(),
          lastUpdate: RPMTWUtil.getUTCTime());

      await mod.insert();

      final response = await post(Uri.parse(host + '/comment/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': 'Very interesting mod!',
            'parentUUID': mod.uuid,
            'type': 'wiki',
          }));

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)['data'];
      expect(data['content'], 'Very interesting mod!');
      expect(data['parentUUID'], mod.uuid);
      expect(data['type'], 'wiki');
      expect(data['userUUID'], userUUID);

      await mod.delete();
    });

    test('add comment (wiki type, unknown parent uuid)', () async {
      final response = await post(Uri.parse(host + '/comment/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': 'Very interesting mod!',
            'parentUUID': 'test',
            'type': 'wiki',
          }));

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('add comment (empty content)', () async {
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: 'Hello, World!',
          gameVersions: [],
          key: 'test.title.hello_world',
          type: SourceTextType.general);

      await source.insert();

      final response = await post(Uri.parse(host + '/comment/'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': ' ',
            'parentUUID': source.uuid,
            'type': 'translate',
          }));

      expect(response.statusCode, 400);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('cannot be empty'));

      await source.delete();
    });
  });

  group('get/list comment', () {
    test('get comment', () async {
      final commentUUID = await addTestComment();

      final response = await get(
        Uri.parse(host + '/comment/$commentUUID'),
      );

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)['data'];
      expect(data['uuid'], commentUUID);
      expect(data['content'], 'Great translation!');
      expect(data['type'], 'translate');
      expect(data['userUUID'], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('get comment (unknown uuid)', () async {
      final response = await get(Uri.parse(host + '/comment/test'),
          headers: {'Authorization': 'Bearer $token'});

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('list comment', () async {
      final commentUUID = await addTestComment();

      final response = await get(
        Uri.parse(host + '/comment/').replace(queryParameters: {
          'type': 'translate',
          'parentUUID': mockSourceTextUUID
        }),
      );

      expect(response.statusCode, 200);
      final List data = json.decode(response.body)['data'];
      expect(data.length, 1);
      expect(data[0]['uuid'], commentUUID);
      expect(data[0]['content'], 'Great translation!');
      expect(data[0]['type'], 'translate');
      expect(data[0]['userUUID'], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });
  });

  group('edit comment', () {
    test('edit comment', () async {
      final commentUUID = await addTestComment();

      final response = await patch(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': 'This translation has a typo, please fix it.',
        }),
      );

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)['data'];
      expect(data['uuid'], commentUUID);
      expect(data['content'], 'This translation has a typo, please fix it.');
      expect(data['type'], 'translate');
      expect(data['userUUID'], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('edit comment (unknown uuid)', () async {
      final response = await patch(Uri.parse(host + '/comment/test'),
          headers: {'Authorization': 'Bearer $token'},
          body: json.encode({
            'content': 'This translation has a typo, please fix it.',
          }));

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('edit comment (empty content)', () async {
      final commentUUID = await addTestComment();

      final response = await patch(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': ' ',
        }),
      );

      expect(response.statusCode, 400);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('cannot be empty'));

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('edit comment (not owner)', () async {
      final commentUUID = await addTestComment();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            'password': 'testPassword1234',
            'email': 'test1@gmail.com',
            'username': 'test1',
          }),
          headers: {'Content-Type': 'application/json'});
      String _token = json.decode(_response.body)['data']['token'];

      final response = await patch(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $_token'},
        body: json.encode({
          'content': 'This translation has a typo, please fix it.',
        }),
      );

      expect(response.statusCode, 403);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('cannot edit'));

      (await Comment.getByUUID(commentUUID))!.delete();
    });
  });

  group('delete comment', () {
    test('delete comment', () async {
      final commentUUID = await addTestComment();

      final response = await delete(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(response.statusCode, 200);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], 'success');
      expect((await Comment.getByUUID(commentUUID))?.isHidden, true);

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('delete comment (unknown uuid)', () async {
      final response = await delete(Uri.parse(host + '/comment/test'),
          headers: {'Authorization': 'Bearer $token'});

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('delete comment (not owner)', () async {
      final commentUUID = await addTestComment();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            'password': 'testPassword1234',
            'email': 'test2@gmail.com',
            'username': 'test2',
          }),
          headers: {'Content-Type': 'application/json'});
      String _token = json.decode(_response.body)['data']['token'];

      final response = await delete(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      expect(response.statusCode, 403);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('cannot delete'));

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('delete reply comment', () async {
      final commentUUID = await addTestComment();

      /// reply comment
      await post(
        Uri.parse(host + '/comment/$commentUUID/reply'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': 'Thank you.',
        }),
      );

      final response = await delete(
        Uri.parse(host + '/comment/$commentUUID'),
        headers: {'Authorization': 'Bearer $token'},
      );

      expect(response.statusCode, 200);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], 'success');
      expect((await Comment.getByUUID(commentUUID))?.isHidden, true);

      (await Comment.getByUUID(commentUUID))!.delete();
    });
  });

  group('reply comment', () {
    test('reply comment', () async {
      final commentUUID = await addTestComment();

      final response = await post(
        Uri.parse(host + '/comment/$commentUUID/reply'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': 'Thank you.',
        }),
      );

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)['data'];
      expect(data['uuid'], isNotNull);
      expect(data['content'], 'Thank you.');
      expect(data['type'], 'translate');
      expect(data['userUUID'], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test('reply comment (unknown uuid)', () async {
      final response = await post(
        Uri.parse(host + '/comment/test/reply'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': 'Thank you.',
        }),
      );

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('not found'));
    });

    test('reply comment (empty content)', () async {
      final commentUUID = await addTestComment();

      final response = await post(
        Uri.parse(host + '/comment/$commentUUID/reply'),
        headers: {'Authorization': 'Bearer $token'},
        body: json.encode({
          'content': ' ',
        }),
      );

      expect(response.statusCode, 400);
      final Map responseJson = json.decode(response.body);
      expect(responseJson['message'], contains('cannot be empty'));

      (await Comment.getByUUID(commentUUID))!.delete();
    });
  });
}
