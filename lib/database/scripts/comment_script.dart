import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/comment/comment.dart';
import 'package:rpmtw_server/database/scripts/db_script.dart';

class CommentScript extends DBScript {
  @override
  Duration get duration => Duration(hours: 15);

  @override
  Future<void> Function(DataBase db, DateTime time) get execute {
    return (db, time) async {
      /// When the comment is hidden and the time is over 7 days ( a week ), the comment will be deleted.
      SelectorBuilder selector = where
          .lte("updatedAt",
              time.subtract(Duration(days: 7)).millisecondsSinceEpoch)
          .eq("isHidden", true);

      List<Comment> comments = await db
          .getCollection<Comment>()
          .find(selector)
          .map((map) => Comment.fromMap(map))
          .toList();

      for (Comment comment in comments) {
        await comment.delete();
      }
    };
  }
}
