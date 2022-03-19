import 'package:rpmtw_server/database/database.dart';

import "package:rpmtw_server/database/models/base_models.dart";
import 'package:rpmtw_server/database/models/index_fields.dart';
import "package:rpmtw_server/database/models/minecraft/minecraft_version.dart";
import 'package:rpmtw_server/database/models/translate/translation.dart';

class SourceText extends BaseModel {
  static const String collectionName = "source_texts";
  static const List<IndexFields> indexFields = [
    IndexFields("source", unique: false),
    IndexFields("key", unique: false),
  ];

  final String source;

  final List<MinecraftVersion> gameVersion;

  final String key;

  Future<List<Translation>> get translations {
    return Translation.getBySourceUUID(uuid);
  }

  const SourceText({
    required String uuid,
    required this.source,
    required this.gameVersion,
    required this.key,
  }) : super(uuid: uuid);

  SourceText copyWith({
    String? source,
    List<MinecraftVersion>? gameVersion,
    String? key,
  }) {
    return SourceText(
      uuid: uuid,
      source: source ?? this.source,
      gameVersion: gameVersion ?? this.gameVersion,
      key: key ?? this.key,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "source": source,
      "gameVersion": gameVersion.map((x) => x.toMap()).toList(),
      "key": key
    };
  }

  factory SourceText.fromMap(Map<String, dynamic> map) {
    return SourceText(
        uuid: map["uuid"],
        source: map["source"],
        gameVersion: List<MinecraftVersion>.from(
            map["gameVersion"]?.map((x) => MinecraftVersion.fromMap(x))),
        key: map["key"]);
  }

  static Future<SourceText?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<SourceText>(uuid);
}