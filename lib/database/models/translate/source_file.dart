import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/database/models/translate/mod_source_info.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';

/// Represents the source language file in a text format.
class SourceFile extends DBModel {
  static const String collectionName = 'source_files';
  static const List<IndexField> indexFields = [
    IndexField('modSourceInfoUUID', unique: false),
    IndexField('textUUIDs', unique: false),
  ];

  final String modSourceInfoUUID;
  final String storageUUID;
  final String path;
  final SourceFileType type;

  /// [SourceText] included in the file.
  final List<String> textUUIDs;

  Future<ModSourceInfo?> get sourceInfo =>
      ModSourceInfo.getByUUID(modSourceInfoUUID);

  Future<Storage?> get storage => Storage.getByUUID(storageUUID);

  Future<List<SourceText>> get sourceTexts async {
    List<SourceText> result = [];
    for (String uuid in textUUIDs) {
      SourceText? text = await SourceText.getByUUID(uuid);
      if (text == null) {
        throw Exception('SourceText not found, uuid: $uuid');
      }
      result.add(text);
    }
    return result;
  }

  const SourceFile(
      {required String uuid,
      required this.modSourceInfoUUID,
      required this.storageUUID,
      required this.path,
      required this.type,
      required this.textUUIDs})
      : super(uuid: uuid);

  SourceFile copyWith({
    String? modSourceInfoUUID,
    String? storageUUID,
    String? path,
    SourceFileType? type,
    List<String>? textUUIDs,
  }) {
    return SourceFile(
      uuid: uuid,
      modSourceInfoUUID: modSourceInfoUUID ?? this.modSourceInfoUUID,
      storageUUID: storageUUID ?? this.storageUUID,
      path: path ?? this.path,
      type: type ?? this.type,
      textUUIDs: textUUIDs ?? this.textUUIDs,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'modSourceInfoUUID': modSourceInfoUUID,
      'storageUUID': storageUUID,
      'path': path,
      'type': type.name,
      'textUUIDs': textUUIDs,
    };
  }

  @override
  Future<WriteResult> delete({bool deleteDependencies = true}) async {
    if (deleteDependencies) {
      final List<SourceText> texts = await sourceTexts;

      for (final text in texts) {
        await text.delete();
      }

      Storage? _storage = await storage;
      if (_storage != null) {
        _storage = _storage.copyWith(
            type: StorageType.general,
            usageCount: _storage.usageCount > 0 ? _storage.usageCount - 1 : 0);
        await _storage.update();
      }
    }

    return super.delete();
  }

  factory SourceFile.fromMap(Map<String, dynamic> map) {
    return SourceFile(
      uuid: map['uuid'],
      modSourceInfoUUID: map['modSourceInfoUUID'],
      storageUUID: map['storageUUID'],
      path: map['path'],
      type: SourceFileType.values.byName(map['type']),
      textUUIDs: List<String>.from(map['textUUIDs']),
    );
  }

  static Future<SourceFile?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<SourceFile>(uuid);

  static Future<List<SourceFile>> list(
          {String? modSourceInfoUUID, int? limit, int? skip}) =>
      DataBase.instance.getModelsByField<SourceFile>([
        if (modSourceInfoUUID != null)
          ModelField('modSourceInfoUUID', modSourceInfoUUID)
      ], limit: limit, skip: skip);
}

enum SourceFileType {
  /// Localized file format used in versions 1.13 and above
  gsonLang,

  /// Localized file format used in versions below 1.12 (inclusive)
  minecraftLang,
  patchouli,

  /// Plain text format
  /// Each line of text is a source entry, and the key in the source entry uses the md5 hash value of the source content
  plainText,

  /// Custom json format
  /// e.g. Tinkers Construct book...
  customJson
}
