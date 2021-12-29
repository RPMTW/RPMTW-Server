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
}
