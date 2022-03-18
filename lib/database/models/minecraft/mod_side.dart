import "dart:convert";

class ModSide {
  /// 執行環境
  final ModSideEnvironment environment;

  /// 執行環境的需求類型 (必需/可選/不支援)
  final ModRequireType requireType;
  ModSide({
    required this.environment,
    required this.requireType,
  });

  ModSide copyWith({
    ModSideEnvironment? environment,
    ModRequireType? requireType,
  }) {
    return ModSide(
      environment: environment ?? this.environment,
      requireType: requireType ?? this.requireType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "environment": environment.name,
      "requireType": requireType.name,
    };
  }

  factory ModSide.fromMap(Map<String, dynamic> map) {
    return ModSide(
      environment: ModSideEnvironment.values.byName(map["environment"]),
      requireType: ModRequireType.values.byName(map["requireType"]),
    );
  }

  String toJson() => json.encode(toMap());

  factory ModSide.fromJson(String source) =>
      ModSide.fromMap(json.decode(source));

  @override
  String toString() =>
      "ModSide(environment: $environment, requireType: $requireType)";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModSide &&
        other.environment == environment &&
        other.requireType == requireType;
  }

  @override
  int get hashCode => environment.hashCode ^ requireType.hashCode;
}

enum ModSideEnvironment {
  client,
  server,
}

enum ModRequireType {
  required,
  optional,
  unsupported,
}
