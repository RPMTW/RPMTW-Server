import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
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
    late List<String> supportVersions;

    final String modName = "test mod";
    final String changedName = "test2 mod";
    final String modID = "test_mod";
    final String modDescription = "This is the test mod";
    final ModSide modSide = ModSide(
        environment: ModSideEnvironment.client,
        requireType: ModRequireType.required);
    final String modTranslatedName = "測試模組";
    final String modIntroduction = "# Test Mod  \n## Introduction";

    test("get versions", () async {
      final response = await get(
        Uri.parse(host + '/minecraft/versions'),
      );
      Map<String, dynamic> data =
          json.decode(response.body)['data'].cast<String, dynamic>();
      MinecraftVersionManifest _manifest =
          MinecraftVersionManifest.fromMap(data);
      supportVersions = [_manifest.manifest.versions.first.id];
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
            "name": modName,
            "id": modID,
            "supportVersions": supportVersions,
            "description": modDescription,
            "loader": [ModLoader.fabric.name, ModLoader.forge.name],
            "side": [modSide.toMap()],
            "relationMods": [
              // TODO:另外建立一個關聯模組來取代 test
              RelationMod(modUUID: "test", type: RelationType.dependency)
                  .toMap()
            ],
            "translatedName": modTranslatedName,
            "introduction": modIntroduction,
            "imageStorageUUID": null // TODO: 測試新增模組圖片至 wiki 資料
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          });
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['name'], modName);
      expect(data['id'], modID);
      expect(data['description'], modDescription);
      expect(data['loader'], [ModLoader.fabric.name, ModLoader.forge.name]);
      expect(data['side'], [modSide.toMap()]);
      expect(data['translatedName'], modTranslatedName);
      expect(data['introduction'], modIntroduction);

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

    test("create mod (invalid mod name)", () async {
      final response = await post(Uri.parse(host + '/minecraft/mod/create'),
          body: json.encode({
            "name": "",
            "supportVersions": supportVersions,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          });

      Map map = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(map['message'], contains("Invalid mod name"));
    });
    test("create mod (invalid mod image storage)", () async {
      final response = await post(Uri.parse(host + '/minecraft/mod/create'),
          body: json.encode({
            "name": "abc",
            "supportVersions": supportVersions,
            "imageStorageUUID": "abc"
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          });

      Map map = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(map['message'], contains("Invalid image storage"));
    });
    test("view mod", () async {
      final response = await get(
        Uri.parse(host + '/minecraft/mod/view/$modUUID?recordViewCount=false'),
      );
      Map data = json.decode(response.body)['data'];

      expect(response.statusCode, 200);
      expect(data['uuid'], modUUID);
      expect(data['name'], modName);
      expect(data['id'], modID);
      expect(data['description'], modDescription);
      expect(data['loader'], [ModLoader.fabric.name, ModLoader.forge.name]);
      expect(data['side'], [modSide.toMap()]);
      expect(data['translatedName'], modTranslatedName);
      expect(data['introduction'], modIntroduction);
    });

    test("search mods", () async {
      final response = await get(
        Uri.parse(
            host + '/minecraft/mod/search?filter=test&limit=1&skip=0&sort=0'),
      );
      Map data = json.decode(response.body)['data'];
      List<Map<String, dynamic>> mods =
          data['mods'].cast<Map<String, dynamic>>();

      expect(response.statusCode, 200);
      expect(mods.length, 1);
      expect(mods[0]['uuid'], modUUID);
      expect(mods[0]['name'], modName);
      expect(mods[0]['id'], modID);
      expect(mods[0]['description'], modDescription);
      expect(mods[0]['loader'], [ModLoader.fabric.name, ModLoader.forge.name]);
      expect(mods[0]['side'], [modSide.toMap()]);
    });
    test("search mods (upper case)", () async {
      final response = await get(
        Uri.parse(
            host + '/minecraft/mod/search?filter=TEST&limit=1&skip=0&sort=0'),
      );
      Map data = json.decode(response.body)['data'];
      List<Map<String, dynamic>> mods =
          data['mods'].cast<Map<String, dynamic>>();

      expect(response.statusCode, 200);
      expect(mods.length, 1);
      expect(mods[0]['uuid'], modUUID);
      expect(mods[0]['name'], modName);
      expect(mods[0]['id'], modID);
      expect(mods[0]['description'], modDescription);
      expect(mods[0]['loader'], [ModLoader.fabric.name, ModLoader.forge.name]);
      expect(mods[0]['side'], [modSide.toMap()]);
    });
    test("search mods (by translated name)", () async {
      final response = await get(
        Uri.parse(
            host + '/minecraft/mod/search?filter=測試&limit=1&skip=0&sort=1'),
      );
      Map data = json.decode(response.body)['data'];
      List<Map<String, dynamic>> mods =
          data['mods'].cast<Map<String, dynamic>>();

      expect(response.statusCode, 200);
      expect(mods.length, 1);
      expect(mods[0]['uuid'], modUUID);
      expect(mods[0]['name'], modName);
      expect(mods[0]['id'], modID);
      expect(mods[0]['description'], modDescription);
      expect(mods[0]['loader'], [ModLoader.fabric.name, ModLoader.forge.name]);
      expect(mods[0]['side'], [modSide.toMap()]);
    });
    test("edit mod", () async {
      final response =
          await patch(Uri.parse(host + '/minecraft/mod/edit/$modUUID'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({"name": changedName}));
      Map data = json.decode(response.body)['data'];
      expect(response.statusCode, 200);
      expect(data['name'], changedName);
    });
    test("edit mod (invalid mod uuid)", () async {
      final response = await patch(Uri.parse(host + '/minecraft/mod/edit/abcd'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({"name": changedName}));
      expect(response.statusCode, 400);
    });
    test("edit mod (invalid mod image storage)", () async {
      final response =
          await patch(Uri.parse(host + '/minecraft/mod/edit/$modUUID'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({"imageStorageUUID": "abc"}));

      Map map = json.decode(response.body);

      expect(response.statusCode, 400);
      expect(map['message'], contains("Invalid image storage"));
    });
    test("filter changelogs", () async {
      final response = await get(
        Uri.parse(host + '/minecraft/changelog?limit=2&skip=0'),
      );
      Map data = json.decode(response.body)['data'];
      List<Map<String, dynamic>> changelogs =
          data['changelogs'].cast<Map<String, dynamic>>();

      expect(response.statusCode, 200);
      expect(changelogs.length, 2);
      expect(changelogs[0]['type'], "addedMod");
      expect(changelogs[0]['dataUUID'], modUUID);

      expect(changelogs[1]['type'], "editedMod");
      expect(changelogs[1]['dataUUID'], modUUID);
    });
  });
}
