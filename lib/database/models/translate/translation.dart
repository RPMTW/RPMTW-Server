import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:intl/locale.dart';

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

  /// [User] UUID of the translator
  final String translatorUUID;

  final List<TranslationVote> votes;

  final Locale language;

  const Translation(
      {required this.content,
      required this.translatorUUID,
      required this.votes,
      required this.language,
      required String uuid})
      : super(uuid: uuid);

  Future<User?> get translator {
    return User.getByUUID(translatorUUID);
  }

  Translation copyWith({
    String? content,
    String? translatorUUID,
    List<TranslationVote>? votes,
  }) {
    return Translation(
      uuid: uuid,
      content: content ?? this.content,
      translatorUUID: translatorUUID ?? this.translatorUUID,
      votes: votes ?? this.votes,
      language: language,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'content': content,
      'translatorUUID': translatorUUID,
      'votes': votes.map((x) => x.toMap()).toList(),
      'language': language.toLanguageTag()
    };
  }

  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      uuid: map['uuid'],
      content: map['content'],
      translatorUUID: map['translatorUUID'],
      votes: List<TranslationVote>.from(
          map['votes']?.map((x) => TranslationVote.fromMap(x))),
      language: Locale.parse(map['language']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Translation.fromJson(String source) =>
      Translation.fromMap(json.decode(source));

  @override
  String toString() =>
      'Translation(content: $content, translatorUUID: $translatorUUID, votes: $votes, language: $language)';

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
}
