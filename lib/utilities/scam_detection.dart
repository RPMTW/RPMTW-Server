import 'package:rpmtw_server/data/phishing_link.dart';

final String _pattern =
    r'(http|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';

final RegExp _urlRegex = RegExp(_pattern);

class ScamDetection {
  static Future<void> detection(String message,
      {required Future<void> Function(String message, String url) inBlackList,
      required Future<void> Function(String message, String url)
          unknownSuspiciousDomain}) async {
    if (message.contains('https://') || message.contains('http://')) {
      if (!_urlRegex.hasMatch(message)) return;

      /// 訊息內容包含網址

      List<RegExpMatch> matchList = _urlRegex.allMatches(message).toList();

      List<String> domainWhitelist = [
        // DC 官方域名
        'discord.gift',
        'discord.gg',
        'discord.com',
        'discordapp.com',
        'discordapp.net',
        'discordstatus.com',
        'discord.media',

        /// 社群域名
        'discordresources.com',
        'discord.wiki',
        'discordservers.tw',

        // Steam 官方域名
        'steampowered.com',
        'steamcommunity.com',
        'steamdeck.com',

        // 在 Alexa 名列前茅的 .gift 和 .gifts 域名
        'crediter.gift',
        'packedwithpurpose.gifts',
        '123movies.gift',
        'admiralwin.gift',
        'gol.gift',
        'newhome.gifts'
      ];

      for (RegExpMatch match in matchList) {
        String matchString = message.substring(match.start, match.end);
        Uri? uri = Uri.tryParse(matchString);
        if (uri == null) continue;
        List<String> domainList = uri.host.split('.');
        List<String> keywords = ['disc', 'steam', 'gift'];

        String domain1 = domainList.length >= 3 ? domainList[1] : domainList[0];
        String domain2 = domainList.length >= 3 ? domainList[2] : domainList[1];
        String domain = '$domain1.$domain2';

        bool isWhitelisted = domainWhitelist.contains(domain);
        bool isBlacklisted = phishingLink.contains(domain);
        bool isUnknownSuspiciousLink =
            keywords.any((e) => domain1.contains(e) || domain2.contains(e));

        if (!isWhitelisted) {
          if (isBlacklisted) {
            await inBlackList(message, matchString);
            break;
          } else if (isUnknownSuspiciousLink) {
            await unknownSuspiciousDomain(message, matchString);
            break;
          }
        }
      }
    }
  }

  static Future<bool> detectionWithBool(String message) async {
    bool phishing = false;
    void onPhishing() {
      phishing = true;
    }

    await ScamDetection.detection(message,
        inBlackList: (message, url) async => onPhishing(),
        unknownSuspiciousDomain: (message, url) async => onPhishing());

    return phishing;
  }
}
