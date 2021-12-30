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

  DataBase();

  static final List<String> collectionList = ["users", "storages"];

  static Future<DataBase> _open() async {
    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> checkCollection(String name) async {
      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
      } else {
        await _mongoDB.createIndex(name,
            key: "uuid", name: 'uuid', unique: true);
      }
    }

    for (String name in collectionList) {
      await checkCollection(name);
    }

    return DataBase();
  }

  static Future<void> init() async {
    String url = env['DATA_BASE_URL']!;

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    _instance = await DataBase._open();
    loggerNoStack.i("Successfully connected to the database");
  }

  String getCollectionName<T extends BaseModels>() {
    Map<String, String> modelTypeMap = {
      "User": 'users',
      "Storage": 'storages',
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
    DbCollection collection = _mongoDB.collection(getCollectionName<T>());
    Map<String, dynamic>? map =
        await collection.findOne(where.eq('uuid', uuid));

    if (map == null) return null;

    return getModelFromMap<T>(map);
  }

  Future<WriteResult> insertOneModel<T extends BaseModels>(T model,
      {WriteConcern? writeConcern, bool? bypassDocumentValidation}) async {
    DbCollection collection = _mongoDB.collection(getCollectionName<T>());
    WriteResult result = await collection.insertOne(model.toMap(),
        writeConcern: writeConcern,
        bypassDocumentValidation: bypassDocumentValidation);

    if (!result.success) {
      throw InsertModelException(
          T.toString(),
          result.writeError?.errmsg ??
              result.writeConcernError?.errmsg ??
              result.errmsg);
    }

    return result;
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
