import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';

import '../../database.dart';
import '../base_models.dart';

class Storage extends BaseModels {
  static const String collectionName = "storages";
  static const List<IndexFields> indexFields = [
    IndexFields("createAt", unique: false),
    IndexFields("type", unique: false)
  ];

  final String contentType;
  final StorageType type;
  final int createAt;

  DateTime get createAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createAt).toUtc();

  const Storage(
      {required String uuid,
      this.contentType = "binary/octet-stream",
      required this.type,
      required this.createAt})
      : super(uuid: uuid);

  Future<Uint8List?> readAsBytes() async {
    GridFS fs = DataBase.instance.gridFS;
    GridOut? gridOut = await fs.getFile(uuid);
    if (gridOut == null) return null;
    List<Map<String, dynamic>> chunks = await (fs.chunks
        .find(where.eq('files_id', gridOut.id).sortBy('n'))
        .toList());

    List<List<int>> _chunks = [];
    for (Map<String, dynamic> chunk in chunks) {
      final data = chunk['data'] as BsonBinary;
      _chunks.add(data.byteList.toList());
    }

    http.ByteStream byteStream = http.ByteStream(Stream.fromIterable(_chunks));
    return Uint8List.fromList(await byteStream.toBytes());
  }

  Storage copyWith(
      {String? uuid, String? contentType, StorageType? type, int? createAt}) {
    return Storage(
      uuid: uuid ?? this.uuid,
      contentType: contentType ?? this.contentType,
      type: type ?? this.type,
      createAt: createAt ?? this.createAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'contentType': contentType,
      'type': type.name,
      'createAt': createAt
    };
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
        uuid: map['uuid'] ?? '',
        contentType: map['contentType'],
        type: StorageType.values.byName(map['type'] ?? 'temp'),
        createAt:
            map['createAt'] ?? DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  @override
  String toString() =>
      'Storage(uuid: $uuid,contentType: $contentType, type: $type, createAt: $createAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Storage &&
        other.uuid == uuid &&
        other.contentType == contentType &&
        other.type == type &&
        other.createAt == createAt;
  }

  @override
  int get hashCode =>
      uuid.hashCode ^ contentType.hashCode ^ type.hashCode ^ createAt.hashCode;

  static Future<Storage?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<Storage>(uuid);
}

enum StorageType { temp, general }
