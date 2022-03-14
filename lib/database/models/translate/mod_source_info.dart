import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/translate/source_file.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';

class ModSourceInfo extends BaseModels {
  /// Namespace of the mod
  final String namespace;

  /// UUID of the [MinecraftMod], can be null.
  final String? modUUID;

  /// [SourceFile] files included in this mod.
  final List<String> files;

  /// Used to store specially formatted [SourceText] in patchouli manuals.
  final List<String> patchouliAddons;

  const ModSourceInfo({
    required String uuid,
    required this.namespace,
    this.modUUID,
    required this.files,
    required this.patchouliAddons,
  }) : super(uuid: uuid);

  ModSourceInfo copyWith({
    String? namespace,
    String? modUUID,
    List<String>? files,
    List<String>? patchouliAddons,
  }) {
    return ModSourceInfo(
      uuid: uuid,
      namespace: namespace ?? this.namespace,
      modUUID: modUUID ?? this.modUUID,
      files: files ?? this.files,
      patchouliAddons: patchouliAddons ?? this.patchouliAddons,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'namespace': namespace,
      'modUUID': modUUID,
      'files': files,
      'patchouliAddons': patchouliAddons,
    };
  }

  factory ModSourceInfo.fromMap(Map<String, dynamic> map) {
    return ModSourceInfo(
      uuid: map['uuid'],
      namespace: map['namespace'],
      modUUID: map['modUUID'],
      files: List<String>.from(map['files']),
      patchouliAddons: List<String>.from(map['patchouliAddons']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ModSourceInfo.fromJson(String source) =>
      ModSourceInfo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ModSourceInfo(uuid: $uuid, namespace: $namespace, modUUID: $modUUID, files: $files, patchouliAddons: $patchouliAddons)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is ModSourceInfo &&
        other.uuid == uuid &&
        other.namespace == namespace &&
        other.modUUID == modUUID &&
        listEquals(other.files, files) &&
        listEquals(other.patchouliAddons, patchouliAddons);
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        namespace.hashCode ^
        modUUID.hashCode ^
        files.hashCode ^
        patchouliAddons.hashCode;
  }
}
