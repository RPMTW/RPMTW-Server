import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io/socket_io.dart';

import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/utilities/data.dart';

class CosmicChatHandler {
  static late final Server _io;

  static Server get io => _io;

  Future<void> init() async {
    /// 2087 is cloudflare supported proxy https port
    int port = int.parse(env['COSMIC_CHAT_PORT'] ?? '2087');
    _io = Server();
    final InternetAddress ip = InternetAddress.anyIPv4;

    try {
      eventHandler(io);
      await io.listen(port);
      loggerNoStack
          .i('Cosmic Chat Server listening on port http://${ip.host}:$port');
    } catch (e) {
      loggerNoStack.e('Cosmic Chat Server error: $e');
    }
  }

  void eventHandler(Server io) {
    io.on('connection', (client) {
      if (client is Socket) {
        List<bool> initCheckList = List<bool>.generate(2, (index) => false);
        final String? token =
            client.handshake?['headers']?['rpmtw_auth_token']?[0];
        final String? minecraftUUID =
            client.handshake?['headers']?['minecraft_uuid']?[0];
        String? minecraftUsername;
        bool minecraftUUIDValid = false;
        User? user;
        if (token != null) {
          try {
            User.getByToken(token).then((value) {
              user = value;
              initCheckList[0] = true;
            });
          } catch (e) {
            user = null;
            initCheckList[0] = true;
          }
        } else {
          initCheckList[0] = true;
        }

        bool isInit() => initCheckList.reduce((a, b) => a && b);
        bool isAuthenticated() =>
            user != null || (minecraftUUIDValid && minecraftUsername != null);

        if (minecraftUUID != null) {
          /// 驗證 minecraft 帳號是否存在
          http
              .get(Uri.parse(
                  "https://sessionserver.mojang.com/session/minecraft/profile/$minecraftUUID"))
              .then((response) {
            if (response.statusCode == 200) {
              Map data = json.decode(response.body);
              minecraftUUIDValid = true;
              minecraftUsername = data['name'];
            }
            initCheckList[1] = true;
          });
        } else {
          initCheckList[1] = true;
        }

        client.on('clientMessage', (_data) {
          if (!isInit()) return; // 尚未完成初始化程序因此不處理該訊息
          if (!isAuthenticated()) return client.error('Unauthorized');

          try {
            Map data = json.decode(_data.toString());
            String? message = data['message'];

            if (message != null && message.isNotEmpty) {
              String username = user?.username ?? minecraftUsername!;
              String? userUUID = user?.uuid;

              if (user?.uuid == "07dfced6-7d41-4660-b2b4-25ba1319b067") {
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
      }
    });
  }

  void sendMessage(Socket client, CosmicChatMessage msg) {
    client.emit('sentMessage', msg.toJson());
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
