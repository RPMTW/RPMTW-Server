import 'package:dbcrypt/dbcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/auth_route.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'api_route.dart';

class AuthRoute extends APIRoute {
  @override
  String get routeName => 'auth';

  @override
  void router(router) {
    router.postRoute('/user/create', (req, data) async {
      String password = data.fields['password'];
      final passwordValidatedResult = AuthHandler.validatePassword(password);
      if (!passwordValidatedResult.isValid) {
        // 密碼驗證失敗
        return APIResponse.badRequest(message: passwordValidatedResult.message);
      }
      String email = data.fields['email'];
      // 驗證電子郵件格式
      final emailValidatedResult = await AuthHandler.validateEmail(email);
      if (!emailValidatedResult.isValid) {
        return APIResponse.badRequest(message: emailValidatedResult.message);
      }
      DBCrypt dbCrypt = DBCrypt();
      String salt =
          dbCrypt.gensaltWithRounds(AuthHandler.saltRounds); // 生成鹽，加密次數為10次
      String hash = dbCrypt.hashpw(password, salt); //使用加鹽算法將明文密碼生成為雜湊值

      User user = User(
          username: data.fields['username'],
          email: email,
          avatarStorageUUID: data.fields['avatarStorageUUID'],
          emailVerified: false,
          passwordHash: hash,
          uuid: Uuid().v4(),
          loginIPs: [req.ip]);

      String? avatarStorageUUID = user.avatarStorageUUID;

      if (avatarStorageUUID != null) {
        Storage? storage = await Storage.getByUUID(avatarStorageUUID);
        if (storage == null) {
          return APIResponse.modelNotFound(modelName: 'Avatar Storage');
        }

        /// Change temp storage to general storage
        storage = storage.copyWith(
            type: StorageType.general, usageCount: storage.usageCount + 1);
        await DataBase.instance.replaceOneModel<Storage>(storage);
      }

      await user.insert(); // 儲存至資料庫

      Map output = user.outputMap();
      output['token'] = AuthHandler.generateAuthToken(user.uuid);
      AuthCode code = await AuthHandler.generateAuthCode(user.email, user.uuid);
      bool successful = await AuthHandler.sendVerifyEmail(email, code.code);
      if (!successful) APIResponse.internalServerError();

      return APIResponse.success(data: output);
    }, requiredFields: ['password', 'email', 'username']);

    router.getRoute('/user/<uuid>', (req, data) async {
      String uuid = data.fields['uuid']!;
      User? user;
      if (uuid == 'me') {
        user = req.user;
      } else {
        user = await User.getByUUID(uuid);
      }
      if (user == null) {
        return APIResponse.modelNotFound<User>();
      }
      return APIResponse.success(data: user.outputMap());
    }, authConfig: AuthConfig(path: '/auth/user/me'));

    router.getRoute('/user/get-by-email/<email>', (req, data) async {
      String email = data.fields['email']!;
      User? user = await User.getByEmail(email);
      if (user == null) {
        return APIResponse.modelNotFound<User>();
      }
      return APIResponse.success(data: user.outputMap());
    });

    /// 更新使用者資訊
    router.postRoute('/user/<uuid>/update', (req, data) async {
      String uuid = data.fields['uuid']!;
      User? user;
      if (uuid == 'me') {
        user = req.user;
      } else {
        user = await User.getByUUID(uuid);
      }
      if (user == null) {
        return APIResponse.modelNotFound<User>();
      }
      User newUser = user;
      String? password = data.fields['password'];

      bool isAuthenticated = req.isAuthenticated() ||
          AuthHandler.checkPassword(password!, newUser.passwordHash);
      if (!isAuthenticated) {
        return APIResponse.unauthorized();
      }

      String? newPassword = data.fields['newPassword'];
      String? email = data.fields['newEmail'];
      String? username = data.fields['newUsername'];
      String? avatarStorageUUID = data.fields['newAvatarStorageUUID'];

      if (newPassword != null) {
        // 使用者想要修改密碼
        final passwordValidatedResult =
            AuthHandler.validatePassword(newPassword);
        if (!passwordValidatedResult.isValid) {
          // 密碼驗證失敗
          return APIResponse.badRequest(
              message: passwordValidatedResult.message);
        }
        DBCrypt dbCrypt = DBCrypt();
        String salt = dbCrypt.gensaltWithRounds(AuthHandler.saltRounds);
        String hash = dbCrypt.hashpw(newPassword, salt);
        newUser = newUser.copyWith(passwordHash: hash);
      }
      if (email != null) {
        // 使用者想要修改電子郵件
        final emailValidatedResult = await AuthHandler.validateEmail(email);
        if (!emailValidatedResult.isValid) {
          return APIResponse.badRequest(message: emailValidatedResult.message);
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
          return APIResponse.modelNotFound(modelName: 'Avatar Storage');
        }

        /// Change temp storage to general storage
        storage = storage.copyWith(
            type: StorageType.general, usageCount: storage.usageCount + 1);
        await storage.update();
        newUser = newUser.copyWith(avatarStorageUUID: avatarStorageUUID);
        Storage? oldStorage = await user.avatarStorage;
        await oldStorage
            ?.copyWith(
                usageCount:
                    oldStorage.usageCount > 0 ? oldStorage.usageCount - 1 : 0)
            .update();
      }

      if (newUser != user) {
        // 如果資料變更才儲存至資料庫
        await newUser.update();
      }
      return APIResponse.success(data: newUser.outputMap());
    }, authConfig: AuthConfig());

    /*
    取得 Token
    所需參數:
    [uuid] 使用者 UUID
    [password] 使用者密碼
    e.g.
    {
      'uuid': 'e5634ad4-529d-42d4-9a56-045c5f5888cd',
      'password': 'test'
    } 
    */
    router.postRoute('/get-token', (req, data) async {
      String uuid = data.fields['uuid'];
      String password = data.fields['password'];
      User? user = await User.getByUUID(uuid);
      if (user == null) {
        return APIResponse.modelNotFound<User>();
      }
      bool checkPassword =
          AuthHandler.checkPassword(password, user.passwordHash);
      if (!checkPassword) {
        return APIResponse.badRequest(message: 'Password is incorrect');
      }
      Map output = user.outputMap();
      output['token'] = AuthHandler.generateAuthToken(user.uuid);
      return APIResponse.success(data: output);
    }, requiredFields: ['uuid', 'password']);

    router.getRoute('/valid-password', (req, data) async {
      String password = data.fields['password']!;
      final validatedResult = AuthHandler.validatePassword(password);
      return APIResponse.success(data: validatedResult.toMap());
    }, requiredFields: ['password']);

    router.getRoute('/valid-auth-code', (req, data) async {
      int authCode = int.parse(data.fields['authCode']!);
      String email = data.fields['email']!;
      bool isValid = await AuthHandler.validateAuthCode(email, authCode);
      return APIResponse.success(data: {
        'isValid': isValid,
      });
    }, requiredFields: ['authCode', 'email']);
  }
}
