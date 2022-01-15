import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
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

  group("Minecraft", () {
    late String modUUID;
    late String token;
    late List<Map<String, dynamic>> supportVersions;

    test("get versions", () async {
      final response = await get(
        Uri.parse(host + '/minecraft/versions'),
      );
      Map<String, dynamic> data =
          json.decode(response.body)['data'].cast<String, dynamic>();
      MinecraftVersionManifest _manifest =
          MinecraftVersionManifest.fromMap(data);
      supportVersions =
          [_manifest.manifest.versions.first].map((e) => e.toMap()).toList();
    });

    test("create mod", () async {
      /// 由於建立 Minecraft 模組需要驗證使用者，因此先建立一個使用者帳號
      final _response = await post(Uri.parse(host + '/auth/user/create'),
          body: json.encode({
            "password": "testPassword1234",
            "email": "test@gmail.com",
            "username": "test",
          }),
          headers: {'Content-Type': 'application/json'});
      token = json.decode(_response.body)['data']['token'];

      final response = await post(Uri.parse(host + '/minecraft/mod/create'),
          body: json.encode({
            "name": "test mod",
            "id": "test_mod",
            "supportVersions": supportVersions,
            "description": "This is the test mod",
            "loader": ModLoader.fabric.name
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          });
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
          body: json.encode({}),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          });

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
      expect(data['loader'], ModLoader.fabric.name);
    });
  });
}
