import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart';
import 'package:socket_io/socket_io.dart';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/utilities/data.dart';

class CosmicChatHandler {
  static late final Server _io;

  static Server get io => _io;

  void init() {
    /// 2087 is cloudflare supported proxy https port
    int port = int.parse(env['COSMIC_CHAT_PORT'] ?? '2087');

    _io = Server(server: port);

    final InternetAddress ip = InternetAddress.anyIPv4;

    loggerNoStack
        .i('Cosmic Chat Server listening on port http://${ip.host}:$port');

    try {
      start(io);
    } catch (e) {
      loggerNoStack.e('Cosmic Chat Server error: $e');
    }
  }

  void start(Server io) {
    io.on('connection', (client) async {
      if (client is Socket) {
        String? token = client.handshake?['auth']?['rpmtw_auth_token'];
        String? minecraftUUID = client.handshake?['auth']?['minecraft_uuid'];
        String? minecraftUsername;
        User? user;
        if (token != null) {
          try {
            user = await User.getByToken(token);
          } catch (e) {
            user = null;
          }
        }

        bool minecraftUUIDValid = false;

        if (minecraftUUID != null) {
          /// 驗證 minecraft 帳號是否存在
          Response response = await get(Uri.parse(
              "https://sessionserver.mojang.com/session/minecraft/profile/$minecraftUUID"));
          if (response.statusCode == 200) {
            Map data = json.decode(response.body);
            minecraftUUIDValid = true;
            minecraftUsername = data['name'];
          }
        }

        bool isAuthenticated =
            user != null || (minecraftUUIDValid && minecraftUsername != null);

        if (isAuthenticated) {
          client.on('clientMessage', (_data) {
            try {
              Map data = json.decode(_data.toString());
              String? message = data['message'];
              bool isValidMessage = isAuthenticated && message != null;

              if (isValidMessage) {
                String username = user?.username ?? minecraftUsername!;

                if (user?.uuid == "07dfced6-7d41-4660-b2b4-25ba1319b067") {
                  username = "RPMTW 維護者兼創辦人";
                }

                CosmicChatMessage msg = CosmicChatMessage(
                    username: username,
                    message: message,
                    userUUID: user?.uuid,
                    minecraftUUID: minecraftUUID,
                    nickname: data['nickname']);

                client.emit('serverMessage', msg.toMap());
              }
            } catch (e) {
              // ignore
            }
          });
        } else {
          client.emit('serverError', 'Unauthorized');
        }
      }
    });
  }
}

/// 宇宙通訊的訊息
class CosmicChatMessage {
  /// 使用者名稱 (非暱稱，可能是 RPMTW 帳號或 Minecraft 帳號的使用者名稱)
  final String username;

  /// 訊息內容
  final String message;

  /// 暱稱
  final String? nickname;

  /// 發送訊息的使用者 ID
  final String? userUUID;

  /// Minecraft 帳號 UUID
  final String? minecraftUUID;

  const CosmicChatMessage({
    required this.username,
    required this.message,
    this.nickname,
    this.userUUID,
    this.minecraftUUID,
  });

  CosmicChatMessage copyWith({
    String? username,
    String? message,
    String? nickname,
    String? userUUID,
    String? minecraftUUID,
  }) {
    return CosmicChatMessage(
      username: username ?? this.username,
      message: message ?? this.message,
      nickname: nickname ?? this.nickname,
      userUUID: userUUID ?? this.userUUID,
      minecraftUUID: minecraftUUID ?? this.minecraftUUID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'message': message,
      'nickname': nickname,
      'userUUID': userUUID,
      'minecraftUUID': minecraftUUID,
    };
  }

  factory CosmicChatMessage.fromMap(Map<String, dynamic> map) {
    return CosmicChatMessage(
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      nickname: map['nickname'],
      userUUID: map['userUUID'],
      minecraftUUID: map['minecraftUUID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CosmicChatMessage.fromJson(String source) =>
      CosmicChatMessage.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CosmicChatMessage(username: $username, message: $message, nickname: $nickname, userUUID: $userUUID, minecraftUUID: $minecraftUUID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CosmicChatMessage &&
        other.username == username &&
        other.message == message &&
        other.nickname == nickname &&
        other.userUUID == userUUID &&
        other.minecraftUUID == minecraftUUID;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        message.hashCode ^
        nickname.hashCode ^
        userUUID.hashCode ^
        minecraftUUID.hashCode;
  }
}
