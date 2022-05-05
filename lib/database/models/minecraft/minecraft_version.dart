import 'package:pub_semver/pub_semver.dart';

import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
import 'package:rpmtw_server/utilities/request_extension.dart';
import 'package:rpmtw_server/utilities/utility.dart';

class MinecraftVersion {
  final String id;

  final MinecraftVersionType type;

  final String url;

  final String time;

  final String releaseTime;

  final String sha1;

  final int complianceLevel;

  DateTime get timeDateTime => DateTime.parse(time);

  DateTime get releaseDateTime => DateTime.parse(releaseTime);

  Version get comparableVersion => Utility.parseMCComparableVersion(id);

  String get mainVersion =>
      '${comparableVersion.major}.${comparableVersion.minor}';

  MinecraftVersion(this.id, this.type, this.url, this.time, this.releaseTime,
      this.sha1, this.complianceLevel);

  factory MinecraftVersion.fromMap(Map map) {
    return MinecraftVersion(
        map['id'],
        MinecraftVersionType.values.firstWhere((_) => _.name == map['type']),
        map['url'],
        map['time'],
        map['releaseTime'],
        map['sha1'],
        map['complianceLevel']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'url': url,
      'time': time,
      'releaseTime': releaseTime,
      'sha1': sha1,
      'complianceLevel': complianceLevel
    };
  }

  static Future<MinecraftVersion?> getByID(String id) async {
    final List<MinecraftVersion> _allVersions =
        (await MinecraftVersionManifest.getFromCache()).manifest.versions;

    return _allVersions.firstWhereOrNull((e) => id.contains(e.id));
  }

  static Future<List<MinecraftVersion>> getByIDs(List<String> ids,
      {bool mainVersion = false}) async {
    final List<MinecraftVersion> _allVersions =
        (await MinecraftVersionManifest.getFromCache()).manifest.versions;

    List<MinecraftVersion> versions = [];
    try {
      versions = _allVersions.where((e) => ids.contains(e.id)).toList();
      if (mainVersion) {
        versions = versions
            .map((ver) =>
                _allVersions.firstWhere((e) => e.id == ver.mainVersion))
            .toList();
      }

      versions
          .sort((a, b) => a.comparableVersion.compareTo(b.comparableVersion));
      versions = versions.toSet().toList();
      return versions;
    } catch (e) {
      return [];
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MinecraftVersion &&
        other.id == id &&
        other.type == type &&
        other.url == url &&
        other.time == time &&
        other.releaseTime == releaseTime &&
        other.sha1 == sha1 &&
        other.complianceLevel == complianceLevel;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        url.hashCode ^
        time.hashCode ^
        releaseTime.hashCode ^
        sha1.hashCode ^
        complianceLevel.hashCode;
  }
}

enum MinecraftVersionType {
  release,
  snapshot,
  beta,
  alpha,
}

extension MCVersionTypeExtension on MinecraftVersionType {
  String get name {
    switch (this) {
      case MinecraftVersionType.release:
        return 'release';
      case MinecraftVersionType.snapshot:
        return 'snapshot';
      case MinecraftVersionType.beta:
        return 'old_beta';
      case MinecraftVersionType.alpha:
        return 'old_alpha';
    }
  }
}
