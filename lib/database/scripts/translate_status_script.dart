import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/translate/mod_source_info.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';
import 'package:rpmtw_server/handler/translate_handler.dart';

class TranslateStatusScript extends DBScript {
  /// uuid of [ModSourceInfo]
  static final Set<String> _editedInfos = {};

  static void addToQueue(String infoUUID) {
    if (!_editedInfos.contains(infoUUID)) {
      _editedInfos.add(infoUUID);
    }
  }

  @override
  Duration get duration => Duration(minutes: 30);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      while (_editedInfos.isNotEmpty) {
        String infoUUID = _editedInfos.first;
        _editedInfos.remove(infoUUID);
        ModSourceInfo? info = await ModSourceInfo.getByUUID(infoUUID);
        
        if (info != null) {
          await TranslateHandler.updateOrCreateStatus(info);
        } else {
          await TranslateHandler.deleteStatus(infoUUID);
        }
      }

      /// Update global status
      TranslateHandler.updateOrCreateStatus(null);
    };
  }
}
