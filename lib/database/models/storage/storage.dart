import 'dart:convert';
import "dart:typed_data";

import "package:http/http.dart" as http;
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/index_fields.dart";

import "../../database.dart";
import "../base_models.dart";

class Storage extends BaseModel {
  static const String collectionName = "storages";
  static const List<IndexField> indexFields = [
    IndexField("createAt", unique: false),
    IndexField("type", unique: false)
  ];

  final String contentType;
  final StorageType type;
  final DateTime createAt;
  final int usageCount;

  const Storage(
      {required String uuid,
      this.contentType = "binary/octet-stream",
      required this.type,
      required this.createAt,
      this.usageCount = 0})
      : super(uuid: uuid);

  Future<Uint8List> readAsBytes() async {
    GridFS fs = DataBase.instance.gridFS;
    GridOut gridOut = (await fs.getFile(uuid))!;

    List<Map<String, dynamic>> chunks = await (fs.chunks
        .find(where.eq("files_id", gridOut.id).sortBy("n"))
        .toList());

    List<List<int>> _chunks = [];
    for (Map<String, dynamic> chunk in chunks) {
      final data = chunk["data"] as BsonBinary;
      _chunks.add(data.byteList.toList());
    }

    http.ByteStream byteStream = http.ByteStream(Stream.fromIterable(_chunks));
    return Uint8List.fromList(await byteStream.toBytes());
  }

  Future<String> readAsString({Encoding encoding = utf8}) async {
    return encoding.decode(await readAsBytes());
  }

  Storage copyWith(
      {String? contentType,
      StorageType? type,
      DateTime? createAt,
      int? usageCount}) {
    return Storage(
      uuid: uuid,
      contentType: contentType ?? this.contentType,
      type: type ?? this.type,
      createAt: createAt ?? this.createAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "contentType": contentType,
      "type": type.name,
      "createAt": createAt.millisecondsSinceEpoch,
      "usageCount": usageCount,
    };
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
        uuid: map["uuid"],
        contentType: map["contentType"],
        type: StorageType.values.byName(map["type"] ?? "temp"),
        createAt:
            DateTime.fromMillisecondsSinceEpoch(map["createAt"], isUtc: true),
        usageCount: map["usageCount"]);
  }

  static Future<Storage?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<Storage>(uuid);
}

enum StorageType { temp, general }
