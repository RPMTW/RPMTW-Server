import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/utilities/utility.dart';

class ViewCountHandler {
  static final List<_Filter> _filters = [];
  static bool needUpdate(String ip, String modUUID) {
    _Filter? getFilter(String userIP) {
      try {
        return _filters.firstWhere(
          (f) => f.userIP == userIP,
        );
      } catch (e) {
        return null;
      }
    }

    _Filter? filter = getFilter(ip);

    if (filter == null) {
      _filters.add(_Filter(
          userIP: ip, viewedMods: {modUUID}, createdAt: Utility.getUTCTime()));
      return true;
    } else {
      bool viewed = filter.isViewedMod(modUUID);
      if (!viewed) {
        _filters.add(filter.copyWith(
            viewedMods: Set.from(filter.viewedMods)..add(modUUID)));
        return true;
      } else {
        return false;
      }
    }
  }

  static void deleteFilters(DateTime time) {
    // Delete records from a day ago
    _filters.removeWhere(
      (f) => f.createdAt.isBefore(time.subtract(Duration(days: 1))),
    );
  }
}

class _Filter {
  final String userIP;

  /// 已瀏覽過的模組 ( [MinecraftMod] 的 UUID )
  final Set<String> viewedMods;

  final DateTime createdAt;

  const _Filter({
    required this.userIP,
    required this.viewedMods,
    required this.createdAt,
  });

  bool isViewedMod(String modUUID) {
    return viewedMods.contains(modUUID);
  }

  _Filter copyWith({
    String? userIP,
    Set<String>? viewedMods,
    DateTime? createdAt,
  }) {
    return _Filter(
      userIP: userIP ?? this.userIP,
      viewedMods: viewedMods ?? this.viewedMods,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
