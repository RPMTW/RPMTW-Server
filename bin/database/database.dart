import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../utilities/data.dart';
import 'models/storage/storage.dart';

class DataBase {
  static late Db _mongoDB;
  static late DataBase _instance;
  static DataBase get instance => _instance;
  Db get db => _mongoDB;

  final DbCollection _usersCollection;
  final DbCollection _storagesCollection;

  DbCollection get usersCollection => _usersCollection;
  DbCollection get storagesCollection => _storagesCollection;

  DataBase(this._usersCollection, this._storagesCollection);

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

    await checkCollection('users');
    await checkCollection('storages');

    return DataBase(
        _mongoDB.collection('users'), _mongoDB.collection('storages'));
  }

  static Future<void> init() async {
    String url = env['DATA_BASE_URL']!;

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    _instance = await DataBase._open();
    loggerNoStack.i("Successfully connected to the database");
  }

  Future<Storage?> getStorageFromUUID(String uuid) async {
    Map<String, dynamic>? data =
        await _storagesCollection.findOne(where.eq('uuid', uuid));
    if (data == null) return null;
    return Storage.fromMap(data);
  }
}
