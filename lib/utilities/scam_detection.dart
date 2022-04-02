import 'package:rpmtw_server/data/phishing_link.dart';

class ScamDetection {
  static final RegExp _urlRegex = RegExp(
      r'(http|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?');

  static bool detection(String message) {
    if (message.contains('https://') || message.contains('http://')) {
      if (!_urlRegex.hasMatch(message)) return false;

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

        // Steam 官方域名
        'steampowered.com',
        'steamcommunity.com',

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

        bool phishing =
            !isWhitelisted && (isBlacklisted || isUnknownSuspiciousLink);

        if (phishing) {
          return true;
        }
      }

      return false;
    } else {
      return false;
    }
  }
}
