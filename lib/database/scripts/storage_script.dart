import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';

class StorageScript extends DBScript {
  @override
  Duration get duration => Duration(hours: 1);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      /// 暫存檔案超過指定時間後將刪除
      /// 檔案最多暫存一天
      SelectorBuilder timeSelector = where.lte(
          "createAt", time.subtract(Duration(days: 1)).millisecondsSinceEpoch);

      SelectorBuilder selector = where
          // 檔案類型為暫存檔案
          .eq("type", StorageType.temp.name)
          .and(timeSelector)
          .or(where.eq("usageCount", 0).and(timeSelector));
      // 檔案建立時間為一天前

      List<Storage> storageList = await db
          .getCollection<Storage>()
          .find(selector)
          .map((map) => Storage.fromMap(map))
          .toList();

      for (Storage storage in storageList) {
        GridOut? gridOut = await db.gridFS.getFile(storage.uuid);

        /// 刪除實際的二進位檔案
        await gridOut?.fs.files.deleteOne(gridOut.data);
        await gridOut?.fs.chunks
            .deleteMany(where.eq("files_id", storage.uuid).sortBy("n"));

        /// 刪除儲存數據 model
        await storage.delete();
      }
    };
  }
}
