import 'package:intl/locale.dart';
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/auth/user.dart";
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/routes/base_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import 'package:rpmtw_server/utilities/data.dart';
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
    }, requiredFields: ["translationUUID", "type"]);

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
    }, requiredFields: ["uuid", "type"]);

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
    }, requiredFields: ["uuid"]);

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

      return APIResponse.success(data: translations.map((e) => e.outputMap()).toList());
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
    }, requiredFields: ["sourceUUID", "language", "content"]);

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
    }, requiredFields: ["uuid"]);
  }
}
