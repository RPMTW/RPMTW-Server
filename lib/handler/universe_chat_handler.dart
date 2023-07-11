import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/models/auth/user_role.dart';
import 'package:rpmtw_server/utilities/request_extension.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:socket_io/socket_io.dart';

import 'package:rpmtw_server/database/models/auth/ban_info.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/universe_chat/universe_chat_message.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/scam_detection.dart';
import 'package:stream/stream.dart';

class UniverseChatHandler {
  static late final Server _io;

  static Server get io => _io;

  /// Number of online users.
  static int get onlineUsers => _io.sockets.sockets.length;

  static final List<_CacheMinecraftInfo> _cachedMinecraftInfos = [];

  Future<void> init() async {
    /// 2087 is cloudflare supported proxy https port
    int port = int.parse(env['universe_chat_PORT'] ?? '2087');

    StreamServer? server;

    final securityContext = Utility.getSecurityContext();

    if (securityContext != null) {
      server = StreamServer();
      await server.startSecure(
        securityContext,
        port: port,
        shared: true,
      );
    }

    _io = Server(server: server);
    final InternetAddress ip = InternetAddress.anyIPv4;

    try {
      eventHandler(io);
      await io.listen(port);
      loggerNoStack
          .i('Universe Chat Server listening on port http://${ip.host}:$port');
    } catch (e) {
      // coverage:ignore-line
      loggerNoStack.e('Universe Chat Server error: $e');
    }
  }

  void eventHandler(Server io) {
    io.on('connection', (client) async {
      if (client is Socket) {
        late final User? user;
        Map<String, dynamic> headers = {};
        client.request.headers.forEach((name, values) {
          headers[name] = values;
        });
        final String? token = headers['rpmtw_auth_token']?[0];
        bool init = false;

        if (token != null) {
          fetch() async {
            try {
              User? _user = await User.getByToken(token);
              user = _user;
              init = true;
            } catch (e) {
              user = null;
              init = true;
              client.error('Invalid rpmtw account token');
            }
          }

          fetch();
        } else {
          user = null;
          init = true;
        }

        while (true) {
          if (init) {
            clientMessageHandler(client, headers, user);
            discordMessageHandler(client, user);
            break;
          } else {
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    });
  }

  Future<void> clientMessageHandler(
      Socket client, Map<String, dynamic> headers, User? user) async {
    bool isInit = false;
    final String? minecraftUUID = headers['minecraft_uuid']?[0];
    final ip = InternetAddress(headers['CF-Connecting-IP'] ??
        client.request.connectionInfo!.remoteAddress.address);

    late String? minecraftUsername;
    late bool isAuthenticated;
    late BanInfo? banInfo;

    /// Listen to the client's message.
    client.on('clientMessage', (_data) async {
      Future<void> handleMessage() async {
        final dataList = _data as List;
        final List bytes = dataList.first is List ? dataList.first : dataList;
        final Function? ack = dataList.last is Function ? dataList.last : null;

        if (banInfo != null) {
          return ack?.call(json.encode({
            'status': 'banned',
          }));
        }
        if (!isAuthenticated) {
          return ack?.call(json.encode({
            'status': 'unauthorized',
          }));
        }

        final Map data = json.decode(utf8.decode((bytes).cast<int>()));
        final String? message = data['message'];

        if (message != null && message.isNotEmpty) {
          String username = user?.username ?? minecraftUsername!;
          late String userIdentifier;
          final userUUID = user?.uuid;
          final userAvatarStorageUUID = user?.avatarStorageUUID;
          final String? nickname = data['nickname'];
          final String? replyMessageUUID = data['replyMessageUUID'];

          if (user?.uuid == 'ed16717e-9bd7-4055-80f2-a0104baa3f9a') {
            username = 'RPMTW 維護者兼創辦人';
          }

          if (userUUID != null) {
            userIdentifier = 'rpmtw:$userUUID';
          } else if (minecraftUUID != null) {
            userIdentifier = 'minecraft:$minecraftUUID';
          }

          late String? avatar;

          if (userUUID != null && userAvatarStorageUUID != null) {
            avatar =
                '${kTestMode ? 'http://localhost:8080' : 'https://api.rpmtw.com:2096'}/storage/$userAvatarStorageUUID/download';
          } else if (minecraftUUID != null) {
            avatar = 'https://crafthead.net/avatar/$minecraftUUID.png';
          } else {
            avatar = null;
          }

          if (replyMessageUUID != null) {
            final replyMessage =
                await UniverseChatMessage.getByUUID(replyMessageUUID);
            if (replyMessage == null) {
              return client.error('Invalid reply message UUID');
            }
          }

          final msg = UniverseChatMessage(
              uuid: Uuid().v4(),
              username: username,
              userIdentifier: userIdentifier,
              message: message,
              nickname: nickname,
              avatarUrl: avatar,
              sentAt: RPMTWUtil.getUTCTime(),
              ip: ip,
              userType: user != null
                  ? UniverseChatUserType.rpmtw
                  : UniverseChatUserType.minecraft,
              replyMessageUUID: replyMessageUUID);
          sendMessage(msg, ack: ack);
        }
      }

      try {
        // Wait until the server is processed the client data.
        while (true) {
          if (isInit) {
            await handleMessage();
            break;
          } else {
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      } catch (e, stackTrace) {
        logger.e(
            '[Universe Chat] Throwing errors when handling client messages: $e',
            null,
            stackTrace);
      }
    });

    try {
      bool minecraftUUIDValid = false;

      if (minecraftUUID != null) {
        _CacheMinecraftInfo? info = _cachedMinecraftInfos
            .firstWhereOrNull((e) => e.uuid == minecraftUUID);
        if (info != null) {
          minecraftUUIDValid = true;
          minecraftUsername = info.name;
        } else {
          // Verify the minecraft account
          final response = await http.get(Uri.parse(
              'https://sessionserver.mojang.com/session/minecraft/profile/$minecraftUUID'));

          if (response.statusCode == 200) {
            Map data = json.decode(response.body);
            minecraftUUIDValid = true;
            minecraftUsername = data['name'];
            _cachedMinecraftInfos.add(
                _CacheMinecraftInfo(uuid: minecraftUUID, name: data['name']));
          }
        }
      }

      banInfo = await BanInfo.getByIP(ip.address);
      isAuthenticated =
          (user != null) || (minecraftUUIDValid && minecraftUsername != null);

      isInit = true;
    } catch (e, stackTrace) {
      logger.e(
          '[Universe Chat] Throwing errors when handling client connect: $e',
          null,
          stackTrace);
    }
  }

  void discordMessageHandler(Socket client, User? user) {
    try {
      if (user == null) return;
      final bool isValid =
          user.role.permission.hasPermission(UserRoleType.bot) &&
              user.role.botType == BotType.discord;

      /// Verify that the message is sent by the [RPMTW Discord Bot](https://github.com/RPMTW/RPMTW-Discord-Bot) and not a forged message from someone else.
      if (!isValid) return;
      client.on('discordMessage', (_data) async {
        final dataList = _data as List;
        final List bytes = dataList.first is List ? dataList.first : dataList;
        final Function? ack = dataList.last is Function ? dataList.last : null;
        Map data = json.decode(utf8.decode(bytes.cast<int>()));

        String? message = data['message'];
        String? username = data['username'];
        String? avatarUrl = data['avatarUrl'];
        String? nickname = data['nickname'];
        String? replyMessageUUID = data['replyMessageUUID'];
        String? userId = data['userId'];

        if (message == null ||
            message.isEmpty ||
            username == null ||
            username.isEmpty ||
            userId == null) {
          return client.error('Invalid discord message');
        }

        if (replyMessageUUID != null) {
          UniverseChatMessage? replyMessage =
              await UniverseChatMessage.getByUUID(replyMessageUUID);
          if (replyMessage == null) {
            return client.error('Invalid reply message UUID');
          }
        }

        final msg = UniverseChatMessage(
            uuid: Uuid().v4(),
            username: username,
            userIdentifier: 'discord:$userId',
            message: message,
            nickname: nickname,
            avatarUrl: avatarUrl,
            sentAt: RPMTWUtil.getUTCTime(),
            ip: client.request.connectionInfo!.remoteAddress,
            userType: UniverseChatUserType.discord,
            replyMessageUUID: replyMessageUUID);
        sendMessage(msg);

        ack?.call(msg.uuid);
      });
    } catch (e, stackTrace) {
      // coverage:ignore-line
      logger.e(
          '[Universe Chat] Throwing errors when handling discord messages: $e',
          null,
          stackTrace);
    }
  }

  Future<void> sendMessage(UniverseChatMessage msg, {Function? ack}) async {
    const List<String> dirtyWords = ["傻逼", "屁事"];

    bool phishing = await ScamDetection.detectionWithBool(msg.message);
    bool isDirtyWord =
        dirtyWords.firstWhereOrNull((word) => msg.message.contains(word)) !=
            null;

    /// Detect phishing
    if (phishing || isDirtyWord) {
      return ack?.call(json.encode({
        'status': 'phishing',
      }));
    } else {
      await msg.insert();

      /// Use utf8 encoding to avoid some characters (e.g. Chinese, Japanese) cannot be parsed.
      io.emit('sentMessage', utf8.encode(json.encode(msg.outputMap())));
      ack?.call(json.encode({'status': 'success'}));
    }
  }
}

class _CacheMinecraftInfo {
  final String uuid;
  final String name;
  const _CacheMinecraftInfo({
    required this.uuid,
    required this.name,
  });
}
