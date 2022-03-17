import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/translate/translation.dart';
import 'package:rpmtw_server/database/models/translate/translation_vote.dart';
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class TranslateRoute implements APIRoute {
  @override
  Router get router {
    final Router router = Router();

    /// Add translation vote
    router.postRoute("/vote", (Request req) async {
      final Map<String, dynamic> data = await req.data;
      final bool validateFields =
          Utility.validateRequiredFields(data, ["translationUUID", "type"]);
      final User user = req.user!;

      if (!validateFields) {
        return APIResponse.missingRequiredFields();
      }

      final String translationUUID = data["translationUUID"]!;
      final TranslationVoteType type =
          TranslationVoteType.values.byName(data["type"]!);

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
    });

    /// Cancel translation vote
    router.deleteRoute("/vote", (Request req) async {
      final Map<String, dynamic> data = await req.data;
      final bool validateFields =
          Utility.validateRequiredFields(data, ["uuid"]);
      final User user = req.user!;

      if (!validateFields) {
        return APIResponse.missingRequiredFields();
      }

      final String uuid = data["uuid"]!;

      TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.notFound("Translation vote not found");
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.badRequest(message: "You can't cancel this vote");
      }

      await vote.delete();

      return APIResponse.success(data: null);
    });

    return router;
  }
}
