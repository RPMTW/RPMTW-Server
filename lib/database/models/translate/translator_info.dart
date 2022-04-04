import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';

class TranslatorInfo extends DBModel {
  static const String collectionName = 'translator_infos';
  static const List<IndexField> indexFields = [
    IndexField('userUUID', unique: true),
    IndexField('translatedCount', unique: false),
    IndexField('votedCount', unique: false)
  ];

  final String userUUID;
  final List<DateTime> translatedCount;
  final List<DateTime> votedCount;

  final DateTime joinAt;

  const TranslatorInfo({
    required String uuid,
    required this.userUUID,
    required this.translatedCount,
    required this.votedCount,
    required this.joinAt,
  }) : super(uuid: uuid);

  TranslatorInfo copyWith({
    List<DateTime>? translatedCount,
    List<DateTime>? votedCount,
  }) {
    return TranslatorInfo(
      uuid: uuid,
      userUUID: userUUID,
      translatedCount: translatedCount ?? this.translatedCount,
      votedCount: votedCount ?? this.votedCount,
      joinAt: joinAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'userUUID': userUUID,
      'translatedCount':
          translatedCount.map((x) => x.millisecondsSinceEpoch).toList(),
      'votedCount': votedCount.map((x) => x.millisecondsSinceEpoch).toList(),
      'joinAt': joinAt.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      'uuid': uuid,
      'userUUID': userUUID,
      'translatedCount': translatedCount.length,
      'votedCount': votedCount.length,
      'joinAt': joinAt.millisecondsSinceEpoch,
    };
  }

  factory TranslatorInfo.fromMap(Map<String, dynamic> map) {
    return TranslatorInfo(
      uuid: map['uuid'],
      userUUID: map['userUUID'],
      translatedCount: List<DateTime>.from(map['translatedCount']
          ?.map((x) => DateTime.fromMillisecondsSinceEpoch(x, isUtc: true))),
      votedCount: List<DateTime>.from(map['votedCount']
          ?.map((x) => DateTime.fromMillisecondsSinceEpoch(x, isUtc: true))),
      joinAt: DateTime.fromMillisecondsSinceEpoch(map['joinAt'], isUtc: true),
    );
  }

  static Future<TranslatorInfo?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<TranslatorInfo>(uuid);

  static Future<TranslatorInfo?> getByUserUUID(String userUUID) =>
      DataBase.instance.getModelByField<TranslatorInfo>('userUUID', userUUID);
}
