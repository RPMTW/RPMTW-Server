import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';

class TranslationVote extends BaseModels {
  static const String collectionName = "translation_votes";
  static const List<IndexFields> indexFields = [
    IndexFields("translationUUID", unique: false),
  ];

  final TranslationVoteType type;
  final String translationUUID;
  final String userUUID;

  bool get isUpVote => type == TranslationVoteType.up;
  bool get isDownVote => type == TranslationVoteType.down;

  const TranslationVote({
    required String uuid,
    required this.type,
    required this.translationUUID,
    required this.userUUID,
  }) : super(uuid: uuid);

  TranslationVote copyWith({
    TranslationVoteType? type,
    String? translationUUID,
    String? userUUID,
  }) {
    return TranslationVote(
      uuid: uuid,
      type: type ?? this.type,
      translationUUID: translationUUID ?? this.translationUUID,
      userUUID: userUUID ?? this.userUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'type': type.name,
      'translationUUID': translationUUID,
      'userUUID': userUUID,
    };
  }

  factory TranslationVote.fromMap(Map<String, dynamic> map) {
    return TranslationVote(
      uuid: map['uuid'],
      type: TranslationVoteType.values.byName(map['type']),
      translationUUID: map['translationUUID'] ?? '',
      userUUID: map['userUUID'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TranslationVote &&
        other.type == type &&
        other.translationUUID == translationUUID &&
        other.userUUID == userUUID;
  }

  @override
  int get hashCode =>
      type.hashCode ^ translationUUID.hashCode ^ userUUID.hashCode;

  static Future<TranslationVote?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<TranslationVote>(uuid);

  static Future<List<TranslationVote>> getByTranslationUUID(
          String uuid) async =>
      DataBase.instance
          .getModelsByField<TranslationVote>("translationUUID", uuid);
}

enum TranslationVoteType { up, down }
