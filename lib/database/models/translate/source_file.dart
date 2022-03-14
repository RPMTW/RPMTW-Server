import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';

class SourceFile extends BaseModels {
  final String path;
  final SourceFileType type;

  /// [SourceText] uuid list
  final List<String> sources;
  const SourceFile(
      {required String uuid,
      required this.path,
      required this.type,
      required this.sources})
      : super(uuid: uuid);

  SourceFile copyWith({
    String? path,
    SourceFileType? type,
    List<String>? sources,
  }) {
    return SourceFile(
      uuid: uuid,
      path: path ?? this.path,
      type: type ?? this.type,
      sources: sources ?? this.sources,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'path': path,
      'type': type.name,
      'sources': sources,
    };
  }

  factory SourceFile.fromMap(Map<String, dynamic> map) {
    return SourceFile(
      uuid: map['uuid'],
      path: map['path'],
      type: SourceFileType.values.byName(map['type']),
      sources: List<String>.from(map['sources']),
    );
  }

  String toJson() => json.encode(toMap());

  factory SourceFile.fromJson(String source) =>
      SourceFile.fromMap(json.decode(source));

  @override
  String toString() =>
      'SourceFile(uuid: $uuid, path: $path, type: $type, sources: $sources)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is SourceFile &&
        other.uuid == uuid &&
        other.path == path &&
        other.type == type &&
        listEquals(other.sources, sources);
  }

  @override
  int get hashCode =>
      uuid.hashCode ^ path.hashCode ^ type.hashCode ^ sources.hashCode;
}

enum SourceFileType {
  /// Localized file format used in versions 1.13 and above
  gsonLang,

  /// Localized file format used in versions below 1.12 (inclusive)
  minecraftLang,
  patchouli,

  /// 
  customText
}
