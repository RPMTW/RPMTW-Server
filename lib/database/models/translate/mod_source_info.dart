import 'package:rpmtw_server/database/database.dart';

import "package:rpmtw_server/database/models/base_models.dart";
import 'package:rpmtw_server/database/models/index_fields.dart';
import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";

class ModSourceInfo extends BaseModel {
  static const String collectionName = "mod_source_infos";
  static const List<IndexFields> indexFields = [
    IndexFields("namespace", unique: false),
    IndexFields("modUUID", unique: true),
  ];

  /// Namespace of the mod
  final String namespace;

  /// UUID of the [MinecraftMod], can be null.
  final String? modUUID;

  /// Used to store specially formatted [SourceText] in patchouli manuals.
  final List<String> patchouliAddons;

  /// [SourceFile] files included in this mod.
  Future<List<SourceFile>> get files {
    return SourceFile.getBySourceInfoUUID(uuid);
  }

  const ModSourceInfo({
    required String uuid,
    required this.namespace,
    this.modUUID,
    required this.patchouliAddons,
  }) : super(uuid: uuid);

  ModSourceInfo copyWith({
    String? namespace,
    String? modUUID,
    List<String>? patchouliAddons,
  }) {
    return ModSourceInfo(
      uuid: uuid,
      namespace: namespace ?? this.namespace,
      modUUID: modUUID ?? this.modUUID,
      patchouliAddons: patchouliAddons ?? this.patchouliAddons,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "namespace": namespace,
      "modUUID": modUUID,
      "patchouliAddons": patchouliAddons,
    };
  }

  factory ModSourceInfo.fromMap(Map<String, dynamic> map) {
    return ModSourceInfo(
      uuid: map["uuid"],
      namespace: map["namespace"],
      modUUID: map["modUUID"],
      patchouliAddons: List<String>.from(map["patchouliAddons"]),
    );
  }

  static Future<ModSourceInfo?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<ModSourceInfo>(uuid);
}
