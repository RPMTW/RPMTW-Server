import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';

class WikiChangelogScript extends DBScript {
  @override
  Duration get duration => Duration(hours: 12);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      /// 變更日誌超過指定時間後將刪除
      /// 變更日誌最多暫存 90 天 ( 約為三個月 )
      SelectorBuilder selector = where.lte(
          "time", time.subtract(Duration(days: 90)).millisecondsSinceEpoch);
      // 變更日誌建立時間為 90 天前

      List<WikiChangeLog> changelogs = await db
          .getCollection<WikiChangeLog>()
          .find(selector)
          .map((map) => WikiChangeLog.fromMap(map))
          .toList();

      for (WikiChangeLog log in changelogs) {
        await log.delete();
      }
    };
  }
}
