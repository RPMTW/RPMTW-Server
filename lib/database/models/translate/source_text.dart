import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';

class SourceText extends BaseModels {
  final String source;

  final List<MinecraftVersion> gameVersion;

  final String key;

  final List<String> translations;

  const SourceText({
    required String uuid,
    required this.source,
    required this.gameVersion,
    required this.key,
    required this.translations,
  }) : super(uuid: uuid);

  SourceText copyWith({
    String? source,
    List<MinecraftVersion>? gameVersion,
    String? key,
    List<String>? translations,
  }) {
    return SourceText(
      uuid: uuid,
      source: source ?? this.source,
      gameVersion: gameVersion ?? this.gameVersion,
      key: key ?? this.key,
      translations: translations ?? this.translations,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'source': source,
      'gameVersion': gameVersion.map((x) => x.toMap()).toList(),
      'key': key,
      'translations': translations,
    };
  }

  factory SourceText.fromMap(Map<String, dynamic> map) {
    return SourceText(
      uuid: map['uuid'],
      source: map['source'],
      gameVersion: List<MinecraftVersion>.from(
          map['gameVersion']?.map((x) => MinecraftVersion.fromMap(x))),
      key: map['key'],
      translations: List<String>.from(map['translations']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is SourceText &&
        other.uuid == uuid &&
        other.source == source &&
        listEquals(other.gameVersion, gameVersion) &&
        other.key == key &&
        listEquals(other.translations, translations);
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        source.hashCode ^
        gameVersion.hashCode ^
        key.hashCode ^
        translations.hashCode;
  }
}
