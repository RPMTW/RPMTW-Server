import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/auth/user.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/routes/base_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
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
  }
}
