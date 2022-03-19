import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/index_fields.dart";
import 'package:rpmtw_server/database/models/model_field.dart';

class TranslationVote extends BaseModel {
  static const String collectionName = "translation_votes";
  static const List<IndexField> indexFields = [
    IndexField("translationUUID", unique: false),
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
  }) {
    return TranslationVote(
      uuid: uuid,
      type: type ?? this.type,
      translationUUID: translationUUID,
      userUUID: userUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "type": type.name,
      "translationUUID": translationUUID,
      "userUUID": userUUID,
    };
  }

  factory TranslationVote.fromMap(Map<String, dynamic> map) {
    return TranslationVote(
      uuid: map["uuid"],
      type: TranslationVoteType.values.byName(map["type"]),
      translationUUID: map["translationUUID"] ?? "",
      userUUID: map["userUUID"] ?? "",
    );
  }

  static Future<TranslationVote?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<TranslationVote>(uuid);

  static Future<List<TranslationVote>> getAllByTranslationUUID(
          String uuid) async =>
      DataBase.instance.getModelsByField<TranslationVote>(
          [ModelField("translationUUID", uuid)]);
}

enum TranslationVoteType { up, down }
