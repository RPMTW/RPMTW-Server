import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/translate/translation.dart';
import 'package:rpmtw_server/database/models/translate/translation_vote.dart';
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:shelf_router/shelf_router.dart';

class TranslateRoute implements APIRoute {
  @override
  Router get router {
    final Router router = Router();

    router.getRoute("/vote", (req, data) async {
      final String translationUUID = data.fields["translationUUID"];

      throw UnimplementedError();
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
        return APIResponse.notFound("Translation not found");
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

    /// Cancel translation vote
    router.deleteRoute("/vote", (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields["uuid"]!;

      TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.notFound("Translation vote not found");
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.badRequest(message: "You can't cancel this vote");
      }

      await vote.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ["uuid"]);

    return router;
  }
}
