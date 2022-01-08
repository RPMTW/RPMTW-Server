import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';

abstract class BaseModels {
  final String uuid;

  const BaseModels({required this.uuid});

  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }

  Map<String, dynamic> outputMap() => toMap();

  Future<WriteResult> delete() async {
    return DataBase.instance.deleteOneModel(this);
  }

  Future<WriteResult> insert() async {
    return DataBase.instance.insertOneModel(this);
  }

  Future<WriteResult> update() async {
    return DataBase.instance.replaceOneModel(this);
  }
}
