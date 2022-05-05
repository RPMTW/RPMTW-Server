import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';

class MinecraftVersionManifest extends DBModel {
  static const String collectionName = 'minecraft_version_manifest';
  static const List<IndexField> indexFields = [
    IndexField('lastUpdated', unique: true),
  ];

  final _Manifest manifest;
  final DateTime lastUpdated;

  const MinecraftVersionManifest(
      {required this.manifest, required String uuid, required this.lastUpdated})
      : super(uuid: uuid);

  MinecraftVersionManifest copyWith({
    _Manifest? manifest,
    DateTime? lastUpdated,
  }) {
    return MinecraftVersionManifest(
      manifest: manifest ?? this.manifest,
      uuid: uuid,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'manifest': manifest.toMap(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory MinecraftVersionManifest.fromMap(Map<String, dynamic> map) {
    return MinecraftVersionManifest(
      manifest: _Manifest.fromMap(map['manifest']),
      uuid: map['uuid'],
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'], isUtc: true),
    );
  }

  static Future<MinecraftVersionManifest> getFromWeb() async {
    _Manifest manifest;
    String mojangMetaAPI = 'https://launchermeta.mojang.com/mc/game';
    Response response =
        await get(Uri.parse('$mojangMetaAPI/version_manifest_v2.json'));
    manifest = _Manifest.fromJson(response.body);

    return MinecraftVersionManifest(
        manifest: manifest,
        uuid: Uuid().v4(),
        lastUpdated: RPMTWUtil.getUTCTime());
  }

  static Future<MinecraftVersionManifest> getFromCache() async {
    MinecraftVersionManifest? manifest = await DataBase.instance
        .getModelWithSelector<MinecraftVersionManifest>(
            where.sortBy('lastUpdated', descending: true));

    if (manifest == null) {
      /// 如果資料庫快取中沒此資料，則重新下載
      MinecraftVersionManifest _manifest = await getFromWeb();
      await _manifest.insert();
      return _manifest;
    }

    return manifest;
  }
}

class _Manifest {
  String latestRelease;

  String? latestSnapshot;

  List<MinecraftVersion> versions;

  _Manifest(this.latestRelease, this.versions, {this.latestSnapshot});

  factory _Manifest.fromMap(Map<String, dynamic> data) {
    return _Manifest(
        data['latest']['release'],
        (data['versions'] as List<dynamic>)
            .map((d) => MinecraftVersion.fromMap(d))
            .toList(),
        latestSnapshot: data['latest']['snapshot']);
  }

  factory _Manifest.fromJson(String json) {
    return _Manifest.fromMap(jsonDecode(json));
  }

  Map<String, dynamic> toMap() {
    return {
      'latest': {
        'release': latestRelease,
        'snapshot': latestSnapshot,
      },
      'versions': versions.map((v) => v.toMap()).toList(),
    };
  }

  _Manifest copyWith({
    String? latestRelease,
    String? latestSnapshot,
    List<MinecraftVersion>? versions,
  }) {
    return _Manifest(
      latestRelease ?? this.latestRelease,
      versions ?? this.versions,
      latestSnapshot: latestSnapshot ?? this.latestSnapshot,
    );
  }
}
