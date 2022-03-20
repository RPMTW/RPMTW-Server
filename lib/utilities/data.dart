import "package:collection/collection.dart";
import "package:dotenv/dotenv.dart";
import "package:intl/locale.dart";
import "package:logger/logger.dart";

import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";

Logger logger =
    Logger(printer: PrettyPrinter(colors: false), filter: _LogFilter());

Logger loggerNoStack = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: false),
    filter: _LogFilter());

bool kTestMode = false;

class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    /// 永遠啟用日誌輸出
    return true;
  }
}

class Data {
  static Future<void> init({Parser? envParser}) async {
    load(".env", envParser ?? const Parser());
  }

  static List<Locale> rpmTranslatorSupportedLanguage = [
    // Traditional Chinese
    Locale.fromSubtags(languageCode: "zh", countryCode: "TW"),
    // Simplified Chinese
    Locale.fromSubtags(languageCode: "zh", countryCode: "CN"),
  ];

  static List<String> rpmTranslatorSupportedVersion = [
    "1.12",
    "1.16",
    "1.17",
    "1.18",
   // "1.19"
  ];
}

class UserViewCountFilter {
  static final List<UserViewCountFilter> _filters = [];

  final String userIP;

  /// 已瀏覽過的模組 ( [MinecraftMod] 的 UUID )
  final Set<String> viewedMods;

  final DateTime createdAt;

  const UserViewCountFilter({
    required this.userIP,
    required this.viewedMods,
    required this.createdAt,
  });

  bool isViewed(String wikiModDataUUID) {
    return viewedMods.contains(wikiModDataUUID);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final setEquals = const DeepCollectionEquality().equals;

    return other is UserViewCountFilter &&
        other.userIP == userIP &&
        setEquals(other.viewedMods, viewedMods) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      userIP.hashCode ^ viewedMods.hashCode ^ createdAt.hashCode;

  UserViewCountFilter copyWith({
    String? userIP,
    Set<String>? viewedMods,
    DateTime? createdAt,
  }) {
    return UserViewCountFilter(
      userIP: userIP ?? this.userIP,
      viewedMods: viewedMods ?? this.viewedMods,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static bool needUpdateViewCount(String ip, String wikiModDataUUID) {
    UserViewCountFilter? _getUserViewCountFilter(String userIP) {
      try {
        return _filters.firstWhere(
          (f) => f.userIP == userIP,
        );
      } catch (e) {
        return null;
      }
    }

    void _add(UserViewCountFilter filter) {
      _filters.add(filter);
    }

    UserViewCountFilter? countFilter = _getUserViewCountFilter(ip);
    if (countFilter == null) {
      _add(UserViewCountFilter(
          userIP: ip,
          viewedMods: {wikiModDataUUID},
          createdAt: DateTime.now().toUtc()));
      return true;
    } else {
      if (!countFilter.isViewed(wikiModDataUUID)) {
        _add(countFilter.copyWith(
            viewedMods: countFilter.viewedMods..add(wikiModDataUUID)));
        return true;
      } else {
        return false;
      }
    }
  }

  static void clearUserViewCountFilter(DateTime time) {
    // Delete records from two hours ago
    _filters.removeWhere(
      (f) => f.createdAt.isBefore(time.subtract(Duration(hours: 2))),
    );
  }
}
