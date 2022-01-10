import 'package:pub_semver/pub_semver.dart';
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
