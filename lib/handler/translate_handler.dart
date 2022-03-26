import "dart:convert";

import "package:crypto/crypto.dart";
import "package:intl/locale.dart";
import "package:json5/json5.dart";
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_version.dart";
import "package:rpmtw_server/database/models/translate/patchouli_file_info.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/utilities/extension.dart";

class TranslateHandler {
  static final List<Locale> supportedLanguage = [
    // Traditional Chinese
    Locale.fromSubtags(languageCode: "zh", countryCode: "TW"),
    // Simplified Chinese
    Locale.fromSubtags(languageCode: "zh", countryCode: "CN"),
  ];

  static final List<String> supportedVersion = [
    "1.12",
    "1.16",
    "1.17",
    "1.18",
    // "1.19"
  ];

  /// https://github.com/VazkiiMods/Patchouli/blob/7d61bb287ea1e87a757bb14bff95e0de1c70688f/Common/src/main/java/vazkii/patchouli/client/book/BookEntry.java#L33
  /// https://github.com/VazkiiMods/Patchouli/blob/7d61bb287ea1e87a757bb14bff95e0de1c70688f/Common/src/main/java/vazkii/patchouli/client/book/BookCategory.java#L20
  static final List<String> _patchouliSkipFields = [
    "category",
    "flag",
    "icon",
    "read_by_default",
    "priority",
    "secret",
    "advancement",
    "turnin",
    "sortnum",
    "entry_color",
    "extra_recipe_mappings",
    "parent"
  ];

  /// Minecraft lang converted to json format, modified and ported by https://gist.github.com/ChAoSUnItY/31c147efd2391b653b8cc12da9699b43
  /// Special thanks to 3X0DUS - ChAoS#6969 for writing this function
  static Map<String, String> langToJson(String source) {
    Map<String, String> map = {};

    String? lastKey;

    for (String line in LineSplitter().convert(source)) {
      if (line.startsWith("#") ||
          line.startsWith("//") ||
          line.startsWith("!")) {
        continue;
      }
      if (line.contains("=")) {
        if (line.split("=").length == 2) {
          List<String> kv = line.split("=");
          lastKey = kv[0];

          map[kv[0]] = kv[1].trimLeft();
        } else {
          if (lastKey == null) continue;
          map[lastKey] = "${map[lastKey]}\n$line";
        }
      } else if (!line.contains("=")) {
        if (lastKey == null) continue;
        if (line == "") continue;

        map[lastKey] = "${map[lastKey]}\n$line";
      }
    }
    return map;
  }

  static List<SourceText> handleFile(String string, SourceFileType type,
      List<MinecraftVersion> gameVersions, String filePath,
      {List<String>? patchouliI18nKeys}) {
    List<SourceText> texts = [];

    if (type == SourceFileType.gsonLang ||
        type == SourceFileType.minecraftLang) {
      late Map<String, String> lang;

      if (type == SourceFileType.gsonLang) {
        lang = JSON5.parse(string).cast<String, String>();
      } else if (type == SourceFileType.minecraftLang) {
        lang = langToJson(string);
      }

      lang.forEach((key, value) {
        if (value.isAllEmpty) return;

        texts.add(SourceText(
            uuid: Uuid().v4(),
            source: value,
            key: key,
            type: SourceTextType.general,
            gameVersions: gameVersions));
      });
    } else if (type == SourceFileType.patchouli) {
      assert(patchouliI18nKeys != null,
          "patchouliI18nKeys must be provided for patchouli files");

      Map<String, dynamic> json = JSON5.parse(string);
      PatchouliFileInfo info = PatchouliFileInfo.parse(filePath);

      json.forEach((key, value) {
        if (key == "pages" && value is List) {
          for (var page in value) {
            if (page is Map) {
              /// https://github.com/VazkiiMods/Patchouli/blob/7d61bb287ea1e87a757bb14bff95e0de1c70688f/Common/src/main/java/vazkii/patchouli/client/book/ClientBookRegistry.java#L101

              String? type = page["type"];

              void _addSource(dynamic source) {
                if (source is String &&
                    source.isNotEmpty &&
                    !patchouliI18nKeys!.contains(source)) {
                  int index = value.indexOf(page);

                  texts.add(SourceText(
                      uuid: Uuid().v4(),
                      source: source,
                      key:
                          "patchouli.${info.namespace}.${info.bookName}.content.${info.fileFolder}.${info.fileName}.pages.$index.text",
                      type: SourceTextType.patchouli,
                      gameVersions: gameVersions));
                }
              }

              if (type != null) {
                _addSource(page["title"]);
                _addSource(page["text"]);
              }
            }
          }
        } else {
          bool hasSource = value is String &&
              !patchouliI18nKeys!.contains(value) &&
              !_patchouliSkipFields.contains(key);

          if (hasSource) {
            texts.add(SourceText(
                uuid: Uuid().v4(),
                source: value,
                key:
                    "patchouli.${info.namespace}.${info.bookName}.content.${info.fileFolder}.${info.fileName}.$key",
                type: SourceTextType.patchouli,
                gameVersions: gameVersions));
          }
        }
      });
    } else if (type == SourceFileType.plainText) {
      List<String> lines =
          LineSplitter().convert(string).where((l) => l.isAllEmpty).toList();

      for (String line in lines) {
        texts.add(SourceText(
            uuid: Uuid().v4(),
            source: line,
            key: md5.convert(utf8.encode(line)).toString(),
            type: SourceTextType.plainText,
            gameVersions: gameVersions));
      }
    }

    return texts.toSet().toList();
  }

  static Future<int> getVoteResult(Translation translation) async {
    int result = 0;
    List<TranslationVote> votes =
        await TranslationVote.getAllByTranslationUUID(translation.uuid);
    for (TranslationVote vote in votes) {
      if (vote.isUpVote) {
        result++;
      } else if (vote.isDownVote) {
        result--;
      }
    }

    return result;
  }

  static Future<Translation?> getBestTranslation(
      SourceText text, Locale language) async {
    List<Translation> translations =
        await text.getTranslations(language: language);

    Map<String, int> voteResults = {};
    for (Translation translation in translations) {
      voteResults[translation.uuid] = await getVoteResult(translation);
    }

    translations
        .sort((a, b) => voteResults[a.uuid]!.compareTo(voteResults[b.uuid]!));

    if (translations.isEmpty) return null;
    return translations.first;
  }
}