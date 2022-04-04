import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';

class MinecraftVersionManifestScript extends DBScript {
  @override
  Duration get duration => Duration(hours: 12);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      /// 每天更新一次 Minecraft 版本資訊
      int timeStamp = time.subtract(Duration(days: 1)).millisecondsSinceEpoch;
      SelectorBuilder selector = where.gte('lastUpdated', timeStamp);
      DbCollection collection = db.getCollection<MinecraftVersionManifest>();
      List<Map<String, dynamic>> manifests =
          await collection.find(selector).toList();
      if (manifests.isEmpty) {
        ///如果為空則代表最後一次更新為一天前

        /// 刪除其他已經過期的資料
        await collection.deleteMany(where.lte('lastUpdated', timeStamp));

        ///從 Mojang API 取得 Minecraft 版本資訊
        MinecraftVersionManifest manifest =
            await MinecraftVersionManifest.getFromWeb();

        await manifest.insert();
      }
    };
  }
}
