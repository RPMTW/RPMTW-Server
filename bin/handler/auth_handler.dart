import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';

class AuthHandler {
  static SecretKey secretKey = SecretKey(env['DATA_BASE_SecretKey']!);

  static String generateAuthToken(String userUUID) {
    JWT jwt = JWT({'uuid': userUUID});
    return jwt.sign(AuthHandler.secretKey);
  }

  static Middleware authorizationToken() => (innerHandler) {
        return (request) {
          return Future.sync(() async {
            String path = request.url.path;
            List<String> needAuthorizationPaths = ["auth/user/me"];
            if (needAuthorizationPaths.contains(path)) {
              String? token = request.headers['Authorization']
                  ?.toString()
                  .replaceAll('Bearer ', '');
              if (token == null) {
                return ResponseExtension.unauthorized();
              }
              try {
                JWT jwt = JWT.verify(token, secretKey);
                Map<String, dynamic> payload = jwt.payload;
                String uuid = payload['uuid'];
                User? user =
                    await DataBase.instance.getModelFromUUID<User>(uuid);
                if (user == null) {
                  return ResponseExtension.unauthorized();
                }
                request = request.change(context: {"user": user});
              } on JWTError catch (e) {
                logger.e(e.message, null, e.stackTrace);
                return ResponseExtension.unauthorized();
              } catch (e, stack) {
                logger.e(e, null, stack);
                return ResponseExtension.internalServerError();
              }
            }
            return await innerHandler(request);
          }).then((response) {
            return response;
          });
        };
      };

  static _PasswordValidatedResult validatePassword(String password) {
    if (password.length < 6) {
      //密碼至少需要6個字元
      return _PasswordValidatedResult(
          false, 1, "Password must be at least 6 characters long");
    } else if (password.length > 30) {
      // 密碼最多30個字元
      return _PasswordValidatedResult(
          false, 2, "Password must be less than 30 characters long");
    } else if (!password.contains(RegExp(r'[A-Za-z]'))) {
      // 密碼必須至少包含一個英文字母
      return _PasswordValidatedResult(
          false, 3, "Password must contain at least one letter of English.");
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      // 密碼必須至少包含一個數字
      return _PasswordValidatedResult(
          false, 4, "Password must contain at least one number");
    } else {
      return _PasswordValidatedResult(true, 0, "no issue");
    }
  }
}

class _PasswordValidatedResult {
  /// 是否驗證成功
  bool isValid;

  /// 驗證結果代碼
  int code;

  /// 驗證結果訊息
  String message;
  _PasswordValidatedResult(this.isValid, this.code, this.message);

  Map toMap() {
    return {"isValid": isValid, "code": code, "message": message};
  }
}
