import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart';
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
        clientMessageHandler(client);
        discordMessageHandler(client);
      }
    });
  }

  void clientMessageHandler(Socket client) {
    try {
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
                "https://${kTestMode ? "0.0.0.0:8080" : "api.rpmtw.com:2096"}/storage/$userUUID/download";
          } else if (minecraftUUID != null) {
            avatar = "https://crafthead.net/avatar/$minecraftUUID.png";
          }

          CosmicChatMessage msg = CosmicChatMessage(
              uuid: Uuid().v4(),
              username: username,
              message: message,
              nickname: data['nickname'],
              avatarUrl: avatar,
              sentAt: DateTime.now(),
              ip: client.request.connectionInfo!.remoteAddress,
              userType: user != null
                  ? CosmicChatUserType.rpmtw
                  : CosmicChatUserType.minecraft);
          sendMessage(client, msg);
        }
      });
    } catch (e, stackTrace) {
      logger.e(
          '[Cosmic Chat] Throwing errors when handling client messages: $e',
          null,
          stackTrace);
    }
  }

  void discordMessageHandler(Socket client) {
    try {
      final String? clientDiscordSecretKey =
          client.handshake?['headers']?['discord_secretKey']?[0];
      final String serverDiscordSecretKey =
          env['COSMIC_CHAT_DISCORD_SecretKey']!;
      final bool isValid = clientDiscordSecretKey == serverDiscordSecretKey;

      /// Verify that the message is sent by the [RPMTW Discord Bot](https://github.com/RPMTW/RPMTW-Discord-Bot) and not a forged message from someone else.
      if (!isValid) return;
      client.on("discordMessage", (_data) {
        Map data = json.decode(utf8.decode(List<int>.from(_data)));

        String? message = data['message'];
        String? username = data['username'];
        String? avatarUrl = data['avatarUrl'];
        String? nickname = data['nickname'];

        if (message == null ||
            message.isEmpty ||
            username == null ||
            username.isEmpty ||
            avatarUrl == null ||
            avatarUrl.isEmpty) return client.error('Invalid discord message');

        CosmicChatMessage msg = CosmicChatMessage(
            uuid: Uuid().v4(),
            username: username,
            message: message,
            nickname: nickname,
            avatarUrl: avatarUrl,
            sentAt: DateTime.now(),
            ip: client.request.connectionInfo!.remoteAddress,
            userType: CosmicChatUserType.discord);
        sendMessage(client, msg);
      });
    } catch (e, stackTrace) {
      logger.e(
          '[Cosmic Chat] Throwing errors when handling discord messages: $e',
          null,
          stackTrace);
    }
  }

  void sendMessage(Socket client, CosmicChatMessage msg) {
    // Use utf8 encoding to avoid some characters (e.g. Chinese, Japanese) cannot be parsed.
    client.emit('sentMessage', utf8.encode(json.encode(msg.outputMap())));
  }
}
