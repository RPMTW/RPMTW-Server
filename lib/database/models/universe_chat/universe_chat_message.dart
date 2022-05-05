import 'dart:io';

import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';

class UniverseChatMessage extends DBModel {
  static const String collectionName = 'universe_chat_message';
  static const List<IndexField> indexFields = [
    IndexField('sentAt', unique: false),
    IndexField('ip', unique: false),
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

  final UniverseChatUserType userType;

  /// Reply message uuid
  final String? replyMessageUUID;

  const UniverseChatMessage({
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

  UniverseChatMessage copyWith({
    String? username,
    String? message,
    String? nickname,
    String? avatarUrl,
    DateTime? sentAt,
    InternetAddress? ip,
    UniverseChatUserType? userType,
    String? replyMessageUUID,
  }) {
    return UniverseChatMessage(
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
      'uuid': uuid,
      'username': username,
      'message': message,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'ip': ip.address,
      'userType': userType.name,
      'replyMessageUUID': replyMessageUUID,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      'uuid': uuid,
      'username': username,
      'message': message,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'sentAt': sentAt.millisecondsSinceEpoch,
      'userType': userType.name,
      'replyMessageUUID': replyMessageUUID,
    };
  }

  factory UniverseChatMessage.fromMap(Map<String, dynamic> map) {
    return UniverseChatMessage(
      uuid: map['uuid'],
      username: map['username'],
      message: map['message'],
      nickname: map['nickname'],
      avatarUrl: map['avatarUrl'],
      sentAt: DateTime.fromMillisecondsSinceEpoch(map['sentAt'], isUtc: true),
      ip: InternetAddress(map['ip']),
      userType: UniverseChatUserType.values.byName(map['userType']),
      replyMessageUUID: map['replyMessageUUID'],
    );
  }

  static Future<UniverseChatMessage?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<UniverseChatMessage>(uuid);
}

enum UniverseChatUserType {
  /// RPMTW account
  rpmtw,

  /// Minecraft account
  minecraft,

  /// Discord account
  discord,
}
