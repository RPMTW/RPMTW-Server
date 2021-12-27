import 'dart:convert';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../utilities//extension.dart';
import '../utilities/data.dart';

class AuthRoute {
  Router get router {
    final Router router = Router();

    router.post('/user/create', (Request req) async {
      try {
        Map<String, dynamic> data = json.decode(await req.readAsString());
        DBCrypt dbCrypt = DBCrypt();
        String salt = dbCrypt.gensaltWithRounds(10); // 生成鹽，加密次數為10次
        String hash =
            dbCrypt.hashpw(data['password'], salt); //使用加鹽算法將明文密碼生成為雜湊值
        User user = User.fromMap(data);
        user = user.copyWith(passwordHash: hash, uuid: Uuid().v4());

        await DataBase.instance.usersCollection
            .insertOne(user.toMap()); // 儲存至資料庫

        return ResponseExtension.success(data: user.outputMap());
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
