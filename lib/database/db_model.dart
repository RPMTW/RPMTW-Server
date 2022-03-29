import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/database.dart";

/// Model of database abstract class.
abstract class DBModel {
  /// UUID of this model.
  /// This is unique key of this model.
  final String uuid;

  const DBModel({required this.uuid});

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }

  /// Output a JSON map to the general user.
  /// Avoid the general user to get confidential data.
  Map<String, dynamic> outputMap() => toMap();

  /// Delete the model from the database.
  Future<WriteResult> delete() async {
    return DataBase.instance.deleteOneModel(this);
  }

  /// Insert the model to the database.
  Future<WriteResult> insert() async {
    return DataBase.instance.insertOneModel(this);
  }

  /// Update the model in the database.
  /// If the model is not exist, throw an exception.
  Future<WriteResult> update() async {
    return DataBase.instance.replaceOneModel(this);
  }
}
