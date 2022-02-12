import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final cosmicChatHost = 'http://localhost:2087';
  final baseOption =
      OptionBuilder().setTransports(['websocket']).disableAutoConnect();
  io.Socket socket = io.io(cosmicChatHost, baseOption.build());
  final String message = "Hello RPMTW World!";

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  tearDown(() {
    socket = socket.disconnect();
    socket.clearListeners();
  });

  Future<void> wait({double scale = 1}) =>
      Future.delayed(Duration(milliseconds: (500 * scale).toInt()));

  test("send message (unauthorized)", () async {
    List<String> errors = [];
    List<Map> messages = [];

    socket.onConnect((_) async {
      await wait();
      socket.emit('clientMessage', json.encode({"message": message}));
    });

    socket.onError((e) async => errors.add(e));
    socket.on(
        'sentMessage', (msg) => messages.add(json.decode(msg)));

    socket = socket.connect();

    await wait(scale: 1.5);

    expect(errors.first, contains('Unauthorized'));
    expect(messages.isEmpty, true);
  });
  test("send message", () async {
    final String minecraftUUID = "977e69fb-0b15-40bf-b25e-4718485bf72f";
    List<String> errors = [];
    List<Map> messages = [];
    socket.opts!["extraHeaders"] = {"minecraft_uuid": minecraftUUID};

    socket.onConnect((_) async {
      await wait();
      socket.emit('clientMessage', json.encode({"message": message}));
    });

    socket.onError((e) async => errors.add(e));

    socket.on('sentMessage', (msg) => messages.add(json.decode(msg)));

    socket = socket.connect();

    await wait(scale: 1.5);

    expect(errors.isEmpty, true);
    expect(messages.isEmpty, false);
    expect(messages.first['message'], message);
    expect(messages.first['username'], contains("SiongSng"));
    expect(messages.first['nickname'], null);
    expect(messages.first['avatarUrl'], contains(minecraftUUID));
    expect(messages.first['userType'], "minecraft");
    expect(messages.length, 1);
  });

  group("send message form discord", () {
    final String username = "SiongSng";
    final String nickname = "菘菘";
    final String avatarUrl =
        "https://cdn.discordapp.com/avatars/645588343228334080/f56a0b0223d5f32b902edcb362d08a5d.png";

    test("(unauthorized)", () async {
      List<String> errors = [];
      List<Map> messages = [];

      socket.onConnect((_) async {
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              "message": message,
              "username": username,
              "nickname": nickname,
              "avatarUrl": avatarUrl
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(json.decode(msg)));
      socket = socket.connect();

      await wait();

      // No errors are thrown for the "discordMessage" event in order to reduce server load.
      expect(errors.isEmpty, true);
      expect(messages.isEmpty, true);
    });
    test("(invalid message)", () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!["extraHeaders"] = {
        "discord_secretKey": TestUttily.secretKey
      };

      socket.onConnect((_) async {
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              "message": message,
              "username": null,
              "nickname": nickname,
              "avatarUrl": null
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(json.decode(msg)));

      socket = socket.connect();

      await wait();

      expect(errors.first, contains('Invalid'));
      expect(messages.isEmpty, true);
    });
    test("(valid message)", () async {
      List<String> errors = [];
      List<Map> messages = [];
      socket.opts!["extraHeaders"] = {
        "discord_secretKey": TestUttily.secretKey
      };

      socket.onConnect((_) async {
        socket.emit(
            'discordMessage',
            utf8.encode(json.encode({
              "message": message,
              "username": username,
              "nickname": nickname,
              "avatarUrl": avatarUrl
            })));
      });

      socket.onError((e) async => errors.add(e));
      socket.on('sentMessage', (msg) => messages.add(json.decode(msg)));

      socket = socket.connect();

      await wait();
      expect(errors.isEmpty, true);
      expect(messages.isNotEmpty, true);
      expect(messages.first['message'], message);
      expect(messages.first['username'], username);
      expect(messages.first['nickname'], nickname);
      expect(messages.first['avatarUrl'], avatarUrl);
      expect(messages.first['userType'], "discord");
      expect(messages.length, 1);
    });
  });
}
