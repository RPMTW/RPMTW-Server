import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../database/models/storage/storage.dart';
import '../utilities//extension.dart';
import '../utilities/data.dart';
import 'base_route.dart';
import 'root_route.dart';

class AuthRoute implements BaseRoute {
  SecretKey key = SecretKey(env['DATA_BASE_SecretKey']!);

  @override
  Router get router {
    final Router router = Router();

    router.post('/user/create', (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;
        DBCrypt dbCrypt = DBCrypt();
        String salt = dbCrypt.gensaltWithRounds(10); // 生成鹽，加密次數為10次
        String hash =
            dbCrypt.hashpw(data['password'], salt); //使用加鹽算法將明文密碼生成為雜湊值
        User user = User.fromMap(data);
        user = user.copyWith(passwordHash: hash, uuid: Uuid().v4());

        String? avatarStorageUUID = user.avatarStorageUUID;
        if (avatarStorageUUID != null) {
          Storage? storage =
              await DataBase.instance.getStorageFromUUID(avatarStorageUUID);
          if (storage == null) {
            return ResponseExtension.notFound('Avatar Storage not found');
          }
        }

        await DataBase.instance.usersCollection
            .insertOne(user.toMap()); // 儲存至資料庫

        Map output = user.outputMap();
        JWT jwt = JWT({'uuid': user.uuid});
        output['token'] = jwt.sign(key);
        return ResponseExtension.success(data: output);
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/user/<uuid>", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        Map<String, dynamic>? data = await DataBase.instance.usersCollection
            .findOne(where.eq('uuid', uuid));
        if (data == null) {
          return ResponseExtension.notFound();
        }
        User user = User.fromMap(data);
        return ResponseExtension.success(data: user.outputMap());
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }

  Middleware authorizationToken() => (innerHandler) {
        return (request) {
          return Future.sync(() async {
            String path = request.url.path;
            List<String> ignorePaths = ["", "auth/user/create", "auth/user/"];
            if (!ignorePaths.any((_path) => path.startsWith(_path))) {
              String? token = request.headers['Authorization']
                  ?.toString()
                  .replaceAll('Bearer ', '');
              if (token == null) {
                return ResponseExtension.unauthorized();
              }
              try {
                JWT jwt = JWT.verify(token, key);
                Map<String, dynamic> payload = jwt.payload;
                String uuid = payload['uuid'];
                Map<String, dynamic>? data = await DataBase
                    .instance.usersCollection
                    .findOne(where.eq('uuid', uuid));
                if (data == null) {
                  return ResponseExtension.unauthorized();
                }
                User user = User.fromMap(data);
                request.change(context: {"user": user});
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
