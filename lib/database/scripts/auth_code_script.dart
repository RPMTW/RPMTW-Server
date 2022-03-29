import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';

class AuthCodeScript extends DBScript {
  @override
  Duration get duration => Duration(minutes: 30);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      /// 驗證碼最多暫存 30 分鐘
      SelectorBuilder selector = where.lte("expiresAt",
          time.subtract(Duration(minutes: 30)).millisecondsSinceEpoch);
      List<AuthCode> authCodeList = await db.getCollection<AuthCode>()
          .find(selector)
          .map((map) => AuthCode.fromMap(map))
          .toList();

      for (AuthCode authCode in authCodeList) {
        await authCode.delete();
      }
    };
  }
}
