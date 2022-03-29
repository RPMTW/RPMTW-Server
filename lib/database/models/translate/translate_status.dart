import "package:intl/locale.dart";
import "package:rpmtw_server/database/database.dart";
import 'package:rpmtw_server/database/db_model.dart';
import "package:rpmtw_server/database/index_fields.dart";

class TranslateStatus extends DBModel {
  static const String collectionName = "translate_status";
  static const List<IndexField> indexFields = [
    IndexField("modSourceInfoUUID", unique: true)
  ];

  /// If null, the status is global.
  final String? modSourceInfoUUID;

  final int totalWords;
  final Map<Locale, int> translatedWords;
  final DateTime lastUpdated;

  /// Check if the status is older than an hour
  bool get isExpired =>
      DateTime.now().toUtc().difference(lastUpdated).inHours > 1;

  const TranslateStatus({
    required String uuid,
    required this.modSourceInfoUUID,
    required this.totalWords,
    required this.translatedWords,
    required this.lastUpdated,
  }) : super(uuid: uuid);

  TranslateStatus copyWith({
    int? totalWords,
    Map<Locale, int>? translatedWords,
    DateTime? lastUpdated,
  }) {
    return TranslateStatus(
      uuid: uuid,
      modSourceInfoUUID: modSourceInfoUUID,
      totalWords: totalWords ?? this.totalWords,
      translatedWords: translatedWords ?? this.translatedWords,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "modSourceInfoUUID": modSourceInfoUUID,
      "totalWords": totalWords,
      "translatedWords": translatedWords
          .map((key, value) => MapEntry(key.toLanguageTag(), value)),
      "lastUpdated": lastUpdated.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      "modSourceInfoUUID": modSourceInfoUUID,
      "totalWords": totalWords,
      "translatedWords": translatedWords
          .map((key, value) => MapEntry(key.toLanguageTag(), value)),
      "lastUpdated": lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory TranslateStatus.fromMap(Map<String, dynamic> map) {
    return TranslateStatus(
      uuid: map["uuid"],
      modSourceInfoUUID: map["modSourceInfoUUID"],
      totalWords: map["totalWords"],
      translatedWords: Map.from((map["translatedWords"] as Map)
          .cast<String, int>()
          .map((key, value) => MapEntry(Locale.parse(key), value))
          .cast<Locale, int>()),
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map["lastUpdated"], isUtc: true),
    );
  }

  static Future<TranslateStatus?> getByModSourceInfoUUID(String? uuid) =>
      DataBase.instance.getModelByField("modSourceInfoUUID", uuid);
}
