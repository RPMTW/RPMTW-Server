import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/auth_route.dart';
import 'package:rpmtw_server/database/models/comment/comment.dart';
import 'package:rpmtw_server/database/models/comment/comment_type.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import 'package:rpmtw_server/routes/api_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/request_extension.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class CommentRoute extends APIRoute {
  @override
  String get routeName => 'comment';

  @override
  void router(Router router) {
    /// Get a comment by uuid.
    router.getRoute('/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid'];

      final Comment? comment = await Comment.getByUUID(uuid);

      if (comment == null) {
        return APIResponse.modelNotFound<Comment>();
      }

      return APIResponse.success(data: comment.outputMap());
    }, requiredFields: ['uuid']);

    /// List all comments by type and parent or reply comment.
    router.getRoute('/', (req, data) async {
      Map<String, dynamic> fields = data.fields;

      final CommentType type = CommentType.values.byName(fields['type']!);
      final String parentUUID = fields['parentUUID'];
      final String? replyCommentUUID = fields['replyCommentUUID'];

      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      final List<Comment> comments = await Comment.list(
          type: type,
          parentUUID: parentUUID,
          replyCommentUUID: replyCommentUUID,
          limit: limit,
          skip: skip);

      return APIResponse.success(
          data: comments.map((comment) => comment.outputMap()).toList());
    }, requiredFields: ['type', 'parentUUID'], checker: _checkParentUUID);

    /// Add a comment.
    router.postRoute('/', (req, data) async {
      final CommentType type = CommentType.values.byName(data.fields['type']!);
      final String parentUUID = data.fields['parentUUID']!;
      final String content = data.fields['content']!;

      if (content.isAllEmpty) {
        return APIResponse.fieldEmpty('content');
      }

      final Comment comment = Comment(
          uuid: Uuid().v4(),
          content: content,
          type: type,
          userUUID: req.user!.uuid,
          parentUUID: parentUUID,
          createdAt: Utility.getUTCTime(),
          updatedAt: Utility.getUTCTime(),
          isHidden: false);

      await comment.insert();

      return APIResponse.success(data: comment.outputMap());
    },
        requiredFields: ['content', 'type', 'parentUUID'],
        authConfig: AuthConfig(),
        checker: _checkParentUUID);

    /// Edit a comment.
    router.patchRoute('/<uuid>', (req, data) async {
      final User user = req.user!;
      final String uuid = data.fields['uuid'];
      final String content = data.fields['content']!;

      final Comment? comment = await Comment.getByUUID(uuid);

      if (comment == null) {
        return APIResponse.modelNotFound<Comment>();
      }

      if (comment.userUUID != user.uuid) {
        return APIResponse.forbidden(message: 'You cannot edit this comment.');
      }

      if (content.isAllEmpty) {
        return APIResponse.fieldEmpty('content');
      }

      final Comment newComment =
          comment.copyWith(content: content, updatedAt: Utility.getUTCTime());
      await newComment.update();

      return APIResponse.success(data: newComment.outputMap());
    }, requiredFields: ['uuid', 'content'], authConfig: AuthConfig());

    /// Delete a comment.
    router.deleteRoute('/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid'];

      final Comment? comment = await Comment.getByUUID(uuid);

      if (comment == null) {
        return APIResponse.modelNotFound<Comment>();
      }

      if (comment.userUUID != req.user!.uuid) {
        return APIResponse.forbidden(
            message: 'You cannot delete this comment.');
      }

      /// Not really delete comments from the database, only hide.
      Future<void> hide(Comment comment) async {
        await comment
            .copyWith(isHidden: true, updatedAt: Utility.getUTCTime())
            .update();
      }

      final List<Comment> replies = await comment.getReplies();
      for (Comment reply in replies) {
        await hide(reply);
      }

      await hide(comment);

      return APIResponse.success(data: null);
    }, requiredFields: ['uuid'], authConfig: AuthConfig());

    /// Reply to a comment.
    router.postRoute('/<uuid>/reply', (req, data) async {
      final String uuid = data.fields['uuid']!;
      final String content = data.fields['content']!;

      final Comment? comment = await Comment.getByUUID(uuid);

      if (comment == null) {
        return APIResponse.modelNotFound<Comment>();
      }

      if (content.isAllEmpty) {
        return APIResponse.fieldEmpty('content');
      }

      final Comment reply = Comment(
          uuid: Uuid().v4(),
          content: content,
          type: comment.type,
          userUUID: req.user!.uuid,
          parentUUID: comment.parentUUID,
          createdAt: Utility.getUTCTime(),
          updatedAt: Utility.getUTCTime(),
          isHidden: comment.isHidden,
          replyCommentUUID: comment.uuid);

      await reply.insert();

      return APIResponse.success(data: reply.outputMap());
    }, requiredFields: ['uuid', 'content'], authConfig: AuthConfig());
  }

  Future<Response?> _checkParentUUID(Request req, RouteData data) async {
    /// Check the parent uuid exists.
    Future<Response?> check(CommentType type, String parentUUID) async {
      if (type == CommentType.translate) {
        SourceText? sourceText = await SourceText.getByUUID(parentUUID);
        if (sourceText == null) {
          return APIResponse.modelNotFound<SourceText>();
        }
      } else if (type == CommentType.wiki) {
        MinecraftMod? mod = await MinecraftMod.getByUUID(parentUUID);
        if (mod == null) {
          return APIResponse.modelNotFound<MinecraftMod>();
        }
      }

      return null;
    }

    final CommentType type = CommentType.values.byName(data.fields['type']!);
    final String parentUUID = data.fields['parentUUID']!;

    return await check(type, parentUUID);
  }
}
