import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
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

  group("Minecraft Mod", () {
    late String modUUID;
    MinecraftVersionManifest versionManifest =
        MinecraftVersionManifest.fromJson(
            TestData.versionManifest.getFileString());
    List<Map<String, dynamic>> supportVersions =
        [versionManifest.versions.first].map((e) => e.toMap()).toList();

    test("create mod", () async {
      final response = await post(Uri.parse(host + '/minecraft/mod/create'),
          body: json.encode({
            "name": "test mod",
            "id": "test_mod",
            "supportVersions": supportVersions,
            "description": "This is the test mod",
          }),
          headers: {'Content-Type': 'application/json'});
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['name'], 'test mod');
      expect(data['id'], 'test_mod');
      expect(data['description'], 'This is the test mod');
      expect(data['supportVersions'], supportVersions);

      modUUID = data['uuid'];
    });

    test("create mod (missing required fields)", () async {
      final response = await post(Uri.parse(host + '/minecraft/mod/create'),
          body: json.encode({}), headers: {'Content-Type': 'application/json'});

      Map map = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(map['message'], contains("Missing required fields"));
    });
    test("view mod", () async {
      final response = await get(
        Uri.parse(host + '/minecraft/mod/$modUUID'),
      );
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], modUUID);
      expect(data['name'], 'test mod');
      expect(data['id'], 'test_mod');
      expect(data['description'], 'This is the test mod');
      expect(data['supportVersions'], supportVersions);
    });
  });
}
