import 'dart:async';

import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/db_model_data.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/scripts/auth_code_script.dart';
import 'package:rpmtw_server/database/scripts/comment_script.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';
import 'package:rpmtw_server/database/scripts/minecraft_version_manifest_script.dart';
import 'package:rpmtw_server/database/scripts/storage_script.dart';
import 'package:rpmtw_server/database/scripts/translate_status_script.dart';
import 'package:rpmtw_server/database/scripts/view_count_script.dart';
import 'package:rpmtw_server/database/scripts/wiki_changelog_script.dart';

import '../utilities/data.dart';
import 'db_model.dart';

class DataBase {
  static late Db _mongoDB;
  static late DataBase _instance;
  static DataBase get instance => _instance;
  Db get db => _mongoDB;
  GridFS get gridFS => GridFS(DataBase.instance.db);

  DataBase() {
    try {
      startScripts();
    } catch (e, stack) {
      logger.e(e, null, stack);
    }
  }

  static late List<DbCollection> collectionList;

  static Future<DataBase> _open() async {
    collectionList = [];

    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> createIndex(String name, List<IndexField> indexFields) async {
      for (IndexField field in indexFields) {
        await _mongoDB.createIndex(name,
            key: field.name, name: field.name, unique: field.unique);
      }
    }

    List<String> collectionNameList = DBModelData.collectionNameList;
    List<List<IndexField>> indexFields = DBModelData.indexFields;

    for (String name in collectionNameList) {
      DbCollection collection = _mongoDB.collection(name);

      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
        await _mongoDB.createIndex(name,
            key: 'uuid', name: 'uuid', unique: true);
      }

      List<Map<String, dynamic>> indexes = await collection.getIndexes();
      List<String> indexFieldsName =
          indexes.map((index) => index['name'] as String).toList();
      List<IndexField> _indexFields =
          indexFields[collectionNameList.indexOf(name)];

      final needCreateIndex = !collections.contains(name) ||
          _indexFields.any((field) => !indexFieldsName.contains(field.name));
      if (needCreateIndex) {
        await createIndex(name, _indexFields);
      }
      collectionList.add(collection);
    }

    return DataBase();
  }

  static Future<void> init() async {
    String url;

    if (kTestMode) {
      url = 'mongodb://127.0.0.1:27017/test';
    } else {
      url = env['DATA_BASE_URL'] ?? 'mongodb://127.0.0.1:27017/rpmtw_data';
    }

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    if (kTestMode) {
      // Drop test database
      await _mongoDB.drop();
    }
    _instance = await DataBase._open();
    loggerNoStack.i('Successfully connected to the database');
  }

  DbCollection getCollection<T extends DBModel>([String? runtimeType]) {
    return DBModelData.collectionMap(
        collectionList)[runtimeType ?? T.toString()]!;
  }

  T getModelByMap<T extends DBModel>(Map<String, dynamic> map) {
    T Function(Map<String, dynamic>) factory = DBModelData.fromMap
        .cast<String, T Function(Map<String, dynamic>)>()[T.toString()]!;
    return factory(map);
  }

  Future<T?> getModelByUUID<T extends DBModel>(String uuid) =>
      getModelByField<T>('uuid', uuid);

  Future<T?> getModelByField<T extends DBModel>(
      String fieldName, dynamic value) async {
    final Map<String, dynamic>? map =
        await getCollection<T>().findOne(where.eq(fieldName, value));

    return map != null ? getModelByMap<T>(map) : null;
  }

  Future<T?> getModelByFields<T extends DBModel>(List<ModelField> field) async {
    final SelectorBuilder selector = SelectorBuilder();

    for (ModelField f in field) {
      selector.eq(f.name, f.value);
    }

    final Map<String, dynamic>? map =
        await getCollection<T>().findOne(selector);

    return map != null ? getModelByMap<T>(map) : null;
  }

  Future<T?> getModelWithSelector<T extends DBModel>(
      SelectorBuilder selector) async {
    final Map<String, dynamic>? map =
        await getCollection<T>().findOne(selector);

    return map != null ? getModelByMap<T>(map) : null;
  }

  Future<List<T>> getModelsWithSelector<T extends DBModel>(
      SelectorBuilder selector) async {
    final List<Map<String, dynamic>> maps =
        await getCollection<T>().find(selector).toList();

    return maps.map((map) => getModelByMap<T>(map)).toList();
  }

  Future<List<T>> getModelsByField<T extends DBModel>(List<ModelField> field,
      {int? limit, int? skip}) async {
    final SelectorBuilder selector = SelectorBuilder();

    for (ModelField f in field) {
      selector.eq(f.name, f.value);
    }

    if (limit != null) {
      selector.limit(limit);
    }
    if (skip != null) {
      selector.skip(skip);
    }

    final List<Map<String, dynamic>>? list =
        await getCollection<T>().find(selector).toList();

    return list?.map((m) => getModelByMap<T>(m)).toList() ?? List.empty();
  }

  Future<WriteResult> insertOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern, bool? bypassDocumentValidation}) async {
    WriteResult result = await getCollection<T>(model.runtimeType.toString())
        .insertOne(model.toMap(),
            writeConcern: writeConcern,
            bypassDocumentValidation: bypassDocumentValidation);

    result.exceptionHandler(model);
    return result;
  }

  Future<WriteResult> replaceOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      String? hint,
      Map<String, Object>? hintDocument}) async {
    WriteResult result =
        await getCollection<T>(model.runtimeType.toString()).replaceOne(
      where.eq('uuid', model.uuid),
      model.toMap(),
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );

    result.exceptionHandler(model);
    return result;
  }

  Future<WriteResult> deleteOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      String? hint,
      Map<String, Object>? hintDocument}) async {
    WriteResult result =
        await getCollection<T>(model.runtimeType.toString()).deleteOne(
      where.eq('uuid', model.uuid),
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );

    result.exceptionHandler(model);
    return result;
  }

  void startScripts() async {
    List<DBScript> scripts = [
      StorageScript(),
      AuthCodeScript(),
      MinecraftVersionManifestScript(),
      ViewCountScript(),
      WikiChangelogScript(),
      CommentScript(),
      TranslateStatusScript()
    ];

    for (DBScript script in scripts) {
      Future<void> _start() async {
        DateTime time = RPMTWUtil.getUTCTime();
        try {
          await script.start(this, time);
        } catch (e) {
          // ignore
        }
      }

      await _start();
      Timer.periodic(script.duration, (timer) async {
        await _start();
      });
    }
  }
}

class InsertModelException implements Exception {
  final String modelName;
  final String? errorMessage;

  InsertModelException(this.modelName, [this.errorMessage]);

  @override
  String toString() {
    return 'InsertModelException: Failed to insert $modelName model.\n$errorMessage';
  }
}

extension WriteResultExtension on WriteResult {
  void exceptionHandler<T extends DBModel>(T model) {
    if (!success) {
      throw InsertModelException(T.toString(),
          writeError?.errmsg ?? writeConcernError?.errmsg ?? errmsg);
    }
  }
}
