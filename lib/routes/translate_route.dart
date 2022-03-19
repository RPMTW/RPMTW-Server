import "package:intl/locale.dart";
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/auth/user.dart";
import 'package:rpmtw_server/database/models/auth/user_role.dart';
import 'package:rpmtw_server/database/models/auth_route.dart';
import "package:rpmtw_server/database/models/minecraft/minecraft_version.dart";
import "package:rpmtw_server/database/models/translate/mod_source_info.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/routes/base_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/data.dart";
import "package:rpmtw_server/utilities/extension.dart";

class TranslateRoute extends APIRoute {
  @override
  String get routeName => "translate";

  @override
  void router(router) {
    /// List all translation votes by translation uuid
    router.getRoute("/vote", (req, data) async {
      final String translationUUID = data.fields["translationUUID"];
      final Translation? translation =
          await Translation.getByUUID(translationUUID);

      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      final List<TranslationVote> votes = await translation.votes;

      return APIResponse.success(
          data: votes.map((e) => e.outputMap()).toList());
    }, requiredFields: ["translationUUID"]);

    /// Add translation vote
    router.postRoute("/vote", (req, data) async {
      final User user = req.user!;

      final String translationUUID = data.fields["translationUUID"]!;
      final TranslationVoteType type =
          TranslationVoteType.values.byName(data.fields["type"]!);

      final Translation? translation =
          await Translation.getByUUID(translationUUID);

      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      final List<TranslationVote> votes = await translation.votes;

      if (votes.any((vote) => vote.userUUID == user.uuid)) {
        return APIResponse.badRequest(message: "You have already voted");
      }

      final TranslationVote vote = TranslationVote(
          uuid: Uuid().v4(),
          type: type,
          translationUUID: translationUUID,
          userUUID: user.uuid);

      await vote.insert();
      return APIResponse.success(data: vote.outputMap());
    }, requiredFields: ["translationUUID", "type"], authConfig: AuthConfig());

    /// Edit translation vote
    router.patchRoute("/vote/<uuid>", (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields["uuid"]!;
      final TranslationVoteType type =
          TranslationVoteType.values.byName(data.fields["type"]!);

      TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.modelNotFound<TranslationVote>();
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.badRequest(message: "You can't edit this vote");
      }

      vote = vote.copyWith(type: type);

      await vote.update();
      return APIResponse.success(data: null);
    }, requiredFields: ["uuid", "type"], authConfig: AuthConfig());

    /// Cancel translation vote
    router.deleteRoute("/vote/<uuid>", (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields["uuid"]!;

      final TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.modelNotFound<TranslationVote>();
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.badRequest(message: "You can't cancel this vote");
      }

      await vote.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ["uuid"], authConfig: AuthConfig());

    /// Get translation by uuid
    router.getRoute("/translation/<uuid>", (req, data) async {
      final String uuid = data.fields["uuid"]!;

      final Translation? translation = await Translation.getByUUID(uuid);

      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      return APIResponse.success(data: translation.outputMap());
    }, requiredFields: ["uuid"]);

    /// List all translations by source text and target language
    router.getRoute("/translation", (req, data) async {
      final SourceText? sourceText =
          await SourceText.getByUUID(data.fields["sourceUUID"]!);
      final Locale language = Locale.parse(data.fields["language"]!);

      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      final List<Translation> translations =
          await sourceText.getTranslations(language: language);

      return APIResponse.success(
          data: translations.map((e) => e.outputMap()).toList());
    }, requiredFields: ["sourceUUID", "language"]);

    /// Add translation
    router.postRoute("/translation", (req, data) async {
      final User user = req.user!;

      final SourceText? sourceText =
          await SourceText.getByUUID(data.fields["sourceUUID"]!);
      final Locale language = Locale.parse(data.fields["language"]!);
      final String content = data.fields["content"]!;

      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      if (content.isEmpty || content.trim().isEmpty) {
        return APIResponse.badRequest(
            message: "Translation content can't be empty");
      }

      if (!Data.rpmTranslatorSupportedLanguage.contains(language)) {
        return APIResponse.badRequest(
            message: "RPMTranslator doesn't support this language");
      }

      final Translation translation = Translation(
          uuid: Uuid().v4(),
          sourceUUID: sourceText.uuid,
          language: language,
          content: content,
          translatorUUID: user.uuid);

      await translation.insert();
      return APIResponse.success(data: translation.outputMap());
    },
        requiredFields: ["sourceUUID", "language", "content"],
        authConfig: AuthConfig());

    /// Delete translation by uuid
    router.deleteRoute("/translation/<uuid>", (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields["uuid"]!;

      final Translation? translation = await Translation.getByUUID(uuid);
      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      if (translation.translatorUUID != user.uuid) {
        return APIResponse.badRequest(
            message: "You can't delete this translation");
      }

      await translation.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ["uuid"], authConfig: AuthConfig());

    /// Get source text by uuid
    router.getRoute("/source-text/<uuid>", (req, data) async {
      final String uuid = data.fields["uuid"]!;

      final SourceText? sourceText = await SourceText.getByUUID(uuid);

      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      return APIResponse.success(data: sourceText.outputMap());
    }, requiredFields: ["uuid"]);

    /// List all source text by source or key
    router.getRoute("/source-text", (req, data) async {
      Map<String, dynamic> fields = data.fields;
      int limit =
          fields["limit"] != null ? int.tryParse(fields["limit"]) ?? 50 : 50;
      int? skip = fields["skip"] != null ? int.tryParse(fields["skip"]) : null;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final List<SourceText> sourceTexts = await SourceText.search(
          source: data.fields["source"],
          key: data.fields["key"],
          limit: limit,
          skip: skip);

      return APIResponse.success(data: {
        "sources": sourceTexts.map((e) => e.outputMap()).toList(),
        "limit": limit,
        "skip": skip,
      });
    });

    /// Add source text
    router.postRoute("/source-text", (req, data) async {
      final String source = data.fields["source"]!;
      final List<MinecraftVersion> gameVersions =
          await MinecraftVersion.getByIDs(
              data.fields["gameVersions"]!.cast<String>());
      final String key = data.fields["key"]!;
      final SourceTextType type =
          SourceTextType.values.byName(data.fields["type"]!);

      if (source.isEmpty || source.trim().isEmpty) {
        return APIResponse.badRequest(message: "Source can't be empty");
      }

      if (gameVersions.isEmpty) {
        return APIResponse.badRequest(message: "Game versions can't be empty");
      }

      if (key.isEmpty || key.trim().isEmpty) {
        return APIResponse.badRequest(message: "Key can't be empty");
      }

      final SourceText sourceText = SourceText(
          uuid: Uuid().v4(),
          source: source,
          gameVersions: gameVersions,
          key: key,
          type: type);

      await sourceText.insert();
      return APIResponse.success(data: sourceText.outputMap());
    },
        requiredFields: ["source", "gameVersions", "key", "type"],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Edit source text by uuid
    router.patchRoute("/source-text/<uuid>", (req, data) async {
      final String uuid = data.fields["uuid"]!;

      SourceText? sourceText = await SourceText.getByUUID(uuid);
      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      final String? source = data.fields["source"];
      final List<MinecraftVersion>? gameVersions =
          data.fields["gameVersions"] != null
              ? await MinecraftVersion.getByIDs(
                  data.fields["gameVersions"]!.cast<String>())
              : null;
      final String? key = data.fields["key"];
      final SourceTextType? type = data.fields["type"] != null
          ? SourceTextType.values.byName(data.fields["type"]!)
          : null;

      if (source != null && (source.isEmpty || source.trim().isEmpty)) {
        return APIResponse.badRequest(message: "Source can't be empty");
      }

      if (gameVersions != null && gameVersions.isEmpty) {
        return APIResponse.badRequest(message: "Game versions can't be empty");
      }

      if (key != null && (key.isEmpty || key.trim().isEmpty)) {
        return APIResponse.badRequest(message: "Key can't be empty");
      }

      if (source == null &&
          gameVersions == null &&
          key == null &&
          type == null) {
        return APIResponse.badRequest(
            message: "You need to provide at least one field to edit");
      }

      sourceText = sourceText.copyWith(
          source: source, gameVersions: gameVersions, key: key, type: type);

      await sourceText.update();
      return APIResponse.success(data: sourceText.outputMap());
    }, requiredFields: ["uuid"], authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Delete source text by uuid
    router.deleteRoute("/source-text/<uuid>", (req, data) async {
      final String uuid = data.fields["uuid"]!;

      SourceText? sourceText = await SourceText.getByUUID(uuid);
      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      /// Delete all dependencies of this source text
      if (sourceText.type == SourceTextType.patchouli) {
        ModSourceInfo? info = await DataBase.instance
            .getModelByField<ModSourceInfo>("patchouliAddons", sourceText.uuid);

        if (info != null && info.patchouliAddons != null) {
          info = info.copyWith(
              patchouliAddons: List.from(info.patchouliAddons!)
                ..remove(sourceText.uuid));
          await info.update();
        }
      } else {
        SourceFile? file = await DataBase.instance
            .getModelByField<SourceFile>("sources", sourceText.uuid);

        if (file != null) {
          file = file.copyWith(
              sources: List.from(file.sources)..remove(sourceText.uuid));
          await file.update();
        }
      }

      await sourceText.delete();

      return APIResponse.success(data: null);
    },
        requiredFields: ["uuid"],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    // /// Get source file by uuid
    // router.getRoute("/source-file/<uuid>", (req, data) async {
    //   final String uuid = data.fields["uuid"]!;

    //   final SourceFile? sourceFile = await SourceFile.getByUUID(uuid);

    //   if (sourceFile == null) {
    //     return APIResponse.modelNotFound<SourceFile>();
    //   }

    //   return APIResponse.success(data: sourceFile.outputMap());
    // }, requiredFields: ["uuid"]);

    // /// Get mod source info by uuid
    // router.getRoute("/mod-source-info/<uuid>", (req, data) async {
    //   final String uuid = data.fields["uuid"]!;

    //   final ModSourceInfo? modSourceInfo = await ModSourceInfo.getByUUID(uuid);

    //   if (modSourceInfo == null) {
    //     return APIResponse.modelNotFound<ModSourceInfo>();
    //   }

    //   return APIResponse.success(data: modSourceInfo.outputMap());
    // }, requiredFields: ["uuid"]);
  }
}
