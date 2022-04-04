import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/ban_info.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/auth/user_role.dart';
import 'package:rpmtw_server/database/models/universe_chat/universe_chat_message.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final universeChatHost = 'http://localhost:2087';
  final host = TestUttily.host;
  final baseOption =
      OptionBuilder().setTransports(['websocket']).disableAutoConnect();
  io.Socket socket = io.io(universeChatHost, baseOption.build());
  final String message = 'Hello RPMTW World!';

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  tearDown(() {
    socket = socket.disconnect();
    (socket.opts?['extraHeaders'] as Map?)?.clear();
    socket.clearListeners();
  });

  Future<void> wait({double scale = 1}) =>
      Future.delayed(Duration(milliseconds: (500 * scale).toInt()));

  Map decodeMessage(List<dynamic> message) =>
      json.decode(utf8.decode(List<int>.from(message)));

  List<int> encodeMessage(Map message) => utf8.encode(json.encode(message));

  test('send message (unauthorized)', () async {
    List<Map> messages = [];
    Map? response;

    socket.onConnect((_) async {
      socket.emitWithAck('clientMessage', encodeMessage({'message': message}),
          ack: (_response) {
        response = json.decode(_response.toString());
      });
    });

    socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

    socket = socket.connect();

    await wait(scale: 2);

    expect(messages.isEmpty, true);
    expect(response!['status'], contains('unauthorized'));
  });
  group('send message by minecraft account', () {
    final String minecraftUUID = '977e69fb-0b15-40bf-b25e-4718485bf72f';
    late final String messageUUID;

    setUpAll(() {
      return Future.sync(() async {
        UniverseChatMessage msg = UniverseChatMessage(
            uuid: Uuid().v4(),
            username: 'SiongSng',
            message: message,
            avatarUrl: 'https://crafthead.net/avatar/$minecraftUUID.png',
            sentAt: Utility.getUTCTime(),
            ip: InternetAddress.loopbackIPv4,
            userType: UniverseChatUserType.minecraft);

        msg.insert();
        messageUUID = msg.uuid;
      });
    });

    tearDownAll(() {
      return Future.sync(() async {
        UniverseChatMessage? msg =
            await UniverseChatMessage.getByUUID(messageUUID);
        await msg!.delete();
      });
    });

    test('send message', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      socket.onConnect((_) async {
        socket.emitWithAck('clientMessage', encodeMessage({'message': message}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 4);

      expect(errors.isEmpty, true);
      expect(messages.isEmpty, false);
      expect(messages.first['message'], message);
      expect(messages.first['username'], contains('SiongSng'));
      expect(messages.first['nickname'], null);
      expect(messages.first['avatarUrl'], contains(minecraftUUID));
      expect(messages.first['userType'], 'minecraft');
      expect(messages.length, 1);
      expect(response!['status'], 'success');
    });
    test('send message (banned)', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      String ip = '127.0.0.1';

      /// 暫時手動新增一個測試用假資料
      BanInfo _info = BanInfo(
          ip: ip,
          reason: 'Sending fraudulent messages in universe chat',
          userUUID: [],
          uuid: Uuid().v4());
      await _info.insert();

      socket.onConnect((_) async {
        socket.emitWithAck('clientMessage', encodeMessage({'message': message}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 4);

      expect(errors.isEmpty, true);
      expect(messages.isEmpty, true);
      expect(response!['status'], 'banned');

      await _info.delete();
    });
    test('send message (phishing message)', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      socket.onConnect((_) async {
        socket.emitWithAck(
            'clientMessage',
            encodeMessage(
                {'message': 'Free nitro\nhttps://disacordnitro.gift'}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 3.5);

      expect(errors.isEmpty, true);
      expect(messages.isEmpty, true);
      expect(response!['status'], 'phishing');
    });
    test('send message (blacklisted phishing message )', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      socket.onConnect((_) async {
        socket.emitWithAck(
            'clientMessage',
            encodeMessage(
                {'message': 'Free nitro\nhttps://discord-nitro-free.com'}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 3.5);

      expect(errors.isEmpty, true);
      expect(messages.isEmpty, true);
      expect(response!['status'], 'phishing');
    });
    test('view message', () async {
      final response =
          await get(Uri.parse(host + '/universe-chat/view/$messageUUID'));
      Map data = json.decode(response.body)['data'];
      expect(response.statusCode, 200);
      expect(data['message'], message);
      expect(data['username'], contains('SiongSng'));
      expect(data['nickname'], null);
      expect(data['avatarUrl'], contains(minecraftUUID));
      expect(data['userType'], 'minecraft');
    });
    test('view message (invalid uuid)', () async {
      final response = await get(Uri.parse(host + '/universe-chat/view/test'));
      expect(response.statusCode, 400);
    });
    test('reply message', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      socket.onConnect((_) async {
        socket.emitWithAck(
            'clientMessage',
            encodeMessage(
                {'message': message, 'replyMessageUUID': messageUUID}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 4.5);

      expect(errors.isEmpty, true);
      expect(messages.isEmpty, false);
      expect(messages.first['message'], message);
      expect(messages.first['username'], contains('SiongSng'));
      expect(messages.first['nickname'], null);
      expect(messages.first['avatarUrl'], contains(minecraftUUID));
      expect(messages.first['userType'], 'minecraft');
      expect(messages.first['replyMessageUUID'], messageUUID);
      expect(messages.length, 1);
      expect(response!['status'], 'success');
    });
    test('reply message (invalid uuid)', () async {
      List<String> errors = [];
      List<Map> messages = [];
      Map? response;
      socket.opts!['extraHeaders'] = {'minecraft_uuid': minecraftUUID};

      socket.onConnect((_) async {
        socket.emitWithAck('clientMessage',
            encodeMessage({'message': message, 'replyMessageUUID': 'test'}),
            ack: (_response) {
          response = json.decode(_response.toString());
        });
      });

      socket.onError((e) async => errors.add(e));

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 3.5);

      expect(errors.isEmpty, false);
      expect(errors.first, contains('Invalid'));
      expect(messages.isEmpty, true);
      expect(response, null);
    });
    test('get info (socket not connect)', () async {
      final response = await get(Uri.parse(host + '/universe-chat/info'));
      Map data = json.decode(response.body)['data'];
      expect(response.statusCode, 200);
      expect(data['onlineUsers'], 0);
      expect(data['protocolVersion'], 1);
    });
    test('get info (socket connected)', () async {
      socket.onConnect((data) async {
        final response = await get(Uri.parse(host + '/universe-chat/info'));
        Map data = json.decode(response.body)['data'];
        expect(response.statusCode, 200);
        expect(data['onlineUsers'], 1);
        expect(data['protocolVersion'], 1);
      });

      socket = socket.connect();
      await wait();
    });
  });

  test('send message by rpmtw account', () async {
    /// Create a new rpmtw account
    final _response = await post(Uri.parse(host + '/auth/user/create'),
        body: json.encode({
          'password': 'testPassword1234',
          'email': 'test@gmail.com',
          'username': 'test',
        }),
        headers: {'Content-Type': 'application/json'});
    Map _body = json.decode(_response.body)['data'];
    String userToken = _body['token'];
    String userUUID = _body['uuid'];

    List<String> errors = [];
    List<Map> messages = [];
    Map? response;
    socket.opts!['extraHeaders'] = {'rpmtw_auth_token': userToken};

    socket.onConnect((_) async {
      await wait();
      socket.emitWithAck('clientMessage', encodeMessage({'message': message}),
          ack: (_response) {
        response = json.decode(_response.toString());
      });
    });

    socket.onError((e) async => errors.add(e));

    socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

    socket = socket.connect();

    await wait(scale: 2);

    expect(errors.isEmpty, true);
    expect(messages.isEmpty, false);
    expect(messages.first['message'], message);
    expect(messages.first['username'], contains('test'));
    expect(messages.first['nickname'], null);
    expect(messages.first['avatarUrl'], '$host/storage/$userUUID/download');
    expect(messages.first['userType'], 'rpmtw');
    expect(messages.length, 1);
    expect(response!['status'], 'success');
  });
  test('send message by rpmtw account (invalid token)', () async {
    List<String> errors = [];
    List<Map> messages = [];
    socket.opts!['extraHeaders'] = {'rpmtw_auth_token': 'test'};
    Map? response;

    socket.onConnect((_) async {
      await wait();
      socket.emitWithAck('clientMessage', encodeMessage({'message': message}),
          ack: (_response) {
        response = json.decode(_response.toString());
      });
    });

    socket.onError((e) async => errors.add(e));

    socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

    socket = socket.connect();

    await wait(scale: 1.5);

    expect(errors.isEmpty, false);
    expect(errors.first.toLowerCase(), contains('invalid'));
    expect(errors.first.toLowerCase(), contains('token'));
    expect(messages.isEmpty, true);
    expect(response!['status'], contains('unauthorized'));
  });
  group('discord', () {
    final String username = 'SiongSng';
    final String nickname = '菘菘';
    final String avatarUrl =
        'https://cdn.discordapp.com/avatars/645588343228334080/f56a0b0223d5f32b902edcb362d08a5d.png';
    late final String messageUUID;
    late final String botToken;

    setUpAll(() {
      return Future.sync(() async {
        User user = User(
            uuid: Uuid().v4(),
            username: 'RPMTW Discord Bot',
            email: 'discordBot@rpmtw.com',
            emailVerified: true,
            passwordHash: '',
            loginIPs: [],
            role: UserRole(
                botType: BotType.discord,
                roles: [UserRoleType.general, UserRoleType.bot]));

        await user.insert();
        botToken = AuthHandler.generateAuthToken(user.uuid);
      });
    });

    test('send message (unauthorized)', () async {
      List<Map> messages = [];

      socket.onConnect((_) async {
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              'message': message,
              'username': username,
              'nickname': nickname,
              'avatarUrl': avatarUrl
            })));
      });

      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));
      socket = socket.connect();

      await wait();
      expect(messages.isEmpty, true);
    });
    test('send message (invalid message)', () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!['extraHeaders'] = {'rpmtw_auth_token': botToken};

      socket.onConnect((_) async {
        await wait();
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              'message': message,
              'username': null,
              'nickname': nickname,
              'avatarUrl': null
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 2);

      expect(errors.first.toLowerCase(), contains('invalid'));
      expect(messages.isEmpty, true);
    });
    test('send message', () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!['extraHeaders'] = {'rpmtw_auth_token': botToken};

      socket.onConnect((_) async {
        await wait();
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              'message': message,
              'username': username,
              'nickname': nickname,
              'avatarUrl': avatarUrl
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 2);
      expect(errors.isEmpty, true);
      expect(messages.isNotEmpty, true);
      expect(messages.first['message'], message);
      expect(messages.first['username'], username);
      expect(messages.first['nickname'], nickname);
      expect(messages.first['avatarUrl'], avatarUrl);
      expect(messages.first['userType'], 'discord');
      expect(messages.length, 1);

      messageUUID = messages.first['uuid'];
    });
    test('reply message', () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!['extraHeaders'] = {'rpmtw_auth_token': botToken};

      socket.onConnect((_) async {
        await wait();
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              'message': message,
              'username': username,
              'nickname': nickname,
              'avatarUrl': avatarUrl,
              'replyMessageUUID': messageUUID
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 2);
      expect(errors.isEmpty, true);
      expect(messages.isNotEmpty, true);
      expect(messages.first['message'], message);
      expect(messages.first['username'], username);
      expect(messages.first['nickname'], nickname);
      expect(messages.first['avatarUrl'], avatarUrl);
      expect(messages.first['userType'], 'discord');
      expect(messages.first['replyMessageUUID'], messageUUID);
      expect(messages.length, 1);
    });
    test('reply message (invalid uuid)', () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!['extraHeaders'] = {'rpmtw_auth_token': botToken};

      socket.onConnect((_) async {
        await wait();
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              'message': message,
              'username': username,
              'nickname': nickname,
              'avatarUrl': avatarUrl,
              'replyMessageUUID': 'test'
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(decodeMessage(msg)));

      socket = socket.connect();

      await wait(scale: 2);
      expect(errors.isEmpty, false);
      expect(errors.first, contains('Invalid'));
      expect(messages.isEmpty, true);
    });
  });
}
