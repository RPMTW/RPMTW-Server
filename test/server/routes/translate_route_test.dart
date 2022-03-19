import "dart:convert";

import "package:http/http.dart";
import "package:intl/locale.dart";
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

      await Translation(
              sourceUUID: mockSourceTextUUID,
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

  Future<String> createTestVote() async {
    final String type = "up";
    final response = await post(Uri.parse(host + "/translate/vote"),
        body:
            json.encode({"type": type, "translationUUID": mockTranslationUUID}),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        });

    return json.decode(response.body)["data"]["uuid"];
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
    String translationVoteUUID = await createTestVote();
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

  test("list translation vote", () async {
    String translationVoteUUID = await createTestVote();

    final response = await get(
        Uri.parse(host + "/translate/vote")
            .replace(queryParameters: {"translationUUID": mockTranslationUUID}),
        headers: {"Content-Type": "application/json"});

    List<Map> data = json.decode(response.body)["data"].cast<Map>();

    expect(response.statusCode, 200);
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
    String translationVoteUUID = await createTestVote();

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
    String translationVoteUUID = await createTestVote();

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
    String translationVoteUUID = await createTestVote();

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
    String translationVoteUUID = await createTestVote();

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
}
