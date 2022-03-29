import "package:rpmtw_server/database/database.dart";

abstract class DBScript {
  Duration get duration;
  Future<void> Function(DataBase db, DateTime time) get execute;

  const DBScript();

  Future<void> start(DataBase db, DateTime time) async {
    await execute(db, time);
  }
}
