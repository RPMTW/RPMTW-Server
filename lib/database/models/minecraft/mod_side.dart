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
