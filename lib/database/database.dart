import 'dart:async';

import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

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
      startStorageTimer();
    } catch (e, stack) {
      logger.e(e, null, stack);
    }
  }

  static late List<DbCollection> collectionList;

  static Future<DataBase> _open() async {
    collectionList = [];
    List<String> collectionNameList = ["users", "storages"];
    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> checkCollection(String name) async {
      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
        await _mongoDB.createIndex(name,
            key: "uuid", name: 'uuid', unique: true);
      }
    }

    for (String name in collectionNameList) {
      await checkCollection(name);
      collectionList.add(_mongoDB.collection(name));
    }

    return DataBase();
  }

  static Future<void> init() async {
    String url = env['DATA_BASE_URL'] ?? "mongodb://127.0.0.1:27017/rpmtw_data";

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    _instance = await DataBase._open();
    loggerNoStack.i("Successfully connected to the database");
    // await AuthHandler.initGoogleApis();
    // loggerNoStack.i("Successfully connected to Google APIs");
  }

  DbCollection getCollection<T extends BaseModels>() {
    Map<String, DbCollection> modelTypeMap = {
      "User": collectionList[0],
      "Storage": collectionList[1],
    };

    return modelTypeMap[T.toString()]!;
  }

  T getModelFromMap<T extends BaseModels>(Map<String, dynamic> map) {
    Map<String, T Function(Map<String, dynamic>)> modelTypeMap = {
      "User": User.fromMap,
      "Storage": Storage.fromMap,
    }.cast<String, T Function(Map<String, dynamic>)>();

    T Function(Map<String, dynamic>) factory = modelTypeMap[T.toString()]!;
    return factory(map);
  }

  Future<T?> getModelFromUUID<T extends BaseModels>(String uuid) async {
    Map<String, dynamic>? map =
        await getCollection<T>().findOne(where.eq('uuid', uuid));

    if (map == null) return null;

    return getModelFromMap<T>(map);
  }

  Future<WriteResult> insertOneModel<T extends BaseModels>(T model,
      {WriteConcern? writeConcern, bool? bypassDocumentValidation}) async {
    WriteResult result = await getCollection<T>().insertOne(model.toMap(),
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
    WriteResult result = await getCollection<T>().replaceOne(
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
    WriteResult result = await getCollection<T>().deleteOne(
      where.eq('uuid', model.uuid),
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );

    result.exceptionHandler(model);

    return result;
  }

  Timer startStorageTimer() {
    /// 暫存檔案超過指定時間後將刪除
    Timer timer = Timer.periodic(Duration(hours: 1), (timer) async {
      DateTime time = DateTime.now().toUtc();

      /// 檔案最多暫存一天
      SelectorBuilder selector = where
          .eq("type", StorageType.temp.name) // 檔案類型為暫存檔案
          .and(where.lte('createdAt', time.subtract(Duration(days: 1))));
      // 檔案建立時間為一天前
      List<Storage> storageList = await getCollection<Storage>()
          .find(selector)
          .map((map) => Storage.fromMap(map))
          .toList();

      for (Storage storage in storageList) {
        await deleteOneModel<Storage>(storage);
      }
    });
    return timer;
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