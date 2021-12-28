import 'dart:convert';

import '../base_models.dart';

class Storage implements BaseModels {
  String uuid;
  StorageType type;

  Storage({required this.uuid, required this.type});

  Storage copyWith({String? uuid, List<int>? bytes, StorageType? type}) {
    return Storage(
      uuid: uuid ?? this.uuid,
      type: this.type,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {'uuid': uuid, 'type': type.name};
  }

  factory Storage.fromMap(Map<String, dynamic> map) {
    return Storage(
        uuid: map['uuid'] ?? '',
        type: StorageType.values.byName(map['type'] ?? 'temp'));
  }
  @override
  String toJson() => json.encode(toMap());

  factory Storage.fromJson(String source) =>
      Storage.fromMap(json.decode(source));

  @override
  String toString() => 'Storage(uuid: $uuid, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Storage && other.uuid == uuid && other.type == type;
  }

  @override
  int get hashCode => uuid.hashCode ^ type.hashCode;

  @override
  Map<String, dynamic> outputMap() => toMap();
}

enum StorageType { temp, general }
