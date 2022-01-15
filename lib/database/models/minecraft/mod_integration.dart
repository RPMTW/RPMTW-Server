import 'dart:convert';

class ModIntegrationPlatform {
  final String? curseForgeID;
  final String? modrinthID;
  ModIntegrationPlatform({
    this.curseForgeID,
    this.modrinthID,
  });

  bool get isCurseForge => curseForgeID != null;
  bool get isModrinth => modrinthID != null;
  bool get hasIntegration => isCurseForge || isModrinth;

  ModIntegrationPlatform copyWith({
    String? curseForgeID,
    String? modrinthID,
  }) {
    return ModIntegrationPlatform(
      curseForgeID: curseForgeID ?? this.curseForgeID,
      modrinthID: modrinthID ?? this.modrinthID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'curseForgeID': curseForgeID,
      'modrinthID': modrinthID,
    };
  }

  factory ModIntegrationPlatform.fromMap(Map<String, dynamic> map) {
    return ModIntegrationPlatform(
      curseForgeID: map['curseForgeID'],
      modrinthID: map['modrinthID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ModIntegrationPlatform.fromJson(String source) =>
      ModIntegrationPlatform.fromMap(json.decode(source));

  @override
  String toString() =>
      'ModIntegration(curseForgeID: $curseForgeID, modrinthID: $modrinthID)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ModIntegrationPlatform &&
        other.curseForgeID == curseForgeID &&
        other.modrinthID == modrinthID;
  }

  @override
  int get hashCode => curseForgeID.hashCode ^ modrinthID.hashCode;
}
