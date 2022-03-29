import "package:rpmtw_server/data/user_view_count_filter.dart";
import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/scripts/db_script.dart";

class ViewCountScript extends DBScript {
  @override
  Duration get duration => Duration(hours: 3);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      ViewCountHandler.deleteFilters(time);
    };
  }
}
