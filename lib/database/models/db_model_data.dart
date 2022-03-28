import 'package:mongo_dart/mongo_dart.dart';
import "package:rpmtw_server/database/models/auth/auth_code_.dart";
import "package:rpmtw_server/database/models/auth/ban_info.dart";
import 'package:rpmtw_server/database/models/auth/user.dart';
import "package:rpmtw_server/database/models/comment/comment.dart";
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/database/models/translate/translation_export_cache.dart';
import "package:rpmtw_server/database/models/universe_chat/universe_chat_message.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart";
import "package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart";
import "package:rpmtw_server/database/models/translate/glossary.dart";
import "package:rpmtw_server/database/models/translate/mod_source_info.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";

class DBModelData {
  static List<String> collectionNameList = [
    User.collectionName,
    Storage.collectionName,
    AuthCode.collectionName,
    MinecraftMod.collectionName,
    BanInfo.collectionName,
    MinecraftVersionManifest.collectionName,
    WikiChangeLog.collectionName,
    UniverseChatMessage.collectionName,
    Translation.collectionName,
    TranslationVote.collectionName,
    SourceText.collectionName,
    ModSourceInfo.collectionName,
    SourceFile.collectionName,
    Glossary.collectionName,
    Comment.collectionName,
    TranslationExportCache.collectionName,
  ];

  static List<List<IndexField>> indexFields = [
    User.indexFields,
    Storage.indexFields,
    AuthCode.indexFields,
    MinecraftMod.indexFields,
    BanInfo.indexFields,
    MinecraftVersionManifest.indexFields,
    WikiChangeLog.indexFields,
    UniverseChatMessage.indexFields,
    Translation.indexFields,
    TranslationVote.indexFields,
    SourceText.indexFields,
    ModSourceInfo.indexFields,
    SourceFile.indexFields,
    Glossary.indexFields,
    Comment.indexFields,
    TranslationExportCache.indexFields,
  ];

  static Map<String, DbCollection> collectionMap(
      List<DbCollection> collections) {
    return {
      "User": collections[0],
      "Storage": collections[1],
      "AuthCode": collections[2],
      "MinecraftMod": collections[3],
      "BanInfo": collections[4],
      "MinecraftVersionManifest": collections[5],
      "WikiChangeLog": collections[6],
      "UniverseChatMessage": collections[7],
      "Translation": collections[8],
      "TranslationVote": collections[9],
      "SourceText": collections[10],
      "ModSourceInfo": collections[11],
      "SourceFile": collections[12],
      "Glossary": collections[13],
      "Comment": collections[14],
      "TranslationExportCache": collections[15],
    };
  }

  static Map<String, dynamic Function(Map<String, dynamic>)> fromMap = {
    "User": User.fromMap,
    "Storage": Storage.fromMap,
    "AuthCode": AuthCode.fromMap,
    "MinecraftMod": MinecraftMod.fromMap,
    "BanInfo": BanInfo.fromMap,
    "MinecraftVersionManifest": MinecraftVersionManifest.fromMap,
    "WikiChangeLog": WikiChangeLog.fromMap,
    "UniverseChatMessage": UniverseChatMessage.fromMap,
    "Translation": Translation.fromMap,
    "TranslationVote": TranslationVote.fromMap,
    "SourceText": SourceText.fromMap,
    "ModSourceInfo": ModSourceInfo.fromMap,
    "SourceFile": SourceFile.fromMap,
    "Glossary": Glossary.fromMap,
    "Comment": Comment.fromMap,
    "TranslationExportCache": TranslationExportCache.fromMap,
  }.cast<String, dynamic Function(Map<String, dynamic>)>();
}
