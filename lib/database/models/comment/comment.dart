import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/comment/comment_type.dart";
import "package:rpmtw_server/database/models/index_fields.dart";
import "package:rpmtw_server/database/models/model_field.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";

class Comment extends BaseModel {
  static const String collectionName = "comments";
  static const List<IndexField> indexFields = [
    IndexField("type", unique: false),
    IndexField("parentUUID", unique: false),
    IndexField("createdAt", unique: false),
    IndexField("updatedAt", unique: false),
    IndexField("replyCommentUUID", unique: false),
  ];

  /// Comment content in Markdown format.
  /// Can use @[userUUID] to tag others. (UUID will not be displayed in the UI, but the username)
  final String content;

  /// The type of the comment.
  final CommentType type;

  /// UUID of the user who sent this comment
  final String userUUID;

  /// If the type is [CommentType.translate] parent is the [SourceText]
  /// If the type is [CommentType.wiki] parent is the [MinecraftMod].
  final String parentUUID;

  /// The time when the comment was created.
  final DateTime createdAt;

  /// The time when the comment was last updated.
  final DateTime updatedAt;

  final bool isHidden;

  /// If the comment is a reply to another comment, this field will be set.
  final String? replyCommentUUID;

  Future<List<Comment>> getReplies() async {
    return Comment.list(
      type: type,
      parentUUID: uuid,
    );
  }

  const Comment({
    required String uuid,
    required this.content,
    required this.type,
    required this.userUUID,
    required this.parentUUID,
    required this.createdAt,
    required this.updatedAt,
    required this.isHidden,
    this.replyCommentUUID,
  }) : super(uuid: uuid);

  Comment copyWith({
    String? content,
    DateTime? updatedAt,
    bool? isHidden,
  }) {
    return Comment(
      uuid: uuid,
      content: content ?? this.content,
      type: type,
      userUUID: userUUID,
      parentUUID: parentUUID,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHidden: isHidden ?? this.isHidden,
      replyCommentUUID: replyCommentUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "content": content,
      "type": type.name,
      "userUUID": userUUID,
      "parentUUID": parentUUID,
      "createdAt": createdAt.millisecondsSinceEpoch,
      "updatedAt": updatedAt.millisecondsSinceEpoch,
      "isHidden": isHidden,
      "replyCommentUUID": replyCommentUUID,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      uuid: map["uuid"],
      content: map["content"],
      type: CommentType.values.byName(map["type"]),
      userUUID: map["userUUID"],
      parentUUID: map["parentUUID"],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map["createdAt"]),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map["updatedAt"]),
      isHidden: map["isHidden"],
      replyCommentUUID: map["replyCommentUUID"],
    );
  }

  static Future<Comment?> getByUUID(String uuid) async =>
      await DataBase.instance.getModelByUUID<Comment>(uuid);

  static Future<List<Comment>> list(
          {required CommentType type,
          String? parentUUID,
          String? replyCommentUUID,
          int? limit,
          int? skip}) =>
      DataBase.instance.getModelsByField([
        ModelField("type", type.name),
        ModelField("isHidden", false),
        if (parentUUID != null) ModelField("parentUUID", parentUUID),
        if (replyCommentUUID != null)
          ModelField("replyCommentUUID", replyCommentUUID),
      ], limit: limit, skip: skip);
}
