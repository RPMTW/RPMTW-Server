import 'dart:collection';

import 'package:intl/locale.dart';
import 'package:collection/collection.dart';

import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/models/translate/translation.dart';
import 'package:rpmtw_server/database/models/translate/mod_source_info.dart';
import 'package:rpmtw_server/database/models/translate/source_file.dart';

/// Represents a source text entry in a text format.
/// Can be referenced by `textUUIDs` of [SourceFile] or `patchouliAddons` of [ModSourceInfo].
/// Cannot be repeatedly referenced.
class SourceText extends DBModel {
  static const String collectionName = 'source_texts';
  static const List<IndexField> indexFields = [
    IndexField('source', unique: false),
    IndexField('key', unique: false),
  ];

  /// Text for translation.
  final String source;

  final List<MinecraftVersion> gameVersions;

  final String key;

  final SourceTextType type;

  Future<List<Translation>> getTranslations({Locale? language}) =>
      Translation.list(sourceUUID: uuid, language: language);

  const SourceText({
    required String uuid,
    required this.source,
    required this.gameVersions,
    required this.key,
    required this.type,
  }) : super(uuid: uuid);

  SourceText copyWith({
    String? source,
    List<MinecraftVersion>? gameVersions,
    String? key,
  }) {
    return SourceText(
      uuid: uuid,
      source: source ?? this.source,
      gameVersions: gameVersions ?? this.gameVersions,
      key: key ?? this.key,
      type: type,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'source': source,
      'gameVersions': gameVersions.map((x) => x.toMap()).toList(),
      'key': key,
      'type': type.name,
    };
  }

  factory SourceText.fromMap(Map<String, dynamic> map) {
    return SourceText(
        uuid: map['uuid'],
        source: map['source'],
        gameVersions: List<MinecraftVersion>.from(
            map['gameVersions']?.map((x) => MinecraftVersion.fromMap(x))),
        key: map['key'],
        type: SourceTextType.values.byName(map['type']));
  }

  static Future<SourceText?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<SourceText>(uuid);

  static Future<List<SourceText>> list(
      {String? source, String? key, int? limit, int? skip}) {
    return DataBase.instance.getModelsByField([
      if (source != null) ModelField('source', source),
      if (key != null) ModelField('key', key),
    ], limit: limit, skip: skip);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is SourceText &&
        other.source == source &&
        listEquals(other.gameVersions, gameVersions) &&
        other.key == key &&
        other.type == type;
  }

  @override
  int get hashCode {
    return source.hashCode ^
        gameVersions.hashCode ^
        key.hashCode ^
        type.hashCode;
  }
}

enum SourceTextType {
  /// A collection of key/value pairs (e.g. [HashMap])
  general,
  patchouli,

  /// Plain text format
  /// Key in the source entry uses the md5 hash value of the source content
  plainText
}
