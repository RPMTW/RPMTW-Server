import "dart:convert";

import "package:http/http.dart";
import "package:intl/locale.dart";
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:test/test.dart";

import "../../test_utility.dart";

void main() async {
  final host = TestUttily.host;
  final String mockTranslationUUID = "0d87bd04-d957-4e7c-a9b7-5eb0bb3a40c1";
  final String mockSourceTextUUID = "b1b02c50-f35c-4a99-a38f-7240e61917f1";
  late final String token;
  late final String userUUID;

  setUpAll(() {
    return Future.sync(() async {
      await TestUttily.setUpAll();

      /// Create a test user account.
      final _response = await post(Uri.parse(host + "/auth/user/create"),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test@gmail.com",
            "username": "test",
          }),
          headers: {"Content-Type": "application/json"});
      Map _body = json.decode(_response.body)["data"];
      token = _body["token"];
      userUUID = _body["uuid"];

      await SourceText(
              uuid: mockSourceTextUUID,
              source: "Hello, World!",
              gameVersion: [],
              key: "test.title.hello_world")
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

  test("add translation vote", () async {
    final String type = "up";
    final response = await post(Uri.parse(host + "/translate/vote"),
        body:
            json.encode({"type": type, "translationUUID": mockTranslationUUID}),
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
    (await TranslationVote.getByUUID(data["uuid"]))?.delete();
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
        body:
            json.encode({"type": "up", "translationUUID": mockTranslationUUID}),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        });
    Map responseJson = json.decode(response.body);

    expect(response.statusCode, 400);
    expect(responseJson["message"], contains("already voted"));

    /// Delete the test translation vote.
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
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
        Uri.parse(host + "/translate/vote")
            .replace(queryParameters: {"translationUUID": mockTranslationUUID}),
        headers: {"Content-Type": "application/json"});

    List<Map> data = json.decode(response.body)["data"].cast<Map>();

    expect(response.statusCode, 200);
    expect(data.length, 1);
    expect(data[0]["uuid"], translationVoteUUID);

    /// Delete the test translation vote.
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
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

    /// Delete the test translation vote.
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
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
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
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
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
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
    (await TranslationVote.getByUUID(translationVoteUUID))?.delete();
  });

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
    (await Translation.getByUUID(data["uuid"]))?.delete();
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
    (await Translation.getByUUID(translationUUID))?.delete();
  });
  test("get translation (unknown uuid)", () async {
    final response = await get(Uri.parse(host + "/translate/translation/test"),
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
    (await Translation.getByUUID(translationUUID))?.delete();
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

    /// Delete the test translation.
    (await Translation.getByUUID(translationUUID))?.delete();
  });

  test("delete translation (unknown translation uuid)", () async {
    final response =
        await delete(Uri.parse(host + "/translate/translation/test"), headers: {
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
    (await Translation.getByUUID(translationUUID))?.delete();
  });
}
