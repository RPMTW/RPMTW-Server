import 'dart:io';
import 'dart:typed_data';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart';
import 'package:rpmtw_server/handler/universe_chat_handler.dart';
import 'package:rpmtw_server/utilities/data.dart';
import '../bin/server.dart' as server;

enum TestData {
  versionManifest,
  tinkersConstructLang,
  justEnoughItemsLang,
  twilightForestPatchouliEntries,
  rpmtwPlatformLogo,
  iceAndFireBestiaryAlchemy,
  tconstructMaterialsAndYouIntroWelcome
}

extension TestDataExtension on TestData {
  String toFileName() {
    switch (this) {
      case TestData.versionManifest:
        return 'minecraft_version_manifest_v2_2022_1_10.json';
      case TestData.tinkersConstructLang:
        return 'tconstruct_1.16_lang.json';
      case TestData.justEnoughItemsLang:
        return 'jei_1.12_lang.lang';
      case TestData.twilightForestPatchouliEntries:
        return 'twilightforest_patchouli_book_guide_entrie_ur_ghast.json';
      case TestData.rpmtwPlatformLogo:
        return 'rpmtw-platform-logo.png';
      case TestData.iceAndFireBestiaryAlchemy:
        return 'iceandfire_bestiary_alchemy_0.txt';
      case TestData.tconstructMaterialsAndYouIntroWelcome:
        return 'tconstruct_materials_and_you_intro_welcome.json';
      default:
        return name;
    }
  }

  File getFile() =>
      File(join(Directory.current.path, 'test', 'data', toFileName()));

  String getFileString() => getFile().readAsStringSync();

  Uint8List getFileBytes() => getFile().readAsBytesSync();
}

class TestEnvParser extends Parser {
  const TestEnvParser();

  @override
  Map<String, String> parse(Iterable<String> lines) {
    Map<String, String> map = super.parse(lines);
    String secretKey = TestUttily.secretKey;
    map['DATA_BASE_SecretKey'] = secretKey;
    return map;
  }
}

class TestUttily {
  static final String host = 'http://localhost:8080';
  static String get secretKey => 'testSecretKey';

  static Future<void> setUpAll({bool isServer = true}) {
    return Future.sync(() async {
      kTestMode = true;
      Parser parser = const TestEnvParser();
      if (isServer) {
        await server.main(['RPMTW_SERVER_TEST_MODE=TRUE']);
      } else {
        await Data.init(envParser: parser);
      }
    });
  }

  static Future<void> tearDownAll() {
    return Future.sync(() async {
      await server.server?.close(force: true); // 關閉伺服器
      await UniverseChatHandler.io.close(); // 關閉宇宙通訊伺服器
    });
  }
}
