import 'dart:convert';

class ModIntegration {
  final String? curseForgeID;
  final String? modrinthID;
  ModIntegration({
    this.curseForgeID,
    this.modrinthID,
  });

  bool get isCurseForge => curseForgeID != null;
  bool get isModrinth => modrinthID != null;
  bool get hasIntegration => isCurseForge || isModrinth;

  ModIntegration copyWith({
    String? curseForgeID,
    String? modrinthID,
  }) {
    return ModIntegration(
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

  factory ModIntegration.fromMap(Map<String, dynamic> map) {
    return ModIntegration(
      curseForgeID: map['curseForgeID'],
      modrinthID: map['modrinthID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ModIntegration.fromJson(String source) => ModIntegration.fromMap(json.decode(source));

  @override
  String toString() => 'ModIntegration(curseForgeID: $curseForgeID, modrinthID: $modrinthID)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ModIntegration &&
      other.curseForgeID == curseForgeID &&
      other.modrinthID == modrinthID;
  }

  @override
  int get hashCode => curseForgeID.hashCode ^ modrinthID.hashCode;
}
