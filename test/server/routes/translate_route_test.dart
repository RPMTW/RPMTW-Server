import "dart:convert";

import "package:http/http.dart";
import "package:intl/locale.dart";
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/auth/user.dart";
import "package:rpmtw_server/database/models/auth/user_role.dart";
import "package:rpmtw_server/database/models/translate/mod_source_info.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/handler/auth_handler.dart";
import "package:test/test.dart";

import "../../test_utility.dart";

void main() async {
  final host = TestUttily.host;
  final String mockTranslationUUID = "0d87bd04-d957-4e7c-a9b7-5eb0bb3a40c1";
  final String mockSourceTextUUID = "b1b02c50-f35c-4a99-a38f-7240e61917f1";
  late final String token;
  late final String translationManagerToken;
  late final String userUUID;

  setUpAll(() {
    return Future.sync(() async {
      await TestUttily.setUpAll();

      /// Create a test user account.
      final user1 = User(
          passwordHash: "testPassword1234",
          email: "test@gmail.com",
          username: "test",
          emailVerified: true,
          uuid: Uuid().v4(),
          loginIPs: []);
      await user1.insert();
      token = AuthHandler.generateAuthToken(user1.uuid);
      userUUID = user1.uuid;

      final user2 = User(
          passwordHash: "testPassword1234",
          email: "testManager@gmail.com",
          username: "testManager",
          emailVerified: true,
          uuid: Uuid().v4(),
          loginIPs: [],
          role: UserRole(
              roles: [UserRoleType.general, UserRoleType.translationManager]));
      await user2.insert();
      translationManagerToken = AuthHandler.generateAuthToken(user2.uuid);

      await SourceText(
              uuid: mockSourceTextUUID,
              source: "Hello, World!",
              gameVersions: [],
              key: "test.title.hello_world",
              type: SourceTextType.general)
          .insert();

      await Translation(
              sourceUUID: mockSourceTextUUID,
              uuid: mockTranslationUUID,
              content: "你好，世界！",
              language: Locale.parse("zh-TW"),
              translatorUUID: userUUID)
          .insert();
    });
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  Future<String> addTestVote() async {
    final TranslationVote vote = TranslationVote(
        uuid: Uuid().v4(),
        type: TranslationVoteType.up,
        translationUUID: mockTranslationUUID,
        userUUID: userUUID);

    await vote.insert();
    return vote.uuid;
  }

  Future<String> addTestTranslation() async {
    final Translation translation = Translation(
        sourceUUID: mockSourceTextUUID,
        uuid: Uuid().v4(),
        content: "你好，世界！",
        language: Locale.parse("zh-TW"),
        translatorUUID: userUUID);
    await translation.insert();
    return translation.uuid;
  }

  Future<String> addTestSourceText(
      {SourceTextType type = SourceTextType.general}) async {
    final SourceText source = SourceText(
        uuid: Uuid().v4(),
        source: "Hello, World!",
        gameVersions: [],
        key: "test.title.hello_world",
        type: type);
    await source.insert();
    return source.uuid;
  }

  group("translation vote", () {
    test("add translation vote", () async {
      final String type = "up";
      final response = await post(Uri.parse(host + "/translate/vote"),
          body: json
              .encode({"type": type, "translationUUID": mockTranslationUUID}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["type"], type);
      expect(data["translationUUID"], mockTranslationUUID);
      expect(data["userUUID"], userUUID);

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(data["uuid"]))!.delete();
    });

    test("add translation vote (unknown translation uuid)", () async {
      final response = await post(Uri.parse(host + "/translate/vote"),
          body: json.encode({"type": "up", "translationUUID": "test"}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("add translation vote (already voted)", () async {
      String translationVoteUUID = await addTestVote();
      final response = await post(Uri.parse(host + "/translate/vote"),
          body: json
              .encode({"type": "up", "translationUUID": mockTranslationUUID}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("already voted"));

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(translationVoteUUID))!.delete();
    });

    test("add translation vote (unauthorized)", () async {
      final response = await post(Uri.parse(host + "/translate/vote"),
          body: json.encode({"type": "up", "translationUUID": "test"}),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 401);
      expect(responseJson["message"], contains("Unauthorized"));
    });

    test("list translation vote", () async {
      String translationVoteUUID = await addTestVote();

      final response = await get(
          Uri.parse(host + "/translate/vote").replace(
              queryParameters: {"translationUUID": mockTranslationUUID}),
          headers: {"Content-Type": "application/json"});

      List<Map> data = json.decode(response.body)["data"].cast<Map>();

      expect(response.statusCode, 200);
      expect(data.length, 1);
      expect(data[0]["uuid"], translationVoteUUID);

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(translationVoteUUID))!.delete();
    });

    test("list translation vote (unknown translation uuid)", () async {
      final response = await get(
          Uri.parse(host + "/translate/vote")
              .replace(queryParameters: {"translationUUID": "test"}),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("cancel translation vote", () async {
      String translationVoteUUID = await addTestVote();

      final response = await delete(
          Uri.parse(host + "/translate/vote/$translationVoteUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");
      expect(await TranslationVote.getByUUID(translationVoteUUID), null);
    });

    test("cancel translation vote (unknown translation vote uuid)", () async {
      final response = await delete(Uri.parse(host + "/translate/vote/test"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("cancel translation vote (use a different user account)", () async {
      String translationVoteUUID = await addTestVote();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + "/auth/user/create"),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test2@gmail.com",
            "username": "test2",
          }),
          headers: {"Content-Type": "application/json"});
      String _token = json.decode(_response.body)["data"]["token"];

      final response = await delete(
          Uri.parse(host + "/translate/vote/$translationVoteUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't cancel"));

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(translationVoteUUID))!.delete();
    });
    test("edit translation vote", () async {
      String translationVoteUUID = await addTestVote();

      final response = await patch(
          Uri.parse(host + "/translate/vote/$translationVoteUUID"),
          body: json.encode({
            "type": "down",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(translationVoteUUID))!.delete();
    });

    test("edit translation vote (unknown translation vote uuid)", () async {
      final response = await patch(Uri.parse(host + "/translate/vote/test"),
          body: json.encode({
            "type": "down",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("edit translation vote (use a different user account)", () async {
      String translationVoteUUID = await addTestVote();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + "/auth/user/create"),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test3@gmail.com",
            "username": "test3",
          }),
          headers: {"Content-Type": "application/json"});
      String _token = json.decode(_response.body)["data"]["token"];

      final response = await patch(
          Uri.parse(host + "/translate/vote/$translationVoteUUID"),
          body: json.encode({
            "type": "down",
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't edit"));

      /// Delete the test translation vote.
      (await TranslationVote.getByUUID(translationVoteUUID))!.delete();
    });
  });

  group("translation", () {
    test("add translation", () async {
      final response = await post(Uri.parse(host + "/translate/translation"),
          body: json.encode({
            "sourceUUID": mockSourceTextUUID,
            "language": "zh-TW",
            "content": "你好，世界！"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["uuid"], isNotNull);
      expect(data["sourceUUID"], mockSourceTextUUID);
      expect(data["language"], "zh-TW");
      expect(data["content"], "你好，世界！");

      /// Delete the test translation.
      (await Translation.getByUUID(data["uuid"]))!.delete();
    });

    test("add translation (unknown source text uuid)", () async {
      final response = await post(Uri.parse(host + "/translate/translation"),
          body: json.encode(
              {"sourceUUID": "test", "language": "zh-TW", "content": "你好，世界！"}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("add translation (empty content)", () async {
      final response = await post(Uri.parse(host + "/translate/translation"),
          body: json.encode({
            "sourceUUID": mockSourceTextUUID,
            "language": "zh-TW",
            "content": "     "
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("content can't be empty"));
    });

    test("add translation (unsupported language)", () async {
      final response = await post(Uri.parse(host + "/translate/translation"),
          body: json.encode({
            "sourceUUID": mockSourceTextUUID,
            "language": "ja",
            "content": "こんにちは世界"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("doesn't support"));
    });

    test("add translation (unauthorized)", () async {
      final response = await post(Uri.parse(host + "/translate/translation"),
          body: json.encode(
              {"sourceUUID": "test", "language": "zh-TW", "content": "你好，世界！"}),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 401);
      expect(responseJson["message"], contains("Unauthorized"));
    });

    test("get translation", () async {
      String translationUUID = await addTestTranslation();

      final response = await get(
          Uri.parse(host + "/translate/translation/$translationUUID"),
          headers: {"Content-Type": "application/json"});

      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["uuid"], translationUUID);

      /// Delete the test translation.
      (await Translation.getByUUID(translationUUID))!.delete();
    });
    test("get translation (unknown uuid)", () async {
      final response = await get(
          Uri.parse(host + "/translate/translation/test"),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("list translation", () async {
      String translationUUID = await addTestTranslation();

      final response = await get(
          Uri.parse(host + "/translate/translation").replace(queryParameters: {
            "sourceUUID": mockSourceTextUUID,
            "language": "zh-TW"
          }),
          headers: {"Content-Type": "application/json"});

      List<Map> data = json.decode(response.body)["data"].cast<Map>();

      expect(response.statusCode, 200);
      expect(data.length, 2);
      expect(data[0]["uuid"], mockTranslationUUID);
      expect(data[1]["uuid"], translationUUID);

      /// Delete the test translation.
      (await Translation.getByUUID(translationUUID))!.delete();
    });

    test("list translation (unknown source text uuid)", () async {
      final response = await get(
          Uri.parse(host + "/translate/translation").replace(
              queryParameters: {"sourceUUID": "test", "language": "zh-TW"}),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("delete translation", () async {
      String translationUUID = await addTestTranslation();

      final response = await delete(
          Uri.parse(host + "/translate/translation/$translationUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");
      expect(await Translation.getByUUID(translationUUID), null);
    });

    test("delete translation (unknown translation uuid)", () async {
      final response = await delete(
          Uri.parse(host + "/translate/translation/test"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("delete translation (use a different user account)", () async {
      String translationUUID = await addTestTranslation();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + "/auth/user/create"),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test4@gmail.com",
            "username": "test4",
          }),
          headers: {"Content-Type": "application/json"});
      String _token = json.decode(_response.body)["data"]["token"];

      final response = await delete(
          Uri.parse(host + "/translate/translation/$translationUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't delete"));

      /// Delete the test translation.
      (await Translation.getByUUID(translationUUID))!.delete();
    });
  });
  group("source text", () {
    test("add source text", () async {
      final response = await post(Uri.parse(host + "/translate/source-text"),
          body: json.encode({
            "source": "Hello, World!",
            "gameVersions": ["1.18.2"],
            "key": "test.title.hello_world",
            "type": "general"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });

      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["uuid"], isNotNull);
      expect(data["source"], "Hello, World!");
      expect(data["key"], "test.title.hello_world");
      expect(data["type"], "general");

      /// Delete the test source text.
      await (await SourceText.getByUUID(data["uuid"]))!.delete();
    });

    test("add source text (not permission)", () async {
      final response = await post(Uri.parse(host + "/translate/source-text"),
          body: json.encode({
            "source": "Hello, World!",
            "gameVersions": ["1.18.2"],
            "key": "test.title.hello_world",
            "type": "general"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 403);
      expect(responseJson["message"], "Forbidden");
    });

    test("add source text (empty source)", () async {
      final response = await post(Uri.parse(host + "/translate/source-text"),
          body: json.encode({
            "source": "  ",
            "gameVersions": ["1.18.2"],
            "key": "test.title.hello_world",
            "type": "general"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));
    });

    test("add source text (empty gameVersions)", () async {
      final response = await post(Uri.parse(host + "/translate/source-text"),
          body: json.encode({
            "source": "Hello, World!",
            "gameVersions": [],
            "key": "test.title.hello_world",
            "type": "general"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));
    });

    test("add source text (empty key)", () async {
      final response = await post(Uri.parse(host + "/translate/source-text"),
          body: json.encode({
            "source": "Hello, World!",
            "gameVersions": ["1.18.2"],
            "key": "  ",
            "type": "general"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));
    });

    test("get source text", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await get(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          headers: {"Content-Type": "application/json"});

      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["uuid"], sourceTextUUID);

      /// Delete the test source text.
      await (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });
    test("get source text (unknown uuid)", () async {
      final response = await get(
          Uri.parse(host + "/translate/source-text/test"),
          headers: {"Content-Type": "application/json"});

      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));
    });

    test("list source text", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await get(
          Uri.parse(host + "/translate/source-text")
              .replace(queryParameters: {"limit": "10", "skip": "0"}),
          headers: {"Content-Type": "application/json"});

      List<Map> data =
          json.decode(response.body)["data"]["sources"].cast<Map>();

      expect(response.statusCode, 200);
      expect(data.length, 2);
      expect(data[1]["uuid"], sourceTextUUID);

      /// Delete the test source text.
      await (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("list source text (search by source and key)", () async {
      final response = await get(
          Uri.parse(host + "/translate/source-text").replace(queryParameters: {
            "limit": "10",
            "skip": "0",
            "source": "Hello, World!",
            "key": "test.title.hello_world"
          }),
          headers: {"Content-Type": "application/json"});

      List<Map> data =
          json.decode(response.body)["data"]["sources"].cast<Map>();

      expect(response.statusCode, 200);
      expect(data.length, 1);
    });

    test("list source text (limit 100)", () async {
      final response = await get(
          Uri.parse(host + "/translate/source-text")
              .replace(queryParameters: {"limit": "100", "skip": "0"}),
          headers: {"Content-Type": "application/json"});

      Map data = json.decode(response.body)["data"];

      expect(response.statusCode, 200);
      expect(data["limit"], 50);
      expect(data["skip"], 0);
      expect(data["sources"].length, 1);
    });

    test("edit source text", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({
            "source": "RPMTW is the best!",
            "gameVersions": ["1.12.2", "1.18.2"],
            "key": "test.patchouli.rpmtw",
            "type": "patchouli"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");
      expect(responseJson["data"]["source"], "RPMTW is the best!");
      expect(responseJson["data"]["key"], "test.patchouli.rpmtw");
      expect(responseJson["data"]["type"], "patchouli");

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (not permission)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({
            "source": "RPMTW is the best!",
            "gameVersions": ["1.12.2", "1.18.2"],
            "key": "test.patchouli.rpmtw",
            "type": "patchouli"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 403);
      expect(responseJson["message"], "Forbidden");

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (unknown uuid)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response =
          await patch(Uri.parse(host + "/translate/source-text/test"),
              body: json.encode({
                "source": "RPMTW is the best!",
                "gameVersions": ["1.12.2", "1.18.2"],
                "key": "test.patchouli.rpmtw",
                "type": "patchouli"
              }),
              headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (empty source)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({
            "source": "",
            "gameVersions": ["1.12.2", "1.18.2"],
            "key": "test.patchouli.rpmtw",
            "type": "patchouli"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (empty game versions)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({
            "source": "RPMTW is the best!",
            "gameVersions": [],
            "key": "test.patchouli.rpmtw",
            "type": "patchouli"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (empty key)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({
            "source": "RPMTW is the best!",
            "gameVersions": ["1.12.2", "1.18.2"],
            "key": "   ",
            "type": "patchouli"
          }),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("can't be empty"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("edit source text (all is empty)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await patch(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          body: json.encode({}),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(responseJson["message"], contains("need to provide"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("delete source text", () async {
      String sourceTextUUID = await addTestSourceText();
      SourceFile file = SourceFile(
          uuid: Uuid().v4(),
          modSourceInfoUUID: Uuid().v4(),
          storageUUID: Uuid().v4(), // TODO: change to real storage uuid
          path: "assets/test/lang/en_us.json",
          type: SourceFileType.gsonLang,
          sources: [sourceTextUUID]);
      await file.insert();

      final response = await delete(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");
      expect(await SourceText.getByUUID(sourceTextUUID), null);

      await file.delete();
    });

    test("delete source text (not permission)", () async {
      final response = await delete(
          Uri.parse(host + "/translate/source-text/test"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 403);
      expect(responseJson["message"], "Forbidden");
    });

    test("delete source text (unknown uuid)", () async {
      String sourceTextUUID = await addTestSourceText();

      final response = await delete(
          Uri.parse(host + "/translate/source-text/test"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 404);
      expect(responseJson["message"], contains("not found"));

      /// Delete the test source text.
      (await SourceText.getByUUID(sourceTextUUID))!.delete();
    });

    test("delete source text (type is patchouli)", () async {
      String sourceTextUUID =
          await addTestSourceText(type: SourceTextType.patchouli);
      ModSourceInfo info = ModSourceInfo(
          uuid: Uuid().v4(),
          namespace: "test",
          patchouliAddons: [sourceTextUUID]);
      await info.insert();

      final response = await delete(
          Uri.parse(host + "/translate/source-text/$sourceTextUUID"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $translationManagerToken"
          });
      Map responseJson = json.decode(response.body);

      expect(response.statusCode, 200);
      expect(responseJson["message"], "success");
      expect(await SourceText.getByUUID(sourceTextUUID), null);

      await info.delete();
    });
  });

  group("source file", () {
    Future<_TestSourceFileData> addTestSourceFile() async {
      ModSourceInfo info = ModSourceInfo(uuid: Uuid().v4(), namespace: "test");
      await info.insert();

      late String storageUUID;
      final _response = await post(Uri.parse(host + "/storage/create"),
          body: TestData.tinkersConstructLang.getFileString(),
          headers: {
            "Content-Type": "application/json",
          });
      storageUUID = json.decode(_response.body)["data"]["uuid"];

      final SourceFile file = SourceFile(
          uuid: mockSourceTextUUID,
          type: SourceFileType.gsonLang,
          modSourceInfoUUID: info.uuid,
          path: "assets/test/lang/en_us.json",
          sources: [mockSourceTextUUID],
          storageUUID: storageUUID);
      await file.insert();

      return _TestSourceFileData(file.uuid, info.uuid);
    }

    group("add", () {
      test("add source file (gson lang)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "tconstruct");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.tinkersConstructLang.getFileString(),
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": ["1.16.5"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });

        Map data = json.decode(response.body)["data"];

        expect(response.statusCode, 200);
        expect(data["uuid"], isNotNull);
        expect(data["modSourceInfoUUID"], info.uuid);
        expect(data["storageUUID"], storageUUID);
        expect(data["path"], "assets/tconstruct/lang/en_us.json");
        expect(data["type"], "gsonLang");

        /// Delete the test source file.
        (await SourceFile.getByUUID(data["uuid"]))!.delete();
      });

      test("add source file (minecraft lang)", () async {
        ModSourceInfo info = ModSourceInfo(uuid: Uuid().v4(), namespace: "jei");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.justEnoughItemsLang.getFileString(),
            headers: {
              "Content-Type": "plain/text",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/jei/lang/en_us.lang",
              "type": "minecraftLang",
              "gameVersions": ["1.12.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });

        Map data = json.decode(response.body)["data"];

        expect(response.statusCode, 200);
        expect(data["uuid"], isNotNull);
        expect(data["modSourceInfoUUID"], info.uuid);
        expect(data["storageUUID"], storageUUID);
        expect(data["path"], "assets/jei/lang/en_us.lang");
        expect(data["type"], "minecraftLang");

        /// Delete the test source file.
        (await SourceFile.getByUUID(data["uuid"]))!.delete();
      });

      test("add source file (patchouli book)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "twilightforest");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.twilightForestPatchouliEntries.getFileString(),
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path":
                  "data/twilightforest/patchouli_books/guide/en_us/entries/bosses/ur_ghast.json",
              "type": "patchouli",
              "gameVersions": ["1.18.2"],
              "patchouliI18nKeys": []
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });

        Map data = json.decode(response.body)["data"];

        expect(response.statusCode, 200);
        expect(data["uuid"], isNotNull);
        expect(data["modSourceInfoUUID"], info.uuid);
        expect(data["storageUUID"], storageUUID);
        expect(data["path"],
            "data/twilightforest/patchouli_books/guide/en_us/entries/bosses/ur_ghast.json");
        expect(data["type"], "patchouli");

        /// Delete the test source file.
        (await SourceFile.getByUUID(data["uuid"]))!.delete();
      });

      test("add source file (not permission)", () async {
        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": "test",
              "storageUUID": "test",
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": ["1.16.5"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 403);
        expect(responseJson["message"], "Forbidden");
      });

      test("add source file (unknown mod source info)", () async {
        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.tinkersConstructLang.getFileString(),
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": "test",
              "storageUUID": storageUUID,
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": ["1.16.5"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));
      });

      test("add source file (unknown storage)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "tconstruct");
        await info.insert();

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": "test",
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": ["1.16.5"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));
      });

      test("add source file (empty path)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "tconstruct");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.tinkersConstructLang.getFileString(),
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": " ",
              "type": "gsonLang",
              "gameVersions": ["1.16.5"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"], contains("can't be empty"));
      });

      test("add source file (empty game versions)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "tconstruct");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.tinkersConstructLang.getFileString(),
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": []
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"], contains("can't be empty"));
      });

      test("add source file (invalid file content)", () async {
        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "tconstruct");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: "test",
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await post(Uri.parse(host + "/translate/source-file"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/tconstruct/lang/en_us.json",
              "type": "gsonLang",
              "gameVersions": ["1.18.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"], contains("Handle file failed"));
      });
    });
    group("get and list", () {
      test("get source file", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await get(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            headers: {"Content-Type": "application/json"});

        Map data = json.decode(response.body)["data"];

        expect(response.statusCode, 200);
        expect(data["uuid"], sourceFileUUID);

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });
      test("get source file (unknown uuid)", () async {
        final response = await get(
            Uri.parse(host + "/translate/source-file/test"),
            headers: {"Content-Type": "application/json"});

        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));
      });

      test("list source file", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await get(
            Uri.parse(host + "/translate/source-file")
                .replace(queryParameters: {"limit": "10", "skip": "0"}),
            headers: {"Content-Type": "application/json"});

        List<Map> data =
            json.decode(response.body)["data"]["files"].cast<Map>();

        expect(response.statusCode, 200);
        expect(data.length, 1);
        expect(data[0]["uuid"], sourceFileUUID);

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("list source file (search by mod source)", () async {
        _TestSourceFileData testData = await addTestSourceFile();

        final response = await get(
            Uri.parse(host + "/translate/source-file")
                .replace(queryParameters: {
              "limit": "10",
              "skip": "0",
              "modSourceInfoUUID": testData.infoUUID,
            }),
            headers: {"Content-Type": "application/json"});

        List<Map> data =
            json.decode(response.body)["data"]["files"].cast<Map>();

        expect(response.statusCode, 200);
        expect(data.length, 1);
        expect(data[0]["uuid"], testData.uuid);

        /// Delete the test source file.
        (await SourceFile.getByUUID(testData.uuid))!.delete();
      });

      test("list source text (limit 100)", () async {
        final response = await get(
            Uri.parse(host + "/translate/source-file")
                .replace(queryParameters: {"limit": "100", "skip": "0"}),
            headers: {"Content-Type": "application/json"});

        Map data = json.decode(response.body)["data"];

        expect(response.statusCode, 200);
        expect(data["limit"], 50);
        expect(data["skip"], 0);
        expect(data["files"].length, 0);
      });
    });
    group("edit", () {
      test("edit source file", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "test2");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.justEnoughItemsLang.getFileString(),
            headers: {
              "Content-Type": "plain/text",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/jei/lang/en_us.lang",
              "type": "minecraftLang",
              "gameVersions": ["1.11.2", "1.12.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 200);
        expect(responseJson["message"], "success");
        expect(responseJson["data"]["modSourceInfoUUID"], info.uuid);
        expect(responseJson["data"]["storageUUID"], storageUUID);
        expect(responseJson["data"]["path"], "assets/jei/lang/en_us.lang");
        expect(responseJson["data"]["type"], "minecraftLang");

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
        await info.delete();
      });

      test("edit source file (not permission)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "modSourceInfoUUID": "test",
              "storageUUID": "test",
              "path": "assets/jei/lang/en_us.lang",
              "type": "minecraftLang",
              "gameVersions": ["1.11.2", "1.12.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 403);
        expect(responseJson["message"], "Forbidden");

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("edit source file (unknown uuid)", () async {
        final response =
            await patch(Uri.parse(host + "/translate/source-file/test"),
                body: json.encode({
                  "modSourceInfoUUID": "test",
                  "storageUUID": "test",
                  "path": "assets/jei/lang/en_us.lang",
                  "type": "minecraftLang",
                  "gameVersions": ["1.11.2", "1.12.2"]
                }),
                headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));
      });

      test("edit source file", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        ModSourceInfo info =
            ModSourceInfo(uuid: Uuid().v4(), namespace: "test2");
        await info.insert();

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.justEnoughItemsLang.getFileString(),
            headers: {
              "Content-Type": "plain/text",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "modSourceInfoUUID": info.uuid,
              "storageUUID": storageUUID,
              "path": "assets/jei/lang/en_us.lang",
              "type": "minecraftLang",
              "gameVersions": ["1.11.2", "1.12.2"],
              "patchouliI18nKeys": []
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 200);
        expect(responseJson["message"], "success");
        expect(responseJson["data"]["modSourceInfoUUID"], info.uuid);
        expect(responseJson["data"]["storageUUID"], storageUUID);
        expect(responseJson["data"]["path"], "assets/jei/lang/en_us.lang");
        expect(responseJson["data"]["type"], "minecraftLang");

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
        await info.delete();
      });

      test("edit source file (unknown mod source info)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "modSourceInfoUUID": "test",
              "gameVersions": ["1.11.2", "1.12.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("edit source file (empty path)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "path": " ",
              "gameVersions": ["1.11.2", "1.12.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"], contains("can't be empty"));

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("edit source file (change storage, empty game versions)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: TestData.justEnoughItemsLang.getFileString(),
            headers: {
              "Content-Type": "plain/text",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({"storageUUID": storageUUID, "gameVersions": []}),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"],
            contains("you must provide game versions"));

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("edit source file (unknown storage)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "storageUUID": "test",
              "gameVersions": ["1.16.5", "1.18.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });

      test("edit source file (invalid file content)", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        late String storageUUID;
        final _response = await post(Uri.parse(host + "/storage/create"),
            body: "test",
            headers: {
              "Content-Type": "application/json",
            });
        storageUUID = json.decode(_response.body)["data"]["uuid"];

        final response = await patch(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            body: json.encode({
              "storageUUID": storageUUID,
              "gameVersions": ["1.18.2"]
            }),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 400);
        expect(responseJson["message"], contains("Handle file failed"));

        /// Delete the test source file.
        (await SourceFile.getByUUID(sourceFileUUID))!.delete();
      });
    });

    group("delete", () {
      test("delete source file", () async {
        String sourceFileUUID = (await addTestSourceFile()).uuid;

        final response = await delete(
            Uri.parse(host + "/translate/source-file/$sourceFileUUID"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 200);
        expect(responseJson["message"], "success");
        expect(await SourceFile.getByUUID(sourceFileUUID), null);
      });

      test("delete source file (unknown uuid)", () async {
        final response = await delete(
            Uri.parse(host + "/translate/source-file/test"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $translationManagerToken"
            });
        Map responseJson = json.decode(response.body);

        expect(response.statusCode, 404);
        expect(responseJson["message"], contains("not found"));
      });
    });
  });
}

class _TestSourceFileData {
  final String uuid;
  final String infoUUID;

  const _TestSourceFileData(this.uuid, this.infoUUID);
}
