import "package:intl/locale.dart";
import "package:rpmtw_server/database/database.dart";

import "package:rpmtw_server/database/models/auth/user.dart";
import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/index_fields.dart";
import "package:rpmtw_server/database/models/model_field.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";

class Translation extends BaseModel {
  static const String collectionName = "translations";
  static const List<IndexField> indexFields = [
    IndexField("sourceUUID", unique: false),
    IndexField("content", unique: false),
    IndexField("translatorUUID", unique: false),
    IndexField("language", unique: false),
  ];

  /// The translation source text.
  /// UUID of [SourceText]
  final String sourceUUID;

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
    return TranslationVote.getAllByTranslationUUID(uuid);
  }

  Future<SourceText?> get source {
    return SourceText.getByUUID(sourceUUID);
  }

  const Translation(
      {required this.sourceUUID,
      required this.content,
      required this.translatorUUID,
      required this.language,
      required String uuid})
      : super(uuid: uuid);

  Translation copyWith({
    String? content,
    String? sourceUUID,
    String? translatorUUID,
  }) {
    return Translation(
      uuid: uuid,
      sourceUUID: sourceUUID ?? this.sourceUUID,
      content: content ?? this.content,
      translatorUUID: translatorUUID ?? this.translatorUUID,
      language: language,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "sourceUUID": sourceUUID,
      "content": content,
      "translatorUUID": translatorUUID,
      "language": language.toLanguageTag()
    };
  }

  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      uuid: map["uuid"],
      sourceUUID: map["sourceUUID"],
      content: map["content"],
      translatorUUID: map["translatorUUID"],
      language: Locale.parse(map["language"]),
    );
  }

  static Future<Translation?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<Translation>(uuid);

  static Future<List<Translation>> search(
          {String? sourceUUID,
          Locale? language,
          String? translatorUUID}) async =>
      DataBase.instance.getModelsByField<Translation>([
        if (sourceUUID != null) ModelField("sourceUUID", sourceUUID),
        if (language != null) ModelField("language", language.toLanguageTag()),
        if (translatorUUID != null) ModelField("translatorUUID", translatorUUID)
      ]);
}
