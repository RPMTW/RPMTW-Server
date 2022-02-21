import 'dart:io';
import 'dart:typed_data';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/handler/cosmic_chat_handler.dart';
import 'package:rpmtw_server/utilities/data.dart';
import '../bin/server.dart' as server;

enum TestData { versionManifest }

extension TestDataExtension on TestData {
  String toFileName() {
    switch (this) {
      case TestData.versionManifest:
        return "minecraft_version_manifest_v2_2022_1_10.json";
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
    map['COSMIC_CHAT_DISCORD_SecretKey'] = secretKey;
    return map;
  }
}

class TestUttily {
  static String get secretKey => "testSecretKey";

  static Future<void> setUpAll({bool isServer = true}) {
    return Future.sync(() async {
      kTestMode = true;
      Parser parser = const TestEnvParser();
      if (isServer) {
        await server.main(["RPMTW_SERVER_TEST_MODE=TRUE"]);
      } else {
        await Data.init(envParser: parser);
      }
    });
  }

  static Future<void> tearDownAll() {
    return Future.sync(() async {
      await server.server?.close(force: true); // 關閉伺服器
      await CosmicChatHandler.io.close(); // 關閉宇宙通訊伺服器
    });
  }
}
