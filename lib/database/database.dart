import 'dart:async';

import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';

import '../utilities/data.dart';
import 'models/auth/user.dart';
import 'models/base_models.dart';
import 'models/storage/storage.dart';

class DataBase {
  static late Db _mongoDB;
  static late DataBase _instance;
  static DataBase get instance => _instance;
  Db get db => _mongoDB;
  GridFS get gridFS => GridFS(DataBase.instance.db);

  DataBase() {
    try {
      startTimer();
    } catch (e, stack) {
      logger.e(e, null, stack);
    }
  }

  static late List<DbCollection> collectionList;

  static Future<DataBase> _open() async {
    collectionList = [];
    List<String> collectionNameList = [
      User.collectionName,
      Storage.collectionName,
      AuthCode.collectionName,
      MinecraftMod.collectionName
    ];
    List<List<IndexFields>> indexFields = [
      User.indexFields,
      Storage.indexFields,
      AuthCode.indexFields,
      MinecraftMod.indexFields
    ];

    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> checkCollection(
        String name, List<IndexFields> indexFields) async {
      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
        await _mongoDB.createIndex(name,
            key: 'uuid', name: 'uuid', unique: true);

        for (IndexFields field in indexFields) {
          await _mongoDB.createIndex(name,
              key: field.name, name: field.name, unique: field.unique);
        }
      }
    }

    for (String name in collectionNameList) {
      await checkCollection(
          name, indexFields[collectionNameList.indexOf(name)]);
      collectionList.add(_mongoDB.collection(name));
    }

    return DataBase();
  }

  static Future<void> init() async {
    String url;

    if (kTestMode) {
      url = "mongodb://127.0.0.1:27017/test";
    } else {
      url = env['DATA_BASE_URL'] ?? "mongodb://127.0.0.1:27017/rpmtw_data";
    }

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    _instance = await DataBase._open();
    loggerNoStack.i("Successfully connected to the database");
  }

  DbCollection getCollection<T extends BaseModels>([String? runtimeType]) {
    Map<String, DbCollection> modelTypeMap = {
      "User": collectionList[0],
      "Storage": collectionList[1],
      "AuthCode": collectionList[2],
      "MinecraftMod": collectionList[3]
    };

    return modelTypeMap[runtimeType ?? T.toString()]!;
  }

  T getModelByMap<T extends BaseModels>(Map<String, dynamic> map) {
    Map<String, T Function(Map<String, dynamic>)> modelTypeMap = {
      "User": User.fromMap,
      "Storage": Storage.fromMap,
      "AuthCode": AuthCode.fromMap,
      "MinecraftMod": MinecraftMod.fromMap
    }.cast<String, T Function(Map<String, dynamic>)>();

    T Function(Map<String, dynamic>) factory = modelTypeMap[T.toString()]!;
    return factory(map);
  }

  Future<T?> getModelByUUID<T extends BaseModels>(String uuid) =>
      getModelByField<T>("uuid", uuid);

  Future<T?> getModelByField<T extends BaseModels>(
      String fieldName, dynamic value) async {
    Map<String, dynamic>? map =
        await getCollection<T>().findOne(where.eq(fieldName, value));

    if (map == null) return null;

    return getModelByMap<T>(map);
  }

  Future<WriteResult> insertOneModel<T extends BaseModels>(T model,
      {WriteConcern? writeConcern, bool? bypassDocumentValidation}) async {
    WriteResult result = await getCollection<T>(model.runtimeType.toString())
        .insertOne(model.toMap(),
            writeConcern: writeConcern,
            bypassDocumentValidation: bypassDocumentValidation);

    result.exceptionHandler(model);
    return result;
  }

  Future<WriteResult> replaceOneModel<T extends BaseModels>(T model,
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

  Future<WriteResult> deleteOneModel<T extends BaseModels>(T model,
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

  Timer startTimer() {
    Timer timer = Timer.periodic(Duration(hours: 1), (timer) async {
      DateTime time = DateTime.now().toUtc();
      await _storageTimer(time);
      await _authCodeTimer(time);
    });
    return timer;
  }

  Future<void> _storageTimer(DateTime time) async {
    /// 暫存檔案超過指定時間後將刪除
    /// 檔案最多暫存一天
    SelectorBuilder selector = where
        .eq("type", StorageType.temp.name) // 檔案類型為暫存檔案
        .and(where.lte('createdAt',
            time.subtract(Duration(days: 1)).millisecondsSinceEpoch));
    // 檔案建立時間為一天前
    List<Storage> storageList = await getCollection<Storage>()
        .find(selector)
        .map((map) => Storage.fromMap(map))
        .toList();

    for (Storage storage in storageList) {
      await storage.delete();
    }
  }

  Future<void> _authCodeTimer(DateTime time) async {
    /// 驗證碼最多暫存 1 小時
    SelectorBuilder selector = where.lte(
        'expiresAt', time.subtract(Duration(hours: 1)).millisecondsSinceEpoch);
    List<AuthCode> authCodeList = await getCollection<AuthCode>()
        .find(selector)
        .map((map) => AuthCode.fromMap(map))
        .toList();

    for (AuthCode authCode in authCodeList) {
      await authCode.delete();
    }
  }
}

class InsertModelException implements Exception {
  final String modelName;
  final String? errorMessage;

  InsertModelException(this.modelName, [this.errorMessage]);

  @override
  String toString() {
    return "InsertModelException: Failed to insert $modelName model.\n$errorMessage";
  }
}

extension WriteResultExtension on WriteResult {
  void exceptionHandler<T extends BaseModels>(T model) {
    if (!success) {
      throw InsertModelException(T.toString(),
          writeError?.errmsg ?? writeConcernError?.errmsg ?? errmsg);
    }
  }
}
