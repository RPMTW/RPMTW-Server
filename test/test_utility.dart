import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:rpmtw_server/database/database.dart';
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

class TestUttily {
  static Future<void> setUpAll() {
    kTestMode = true;
    return Future.sync(() async => await server.run());
  }

  static Future<void> tearDownAll() {
    return Future.sync(() async {
      await DataBase.instance.db.drop(); // 刪除測試用資料庫
      await server.server?.close(force: true); // 關閉伺服器
    });
  }
}
