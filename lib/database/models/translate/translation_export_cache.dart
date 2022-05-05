import 'package:intl/locale.dart';

import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/models/translate/translation_export_format.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/utilities/utility.dart';

class TranslationExportCache extends DBModel {
  static const String collectionName = 'translation_export_caches';
  static const List<IndexField> indexFields = [
    IndexField('modSourceInfoUUID', unique: true),
    IndexField('language', unique: false),
    IndexField('format', unique: false)
  ];

  final String modSourceInfoUUID;
  final Locale language;
  final TranslationExportFormat format;
  final DateTime lastUpdated;
  final Map<String, String> data;

  /// Check if the cache is older than 30 minutes
  bool get isExpired =>
      Utility.getUTCTime().difference(lastUpdated).inMinutes > 30;

  const TranslationExportCache({
    required String uuid,
    required this.modSourceInfoUUID,
    required this.language,
    required this.format,
    required this.lastUpdated,
    required this.data,
  }) : super(uuid: uuid);

  TranslationExportCache copyWith({
    DateTime? lastUpdated,
    Map<String, String>? data,
  }) {
    return TranslationExportCache(
      uuid: uuid,
      modSourceInfoUUID: modSourceInfoUUID,
      language: language,
      format: format,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'modSourceInfoUUID': modSourceInfoUUID,
      'language': language.toLanguageTag(),
      'format': format.name,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory TranslationExportCache.fromMap(Map<String, dynamic> map) {
    return TranslationExportCache(
      uuid: map['uuid'],
      modSourceInfoUUID: map['modSourceInfoUUID'],
      language: Locale.parse(map['language']),
      format: TranslationExportFormat.values.byName(map['format']),
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'], isUtc: true),
      data: map['data'].cast<String, String>(),
    );
  }

  static Future<TranslationExportCache?> getByInfos(
    String modSourceInfoUUID,
    Locale language,
    TranslationExportFormat format,
  ) =>
      DataBase.instance.getModelByFields([
        ModelField('modSourceInfoUUID', modSourceInfoUUID),
        ModelField('language', language.toLanguageTag()),
        ModelField('format', format.name)
      ]);
}
