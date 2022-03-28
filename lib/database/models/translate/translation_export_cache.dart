import "package:intl/locale.dart";
import 'package:mongo_dart/mongo_dart.dart';

import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/translate/translation_export_format.dart";
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';

class TranslationExportCache extends DBModel {
  static const String collectionName = "translation_export_caches";
  static const List<IndexField> indexFields = [
    IndexField("modSourceInfoUUID", unique: true),
    IndexField("language", unique: false),
    IndexField("format", unique: false),
    IndexField("createdAt", unique: false),
  ];

  final String modSourceInfoUUID;
  final Locale language;
  final TranslationExportFormat format;
  final DateTime createdAt;
  final Map<String, String> data;

  const TranslationExportCache({
    required String uuid,
    required this.modSourceInfoUUID,
    required this.language,
    required this.format,
    required this.createdAt,
    required this.data,
  }) : super(uuid: uuid);

  TranslationExportCache copyWith({
    DateTime? createdAt,
    Map<String, String>? data,
  }) {
    return TranslationExportCache(
      uuid: uuid,
      modSourceInfoUUID: modSourceInfoUUID,
      language: language,
      format: format,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "modSourceInfoUUID": modSourceInfoUUID,
      "language": language.toLanguageTag(),
      "format": format.name,
      "createdAt": createdAt.millisecondsSinceEpoch,
      "data": data,
    };
  }

  factory TranslationExportCache.fromMap(Map<String, dynamic> map) {
    return TranslationExportCache(
      uuid: map["uuid"],
      modSourceInfoUUID: map["modSourceInfoUUID"],
      language: Locale.parse(map["language"]),
      format: TranslationExportFormat.values.byName(map["format"]),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map["createdAt"], isUtc: true),
      data: map["data"].cast<String, String>(),
    );
  }

  static Future<TranslationExportCache?> getByInfos(
    String modSourceInfoUUID,
    Locale language,
    TranslationExportFormat format,
  ) async {
    TranslationExportCache? cache = await DataBase.instance
        .getModelWithSelector(where.eq("modSourceInfoUUID", modSourceInfoUUID)
          ..eq("language", language.toLanguageTag())
          ..eq("format", format.name));

    if (cache == null) {
      return null;
    }

    /// Check if the cache is older than 30 minutes
    /// If so, delete it
    if (cache.createdAt
        .add(Duration(minutes: 30))
        .isBefore(DateTime.now().toUtc())) {
      await cache.delete();
      return null;
    }

    return cache;
  }
}
