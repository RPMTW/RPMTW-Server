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
        String? token = client.handshake?['headers']?['rpmtw_auth_token']?[0];

        String? minecraftUUID =
            client.handshake?['headers']?['minecraft_uuid']?[0];
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
    print("test");

              if (isValidMessage) {
                String username = user?.username ?? minecraftUsername!;
                String? userUUID = user?.uuid;

                if (user != null &&
                    user.uuid == "07dfced6-7d41-4660-b2b4-25ba1319b067") {
                  username = "RPMTW 維護者兼創辦人";
                }

                late String avatar;

                if (userUUID != null) {
                  avatar =
                      "https://api.rpmtw.com:2096/storage/$userUUID/download";
                } else if (minecraftUUID != null) {
                  avatar = "https://crafthead.net/avatar/$minecraftUUID.png";
                }

                CosmicChatMessage msg = CosmicChatMessage(
                    username: username,
                    message: message,
                    nickname: data['nickname'],
                    avatarUrl: avatar);
                sendMessage(client, msg);
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

  void sendMessage(Socket client, CosmicChatMessage msg) {
    client.emit('serverMessage', msg.toJson());
  }
}

/// 宇宙通訊的訊息
class CosmicChatMessage {
  /// 使用者名稱 (非暱稱，可能是 RPMTW 帳號、Minecraft 帳號或 Discord 帳號的使用者名稱)
  final String username;

  /// 訊息內容
  final String message;

  /// 暱稱
  final String? nickname;

  final String avatarUrl;

  const CosmicChatMessage({
    required this.username,
    required this.message,
    this.nickname,
    required this.avatarUrl,
  });

  CosmicChatMessage copyWith({
    String? username,
    String? message,
    String? nickname,
    String? avatarUrl,
  }) {
    return CosmicChatMessage(
      username: username ?? this.username,
      message: message ?? this.message,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'message': message,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
    };
  }

  factory CosmicChatMessage.fromMap(Map<String, dynamic> map) {
    return CosmicChatMessage(
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      nickname: map['nickname'],
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CosmicChatMessage.fromJson(String source) =>
      CosmicChatMessage.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CosmicChatMessage(username: $username, message: $message, nickname: $nickname, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CosmicChatMessage &&
        other.username == username &&
        other.message == message &&
        other.nickname == nickname &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        message.hashCode ^
        nickname.hashCode ^
        avatarUrl.hashCode;
  }
}
