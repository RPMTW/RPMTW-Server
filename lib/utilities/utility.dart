import "package:pub_semver/pub_semver.dart";

class Utility {
  /// 驗證請求資料完整性，如果不完整則為回傳 false，完整則回傳 true
  /// [data] 請求資料
  /// [fields] 必填欄位
  static bool validateRequiredFields(
      Map<String, dynamic> data, List<String> fields) {
    for (String field in fields) {
      if (data[field] == null) {
        return false;
      }
    }
    return true;
  }

  /// https://github.com/RPMTW/RPMLauncher/blob/fa2523e3b006cd5e3dfca315be3c61debf48b40b/lib/Utility/Utility.dart#L381
  static Version parseMCComparableVersion(String sourceVersion) {
    Version _comparableVersion;
    try {
      try {
        _comparableVersion = Version.parse(sourceVersion);
      } catch (e) {
        _comparableVersion = Version.parse("$sourceVersion.0");
      }
    } catch (e) {
      String? _preVersion() {
        int pos = sourceVersion.indexOf("-pre");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Pre-release ");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Pre-Release ");
        if (pos >= 0) return sourceVersion.substring(0, pos);

        pos = sourceVersion.indexOf(" Release Candidate ");
        if (pos >= 0) return sourceVersion.substring(0, pos);
        return null;
      }

      String? _str = _preVersion();
      if (_str != null) {
        try {
          return Version.parse(_str);
        } catch (e) {
          return Version.parse("$_str.0");
        }
      }

      /// 例如 21w44a
      RegExp _ = RegExp(r"(?:(?<yy>\d\d)w(?<ww>\d\d)[a-z])");
      if (_.hasMatch(sourceVersion)) {
        RegExpMatch match = _.allMatches(sourceVersion).toList().first;

        String praseRelease(int year, int week) {
          if (year == 22 && week >= 11) {
            return "1.19.0";
          } else if (year == 22 && week >= 3 && week <= 7) {
            return "1.18.2";
          } else if (year == 21 && week >= 37) {
            return "1.18.0";
          } else if (year == 21 && (week >= 3 && week <= 20)) {
            return "1.17.0";
          } else if (year == 20 && week >= 6) {
            return "1.16.0";
          } else if (year == 19 && week >= 34) {
            return "1.15.2";
          } else if (year == 18 && week >= 43 || year == 19 && week <= 14) {
            return "1.14.0";
          } else if (year == 18 && week >= 30 && week <= 33) {
            return "1.13.1";
          } else if (year == 17 && week >= 43 || year == 18 && week <= 22) {
            return "1.13.0";
          } else if (year == 17 && week == 31) {
            return "1.12.1";
          } else if (year == 17 && week >= 6 && week <= 18) {
            return "1.12.0";
          } else if (year == 16 && week == 50) {
            return "1.11.1";
          } else if (year == 16 && week >= 32 && week <= 44) {
            return "1.11.0";
          } else if (year == 16 && week >= 20 && week <= 21) {
            return "1.10.0";
          } else if (year == 16 && week >= 14 && week <= 15) {
            return "1.9.3";
          } else if (year == 15 && week >= 31 || year == 16 && week <= 7) {
            return "1.9.0";
          } else if (year == 14 && week >= 2 && week <= 34) {
            return "1.8.0";
          } else if (year == 13 && week >= 47 && week <= 49) {
            return "1.7.4";
          } else if (year == 13 && week >= 36 && week <= 43) {
            return "1.7.2";
          } else if (year == 13 && week >= 16 && week <= 26) {
            return "1.6.0";
          } else if (year == 13 && week >= 11 && week <= 12) {
            return "1.5.1";
          } else if (year == 13 && week >= 1 && week <= 10) {
            return "1.5.0";
          } else if (year == 12 && week >= 49 && week <= 50) {
            return "1.4.6";
          } else if (year == 12 && week >= 32 && week <= 42) {
            return "1.4.2";
          } else if (year == 12 && week >= 15 && week <= 30) {
            return "1.3.1";
          } else if (year == 12 && week >= 3 && week <= 8) {
            return "1.2.1";
          } else if (year == 11 && week >= 47 || year == 12 && week <= 1) {
            return "1.1.0";
          } else {
            return "1.18.0";
          }
        }

        int year = int.parse(match.group(1).toString()); //ex: 21
        int week = int.parse(match.group(2).toString()); //ex: 44

        _comparableVersion = Version.parse(praseRelease(year, week));
      } else {
        _comparableVersion = Version.none;
      }
    }

    return _comparableVersion;
  }
}
