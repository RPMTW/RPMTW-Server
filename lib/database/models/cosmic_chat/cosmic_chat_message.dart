import "dart:io";

import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/index_fields.dart";

class CosmicChatMessage extends DBModel {
  static const String collectionName = "cosmic_chat_message";
  static const List<IndexField> indexFields = [
    IndexField("sentAt", unique: false),
    IndexField("ip", unique: false),
  ];

  /// Username (not a nickname, may be the username of RPMTW account, Minecraft account or Discord account)
  final String username;

  /// message content
  final String message;

  final String? nickname;

  final String avatarUrl;

  /// message sent time (UTC+0)
  final DateTime sentAt;

  /// IP address of the sender of the message (not public)
  final InternetAddress ip;

  final CosmicChatUserType userType;

  /// Reply message uuid
  final String? replyMessageUUID;

  const CosmicChatMessage({
    required String uuid,
    required this.username,
    required this.message,
    this.nickname,
    required this.avatarUrl,
    required this.sentAt,
    required this.ip,
    required this.userType,
    this.replyMessageUUID,
  }) : super(uuid: uuid);

  CosmicChatMessage copyWith({
    String? username,
    String? message,
    String? nickname,
    String? avatarUrl,
    DateTime? sentAt,
    InternetAddress? ip,
    CosmicChatUserType? userType,
    String? replyMessageUUID,
  }) {
    return CosmicChatMessage(
      uuid: uuid,
      username: username ?? this.username,
      message: message ?? this.message,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sentAt: sentAt ?? this.sentAt,
      ip: ip ?? this.ip,
      userType: userType ?? this.userType,
      replyMessageUUID: replyMessageUUID ?? this.replyMessageUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "username": username,
      "message": message,
      "nickname": nickname,
      "avatarUrl": avatarUrl,
      "sentAt": sentAt.millisecondsSinceEpoch,
      "ip": ip.address,
      "userType": userType.name,
      "replyMessageUUID": replyMessageUUID,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      "uuid": uuid,
      "username": username,
      "message": message,
      "nickname": nickname,
      "avatarUrl": avatarUrl,
      "sentAt": sentAt.millisecondsSinceEpoch,
      "userType": userType.name,
      "replyMessageUUID": replyMessageUUID,
    };
  }

  factory CosmicChatMessage.fromMap(Map<String, dynamic> map) {
    return CosmicChatMessage(
      uuid: map["uuid"],
      username: map["username"],
      message: map["message"],
      nickname: map["nickname"],
      avatarUrl: map["avatarUrl"],
      sentAt: DateTime.fromMillisecondsSinceEpoch(map["sentAt"]),
      ip: InternetAddress(map["ip"]),
      userType: CosmicChatUserType.values.byName(map["userType"]),
      replyMessageUUID: map["replyMessageUUID"],
    );
  }

  static Future<CosmicChatMessage?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<CosmicChatMessage>(uuid);
}

enum CosmicChatUserType {
  /// RPMTW account
  rpmtw,

  /// Minecraft account
  minecraft,

  /// Discord account
  discord,
}
