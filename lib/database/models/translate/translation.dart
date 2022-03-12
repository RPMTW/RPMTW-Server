import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';

class Translation extends BaseModels {
  static const String collectionName = "translations";
  static const List<IndexFields> indexFields = [];

  final String source;

  final String content;

  /// [User] UUID of the translator
  final String translatorUUID;

  Translation(this.content, this.translatorUUID, this.source, {required String uuid})
      : super(uuid: uuid);

  Future<User?> get translator {
    return User.getByUUID(translatorUUID);
  }
}
