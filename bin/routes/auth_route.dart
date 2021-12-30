import 'package:dbcrypt/dbcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../database/models/storage/storage.dart';
import '../handler/auth_handler.dart';
import '../utilities//extension.dart';
import '../utilities/data.dart';
import 'base_route.dart';
import 'root_route.dart';

class AuthRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.post('/user/create', (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;
        String password = data['password'];
        final validatedResult = AuthHandler.validatePassword(password);
        if (!validatedResult.isValid) {
          // 密碼驗證失敗
          return ResponseExtension.badRequest(message: validatedResult.message);
        }

        DBCrypt dbCrypt = DBCrypt();
        String salt = dbCrypt.gensaltWithRounds(10); // 生成鹽，加密次數為10次
        String hash = dbCrypt.hashpw(password, salt); //使用加鹽算法將明文密碼生成為雜湊值
        User user = User.fromMap(data);
        user = user.copyWith(passwordHash: hash, uuid: Uuid().v4());

        String? avatarStorageUUID = user.avatarStorageUUID;
        if (avatarStorageUUID != null) {
          Storage? storage = await DataBase.instance
              .getModelFromUUID<Storage>(avatarStorageUUID);
          if (storage == null) {
            return ResponseExtension.notFound('Avatar Storage not found');
          }
          if (storage.type == StorageType.temp) {
            //將暫存檔案改為一般檔案
            storage = storage.copyWith(type: StorageType.general);
            await DataBase.instance.replaceOneModel<Storage>(storage);
          }
        }

        await DataBase.instance.insertOneModel<User>(user); // 儲存至資料庫

        Map output = user.outputMap();
        output['token'] = AuthHandler.generateAuthToken(user.uuid);
        return ResponseExtension.success(data: output);
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/user/<uuid>", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        User? user;
        if (uuid == "me") {
          user = req.user;
        } else {
          user = await DataBase.instance.getModelFromUUID<User>(uuid);
        }
        if (user == null) {
          return ResponseExtension.notFound("User not found");
        }
        return ResponseExtension.success(data: user.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    /*
    取得 Token
    所需參數:
    [uuid] 使用者 UUID
    [password] 使用者密碼
    e.g.
    {
      "uuid": "e5634ad4-529d-42d4-9a56-045c5f5888cd",
      "password": "test"
    } 
    */
    router.post("/get-token", (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;

        String uuid = data['uuid'];
        String password = data['password'];
        User? user = await DataBase.instance.getModelFromUUID<User>(uuid);
        if (user == null) {
          return ResponseExtension.notFound("User not found");
        }
        DBCrypt dbCrypt = DBCrypt();
        bool checkPassword = dbCrypt.checkpw(password, user.passwordHash);
        if (!checkPassword) {
          return ResponseExtension.badRequest(message: "Password is incorrect");
        }
        Map output = user.outputMap();
        output['token'] = AuthHandler.generateAuthToken(user.uuid);
        return ResponseExtension.success(data: output);
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/valid-password", (Request req) async {
      try {
        Map<String, dynamic> queryParameters = req.requestedUri.queryParameters;
        String password = queryParameters['password']!;
        final validatedResult = AuthHandler.validatePassword(password);
        return ResponseExtension.success(data: validatedResult.toMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
