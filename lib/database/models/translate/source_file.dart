import 'package:rpmtw_server/database/database.dart';
import "package:rpmtw_server/database/models/base_models.dart";
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/model_field.dart';
import 'package:rpmtw_server/database/models/translate/mod_source_info.dart';
import "package:rpmtw_server/database/models/translate/source_text.dart";

/// Represents the source language file in a text format.
class SourceFile extends BaseModel {
  static const String collectionName = "source_files";
  static const List<IndexField> indexFields = [
    IndexField("sourceInfoUUID", unique: false)
  ];

  final String sourceInfoUUID;
  final String path;
  final SourceFileType type;

  /// [SourceText] included in the file.
  final List<String> sources;

  Future<ModSourceInfo?> get sourceInfo {
    return ModSourceInfo.getByUUID(sourceInfoUUID);
  }

  Future<List<SourceText>> get sourceTexts async {
    List<SourceText> texts = [];
    for (String source in sources) {
      SourceText? text = await SourceText.getByUUID(source);
      if (text == null) {
        throw Exception("SourceText not found, uuid: $source");
      }
      texts.add(text);
    }
    return texts;
  }

  const SourceFile(
      {required String uuid,
      required this.sourceInfoUUID,
      required this.path,
      required this.type,
      required this.sources})
      : super(uuid: uuid);

  SourceFile copyWith({
    String? sourceInfoUUID,
    String? path,
    SourceFileType? type,
    List<String>? sources,
  }) {
    return SourceFile(
      uuid: uuid,
      sourceInfoUUID: sourceInfoUUID ?? this.sourceInfoUUID,
      path: path ?? this.path,
      type: type ?? this.type,
      sources: sources ?? this.sources,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "sourceInfoUUID": sourceInfoUUID,
      "path": path,
      "type": type.name,
      "sources": sources,
    };
  }

  factory SourceFile.fromMap(Map<String, dynamic> map) {
    return SourceFile(
      uuid: map["uuid"],
      sourceInfoUUID: map["sourceInfoUUID"],
      path: map["path"],
      type: SourceFileType.values.byName(map["type"]),
      sources: List<String>.from(map["sources"]),
    );
  }

  static Future<List<SourceFile>> getBySourceInfoUUID(String uuid) async =>
      DataBase.instance
          .getModelsByField<SourceFile>([ModelField("sourceInfoUUID", uuid)]);
}

enum SourceFileType {
  /// Localized file format used in versions 1.13 and above
  gsonLang,

  /// Localized file format used in versions below 1.12 (inclusive)
  minecraftLang,
  patchouli,

  /// Plain text format
  /// Each line of text is a source entry, and the key in the source entry uses the md5 hash value of the source content
  plainText
}
