import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/comment/comment.dart';
import 'package:rpmtw_server/database/models/comment/comment_type.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import "package:test/test.dart";

import "../../test_utility.dart";

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
          passwordHash: "testPassword1234",
          email: "test@gmail.com",
          username: "test",
          emailVerified: true,
          uuid: Uuid().v4(),
          loginIPs: []);
      await user.insert();
      token = AuthHandler.generateAuthToken(user.uuid);
      userUUID = user.uuid;

      /// Add a test source text.
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: "Hello, World!",
          gameVersions: [],
          key: "test.title.hello_world",
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
        content: "Great translation!",
        type: CommentType.translate,
        userUUID: userUUID,
        parentUUID: mockSourceTextUUID,
        createdAt: Utility.getUTCTime(),
        updatedAt: Utility.getUTCTime(),
        isHidden: false);

    await comment.insert();

    return comment.uuid;
  }

  group("add comment", () {
    test("add comment (translate type)", () async {
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: "Hello, World!",
          gameVersions: [],
          key: "test.title.hello_world",
          type: SourceTextType.general);

      await source.insert();

      final response = await post(Uri.parse(host + "/comment/"),
          headers: {"Authorization": "Bearer $token"},
          body: json.encode({
            "content": "Great translation!",
            "parentUUID": source.uuid,
            "type": "translate",
          }));

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)["data"];
      expect(data["content"], "Great translation!");
      expect(data["parentUUID"], source.uuid);
      expect(data["type"], "translate");
      expect(data["userUUID"], userUUID);

      await source.delete();
    });
    test("add comment (translate type, unknown parent uuid)", () async {
      final response = await post(Uri.parse(host + "/comment/"),
          headers: {"Authorization": "Bearer $token"},
          body: json.encode({
            "content": "Great translation!",
            "parentUUID": "test",
            "type": "translate",
          }));

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson["message"], contains("not found"));
    });

    test("add comment (wiki type)", () async {
      MinecraftMod mod = MinecraftMod(
          uuid: Uuid().v4(),
          name: "test",
          id: "test",
          supportVersions: [],
          relationMods: [],
          integration: ModIntegrationPlatform(),
          side: [],
          createTime: Utility.getUTCTime(),
          lastUpdate: Utility.getUTCTime());

      await mod.insert();

      final response = await post(Uri.parse(host + "/comment/"),
          headers: {"Authorization": "Bearer $token"},
          body: json.encode({
            "content": "Very interesting mod!",
            "parentUUID": mod.uuid,
            "type": "wiki",
          }));

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)["data"];
      expect(data["content"], "Very interesting mod!");
      expect(data["parentUUID"], mod.uuid);
      expect(data["type"], "wiki");
      expect(data["userUUID"], userUUID);

      await mod.delete();
    });

    test("add comment (wiki type, unknown parent uuid)", () async {
      final response = await post(Uri.parse(host + "/comment/"),
          headers: {"Authorization": "Bearer $token"},
          body: json.encode({
            "content": "Very interesting mod!",
            "parentUUID": "test",
            "type": "wiki",
          }));

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson["message"], contains("not found"));
    });

    test("add comment (empty content)", () async {
      final SourceText source = SourceText(
          uuid: Uuid().v4(),
          source: "Hello, World!",
          gameVersions: [],
          key: "test.title.hello_world",
          type: SourceTextType.general);

      await source.insert();

      final response = await post(Uri.parse(host + "/comment/"),
          headers: {"Authorization": "Bearer $token"},
          body: json.encode({
            "content": " ",
            "parentUUID": source.uuid,
            "type": "translate",
          }));

      expect(response.statusCode, 400);
      final Map responseJson = json.decode(response.body);
      expect(responseJson["message"], contains("cannot be empty"));

      await source.delete();
    });
  });

  group("get/list comment", () {
    test("get comment", () async {
      final commentUUID = await addTestComment();

      final response = await get(
        Uri.parse(host + "/comment/$commentUUID"),
      );

      expect(response.statusCode, 200);
      final Map data = json.decode(response.body)["data"];
      expect(data["uuid"], commentUUID);
      expect(data["content"], "Great translation!");
      expect(data["type"], "translate");
      expect(data["userUUID"], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });

    test("get comment (unknown uuid)", () async {
      final response = await get(Uri.parse(host + "/comment/test"),
          headers: {"Authorization": "Bearer $token"});

      expect(response.statusCode, 404);
      final Map responseJson = json.decode(response.body);
      expect(responseJson["message"], contains("not found"));
    });

    test("list comment", () async {
      final commentUUID = await addTestComment();

      final response = await get(
        Uri.parse(host + "/comment/").replace(queryParameters: {
          "type": "translate",
          "parentUUID": mockSourceTextUUID
        }),
      );

      expect(response.statusCode, 200);
      final List data = json.decode(response.body)["data"];
      expect(data.length, 1);
      expect(data[0]["uuid"], commentUUID);
      expect(data[0]["content"], "Great translation!");
      expect(data[0]["type"], "translate");
      expect(data[0]["userUUID"], userUUID);

      (await Comment.getByUUID(commentUUID))!.delete();
    });
  });
}
