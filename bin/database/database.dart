import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

class DataBase {
  static late Db _mongoDB;
  static late DataBase _instance;
  static DataBase get instance => _instance;
  Db get db => _mongoDB;

  final DbCollection _usersCollection;

  DbCollection get usersCollection => _usersCollection;

  DataBase(this._usersCollection);

  static Future<DataBase> _open() async {
    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> checkCollection(String name) async {
      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
      }
    }

    await checkCollection('users');

    return DataBase(_mongoDB.collection('users'));
  }

  static Future<void> init() async {
    // InternetAddress ip = InternetAddress.anyIPv4;

    String username = env['DATA_BASE_USERNAME']!;
    String password = env['DATA_BASE_PASSWORD']!;
    String host = env['DATA_BASE_HOST']!;
    String port = env['DATA_BASE_PORT']!;
    String name = env['DATA_BASE_NAME']!;

    String? testUrl = env['DATA_BASE_TEST_URL'];

    String url =
        testUrl ?? "mongodb+srv://$username:$password@$host:$port/$name";

    //   print(url);

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    _instance = await DataBase._open();
    print("Successfully connected to the database");
  }
}
