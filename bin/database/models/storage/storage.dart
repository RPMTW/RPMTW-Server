import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';

import '../../database.dart';
import '../base_models.dart';

class Storage implements BaseModels {
  String uuid;
  String contentType;
  StorageType type;

  Storage(
      {required this.uuid,
      this.contentType = "binary/octet-stream",
      required this.type});

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

  Storage copyWith({String? uuid, String? contentType, StorageType? type}) {
    return Storage(
      uuid: uuid ?? this.uuid,
      contentType: contentType ?? this.contentType,
      type: this.type,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {'uuid': uuid, 'contentType': contentType, 'type': type.name};
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
        uuid: map['uuid'] ?? '',
        contentType: map['contentType'],
        type: StorageType.values.byName(map['type'] ?? 'temp'));
  }
  @override
  String toJson() => json.encode(toMap());

  factory Storage.fromJson(String source) =>
      Storage.fromMap(json.decode(source));

  @override
  String toString() =>
      'Storage(uuid: $uuid,contentType: $contentType, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Storage &&
        other.uuid == uuid &&
        other.contentType == contentType &&
        other.type == type;
  }

  @override
  int get hashCode => uuid.hashCode ^ contentType.hashCode ^ type.hashCode;

  @override
  Map<String, dynamic> outputMap() => toMap();
}

enum StorageType { temp, general }
