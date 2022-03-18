import 'package:collection/collection.dart';
import 'package:intl/locale.dart';
import 'package:rpmtw_server/database/database.dart';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/translate/translation_vote.dart';

class Translation extends BaseModels {
  static const String collectionName = "translations";
  static const List<IndexFields> indexFields = [
    IndexFields("translatorUUID", unique: false),
    IndexFields("language", unique: false),
  ];

  /// Translated text
  final String content;

  /// Uuid of translator
  final String translatorUUID;

  /// Language of translation
  final Locale language;

  Future<User?> get translator {
    return User.getByUUID(translatorUUID);
  }

  Future<List<TranslationVote>> get votes {
    return TranslationVote.getByTranslationUUID(uuid);
  }

  const Translation(
      {required this.content,
      required this.translatorUUID,
      required this.language,
      required String uuid})
      : super(uuid: uuid);

  Translation copyWith({
    String? content,
    String? translatorUUID,
  }) {
    return Translation(
      uuid: uuid,
      content: content ?? this.content,
      translatorUUID: translatorUUID ?? this.translatorUUID,
      language: language,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'content': content,
      'translatorUUID': translatorUUID,
      'language': language.toLanguageTag()
    };
  }

  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      uuid: map['uuid'],
      content: map['content'],
      translatorUUID: map['translatorUUID'],
      language: Locale.parse(map['language']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Translation &&
        other.content == content &&
        other.translatorUUID == translatorUUID &&
        listEquals(other.votes, votes) &&
        other.language == language;
  }

  @override
  int get hashCode =>
      content.hashCode ^
      translatorUUID.hashCode ^
      votes.hashCode ^
      language.hashCode;

  static Future<Translation?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<Translation>(uuid);
}
