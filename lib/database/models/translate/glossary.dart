import 'package:intl/locale.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';

class Glossary extends DBModel {
  static const String collectionName = 'glossaries';
  static const List<IndexField> indexFields = [
    IndexField('term', unique: false),
    IndexField('language', unique: false),
    IndexField('modUUID', unique: false),
  ];

  final String term;
  final String translation;
  final String? description;
  final Locale language;
  final String? modUUID;

  const Glossary({
    required String uuid,
    required this.term,
    required this.translation,
    this.description,
    required this.language,
    this.modUUID,
  }) : super(uuid: uuid);

  Glossary copyWith({
    String? term,
    String? translation,
    String? description,
    String? modUUID,
  }) {
    return Glossary(
      uuid: uuid,
      term: term ?? this.term,
      translation: translation ?? this.translation,
      description: description ?? this.description,
      language: language,
      modUUID: modUUID ?? this.modUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'term': term,
      'translation': translation,
      'description': description,
      'language': language.toLanguageTag(),
      'modUUID': modUUID,
    };
  }

  factory Glossary.fromMap(Map<String, dynamic> map) {
    return Glossary(
      uuid: map['uuid'],
      term: map['term'],
      translation: map['translation'],
      description: map['description'],
      language: Locale.parse(map['language']),
      modUUID: map['modUUID'],
    );
  }

  static Future<Glossary?> getByUUID(String uuid) =>
      DataBase.instance.getModelByUUID<Glossary>(uuid);

  static Future<List<Glossary>> list(
      {Locale? language,
      String? modUUID,
      String? filter,
      int? limit,
      int? skip}) async {
    SelectorBuilder selector = SelectorBuilder();

    if (language != null) {
      selector.eq('language', language.toLanguageTag());
    }

    if (modUUID != null) {
      selector.eq('modUUID', modUUID);
    }

    if (filter != null) {
      selector
          .match('term', '(?i)$filter')
          .or(where.match('translation', '(?i)$filter'));
    }

    if (limit != null) {
      selector.limit(limit);
    }

    if (skip != null) {
      selector.skip(skip);
    }

    return DataBase.instance.getModelsWithSelector(selector);
  }
}
