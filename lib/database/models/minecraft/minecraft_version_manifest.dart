import 'dart:convert';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';

import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';

class MinecraftVersionManifest extends BaseModels {
  static const String collectionName = 'minecraft_version_manifest';
  static const List<IndexFields> indexFields = [
    IndexFields("lastUpdated"),
  ];

  final _Manifest manifest;
  final DateTime lastUpdated;

  const MinecraftVersionManifest(
      {required this.manifest, required String uuid, required this.lastUpdated})
      : super(uuid: uuid);

  MinecraftVersionManifest copyWith({
    _Manifest? manifest,
    String? uuid,
    DateTime? lastUpdated,
  }) {
    return MinecraftVersionManifest(
      manifest: manifest ?? this.manifest,
      uuid: uuid ?? this.uuid,
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
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated']),
    );
  }

  String toJson() => json.encode(toMap());

  factory MinecraftVersionManifest.fromJson(String source) =>
      MinecraftVersionManifest.fromMap(json.decode(source));

  @override
  String toString() =>
      'MinecraftVersionManifestModels(manifest: $manifest, uuid: $uuid, lastUpdated: $lastUpdated)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MinecraftVersionManifest &&
        other.manifest == manifest &&
        other.uuid == uuid &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => manifest.hashCode ^ uuid.hashCode ^ lastUpdated.hashCode;

  static Future<MinecraftVersionManifest> getFromWeb() async {
    _Manifest manifest;
    String mojangMetaAPI = 'https://launchermeta.mojang.com/mc/game';
    Response response =
        await get(Uri.parse("$mojangMetaAPI/version_manifest_v2.json"));
    manifest = _Manifest.fromJson(response.body);

    return MinecraftVersionManifest(
        manifest: manifest,
        uuid: Uuid().v4(),
        lastUpdated: DateTime.now().toUtc());
  }

  static Future<MinecraftVersionManifest> getFromCache() async {
    Map<String, dynamic>? manifestMap = await DataBase.instance
        .getCollection<MinecraftVersionManifest>()
        .findOne();

    if (manifestMap == null) {
      /// 如果資料庫快取中沒此資料，則重新下載
      MinecraftVersionManifest _manifest = await getFromWeb();
      await _manifest.insert();
      return _manifest;
    }

    return MinecraftVersionManifest.fromMap(manifestMap);
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
}
