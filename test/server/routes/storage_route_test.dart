import "dart:convert";

import "package:http/http.dart";
import "package:test/test.dart";
import "../../test_utility.dart";

void main() async {
  final host = TestUttily.host;

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  final String storageContent = "Hello World";

  late String storageUUID;
  late int createAt;

  test("create storage", () async {
    final response = await post(Uri.parse(host + "/storage/create"),
        body: utf8.encode(storageContent),
        headers: {"Content-Type": "text/plain"});
    Map data = json.decode(response.body)["data"];

    expect(response.statusCode, 200);
    expect(data["contentType"], contains("text/plain"));
    expect(data["type"], contains("temp"));

    storageUUID = data["uuid"];
    createAt = data["createAt"];
  });

  test("create storage (file too large)", () async {
    final response = await post(Uri.parse(host + "/storage/create"),
        body: utf8.encode(
            List.generate(780000, (index) => storageContent).join()),
        headers: {"Content-Type": "text/plain"});
    Map responseJson = json.decode(response.body);

    expect(response.statusCode, 400);
    expect(responseJson["message"], contains("too large"));
  });

  test("view storage", () async {
    final response = await get(
      Uri.parse(host + "/storage/$storageUUID"),
    );
    Map data = json.decode(response.body)["data"];

    expect(response.statusCode, 200);
    expect(data["uuid"], storageUUID);
    expect(data["createAt"], createAt);
  });

  test("view storage (unknown uuid)", () async {
    final response = await get(
      Uri.parse(host + "/storage/test"),
    );
    Map responseJson = json.decode(response.body);

    expect(response.statusCode, 404);
    expect(responseJson["message"], contains("not found"));
  });

  test("download storage", () async {
    final response = await get(
      Uri.parse(host + "/storage/$storageUUID/download"),
    );

    expect(response.statusCode, 200);
    expect(response.body, storageContent);
  });
}
