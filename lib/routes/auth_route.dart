import 'package:dbcrypt/dbcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
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
        final passwordValidatedResult = AuthHandler.validatePassword(password);
        if (!passwordValidatedResult.isValid) {
          // 密碼驗證失敗
          return ResponseExtension.badRequest(
              message: passwordValidatedResult.message);
        }
        String email = data['email'];
        // 驗證電子郵件格式
        final emailValidatedResult = await AuthHandler.validateEmail(email);
        if (!emailValidatedResult.isValid) {
          return ResponseExtension.badRequest(
              message: emailValidatedResult.message);
        }
        DBCrypt dbCrypt = DBCrypt();
        String salt =
            dbCrypt.gensaltWithRounds(AuthHandler.saltRounds); // 生成鹽，加密次數為10次
        String hash = dbCrypt.hashpw(password, salt); //使用加鹽算法將明文密碼生成為雜湊值

        User user = User(
            username: data['username'],
            email: email,
            avatarStorageUUID: data['avatarStorageUUID'],
            emailVerified: false,
            passwordHash: hash,
            uuid: Uuid().v4());

        String? avatarStorageUUID = user.avatarStorageUUID;

        if (avatarStorageUUID != null) {
          Storage? storage = await Storage.getByUUID(avatarStorageUUID);
          if (storage == null) {
            return ResponseExtension.notFound('Avatar Storage not found');
          }
          if (storage.type == StorageType.temp) {
            //將暫存檔案改為一般檔案
            storage = storage.copyWith(type: StorageType.general);
            await DataBase.instance.replaceOneModel<Storage>(storage);
          }
        }

        await user.insert(); // 儲存至資料庫

        Map output = user.outputMap();
        output['token'] = AuthHandler.generateAuthToken(user.uuid);
        AuthCode code =
            await AuthHandler.generateAuthCode(user.email, user.uuid);
        bool successful = await AuthHandler.sendVerifyEmail(email, code.code);
        if (!successful) ResponseExtension.internalServerError();
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
          user = await User.getByUUID(uuid);
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

    router.get("/user/get-by-email/<email>", (Request req) async {
      try {
        String email = req.params['email']!;
        User? user = await User.getByEmail(email);
        if (user == null) {
          return ResponseExtension.notFound("User not found");
        }
        return ResponseExtension.success(data: user.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    /// 更新使用者資訊
    router.post("/user/<uuid>/update", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        User? user;
        if (uuid == "me") {
          user = req.user;
        } else {
          user = await User.getByUUID(uuid);
        }
        if (user == null) {
          return ResponseExtension.notFound("User not found");
        }
        User newUser = user;
        Map data = await req.data;
        String password = data['password'];

        bool checkPassword =
            AuthHandler.checkPassword(password, newUser.passwordHash);
        if (!checkPassword) {
          return ResponseExtension.badRequest(message: "Password is incorrect");
        }

        String? newPassword = data['newPassword'];
        String? email = data['newEmail'];
        String? username = data['newUsername'];
        String? avatarStorageUUID = data['newAvatarStorageUUID'];

        if (newPassword != null) {
          // 使用者想要修改密碼
          final passwordValidatedResult =
              AuthHandler.validatePassword(password);
          if (!passwordValidatedResult.isValid) {
            // 密碼驗證失敗
            return ResponseExtension.badRequest(
                message: passwordValidatedResult.message);
          }
          DBCrypt dbCrypt = DBCrypt();
          String salt = dbCrypt.gensaltWithRounds(AuthHandler.saltRounds);
          String hash = dbCrypt.hashpw(password, salt);
          newUser = newUser.copyWith(passwordHash: hash);
        }
        if (email != null) {
          // 使用者想要修改電子郵件
          final emailValidatedResult = await AuthHandler.validateEmail(email);
          if (!emailValidatedResult.isValid) {
            return ResponseExtension.badRequest(
                message: emailValidatedResult.message);
          }
          newUser = newUser.copyWith(email: email);
        }
        if (username != null) {
          // 使用者想要修改名稱
          newUser = newUser.copyWith(username: username);
        }
        if (avatarStorageUUID != null) {
          // 使用者想要修改帳號圖片
          Storage? storage = await Storage.getByUUID(avatarStorageUUID);
          if (storage == null) {
            return ResponseExtension.notFound('Avatar Storage not found');
          }
          if (storage.type == StorageType.temp) {
            //將暫存檔案改為一般檔案
            storage = storage.copyWith(type: StorageType.general);
            await DataBase.instance.replaceOneModel<Storage>(storage);
          }
          newUser = newUser.copyWith(avatarStorageUUID: avatarStorageUUID);
        }

        if (newUser != user) {
          // 如果資料變更才儲存至資料庫
          await newUser.update();
        }
        return ResponseExtension.success(data: newUser.outputMap());
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
        User? user = await User.getByUUID(uuid);
        if (user == null) {
          return ResponseExtension.notFound("User not found");
        }
        bool checkPassword =
            AuthHandler.checkPassword(password, user.passwordHash);
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

    router.get("/valid-auth-code", (Request req) async {
      try {
        Map<String, dynamic> queryParameters = req.requestedUri.queryParameters;
        int authCode = int.parse(queryParameters['authCode']!);
        String email = queryParameters['email']!;
        bool isValid = await AuthHandler.validateAuthCode(email, authCode);
        return ResponseExtension.success(data: {
          'isValid': isValid,
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
