import 'dart:convert';

import 'package:collection/collection.dart';

import '../base_models.dart';

class Storage implements BaseModels {
  String uuid;
  List<int> bytes;
  StorageType type;

  Storage({required this.uuid, required this.bytes, required this.type});

  Storage copyWith({String? uuid, List<int>? bytes, StorageType? type}) {
    return Storage(
      uuid: uuid ?? this.uuid,
      bytes: bytes ?? this.bytes,
      type: this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {'uuid': uuid, 'bytes': bytes, 'type': type.name};
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
        uuid: map['uuid'] ?? '',
        bytes: List<int>.from(map['bytes']),
        type: StorageType.values.byName(map['type'] ?? 'temp'));
  }

  String toJson() => json.encode(toMap());

  factory Storage.fromJson(String source) =>
      Storage.fromMap(json.decode(source));

  @override
  String toString() => 'Storage(uuid: $uuid, bytes: $bytes, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Storage &&
        other.uuid == uuid &&
        listEquals(other.bytes, bytes) &&
        other.type == type;
  }

  @override
  int get hashCode => uuid.hashCode ^ bytes.hashCode ^ type.hashCode;

  @override
  Map<String, dynamic> outputMap() => toMap();
}

enum StorageType { temp, general }
