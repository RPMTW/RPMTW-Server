import 'dart:convert';

class RelationMod {
  // 被串連的模組 UUID
  final String modUUID;

  // 關聯模組條件 (例如在某些版本情況下才適用)
  final String? condition;

  // 關聯類型 (例如 前置模組/衝突模組/連動模組)
  final RelationType type;
  RelationMod({
    required this.modUUID,
    this.condition,
    required this.type,
  });

  RelationMod copyWith({
    String? modUUID,
    String? condition,
    RelationType? type,
  }) {
    return RelationMod(
      modUUID: modUUID ?? this.modUUID,
      condition: condition ?? this.condition,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modUUID': modUUID,
      'condition': condition,
      'type': type.name,
    };
  }

  factory RelationMod.fromMap(Map<String, dynamic> map) {
    return RelationMod(
      modUUID: map['modUUID'] ?? '',
      condition: map['condition'],
      type: RelationType.values.byName(map['type']),
    );
  }

  String toJson() => json.encode(toMap());

  factory RelationMod.fromJson(String source) =>
      RelationMod.fromMap(json.decode(source));

  @override
  String toString() =>
      'RelationMod(modUUID: $modUUID, condition: $condition, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RelationMod &&
        other.modUUID == modUUID &&
        other.condition == condition &&
        other.type == type;
  }

  @override
  int get hashCode => modUUID.hashCode ^ condition.hashCode ^ type.hashCode;
}

enum RelationType {
  dependency, // 前置模組
  conflict, // 衝突模組
  integration, // 連動模組
  reforged, // 重製、移植模組
  other, // 其他類型的關聯模組
}
