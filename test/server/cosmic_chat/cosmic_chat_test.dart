import 'dart:convert';

import 'package:rpmtw_server/handler/cosmic_chat_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final cosmicChatHost = 'http://localhost:2087';
  final baseOption =
      OptionBuilder().setTransports(['websocket']).disableAutoConnect();
  io.Socket socket = io.io(cosmicChatHost, baseOption.build());

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  Future<void> wait({int scale = 1}) =>
      Future.delayed(Duration(milliseconds: 500 * scale));

  test("send message (unauthorized)", () async {
    List<String> errors = [];
    socket = socket.connect();

    socket.onConnect((_) async {
      await wait();
      socket.emit('clientMessage', json.encode({"message": 'Hello,World!'}));
    });

    socket.onError((e) async => errors.add(e));

    await wait(scale: 2);

    expect(errors.first, contains('Unauthorized'));
  });
  test("send message", () async {
    final String message = "Hello,World!";
    final String minecraftUUID = "977e69fb-0b15-40bf-b25e-4718485bf72f";
    List<String> errors = [];
    List<CosmicChatMessage> messages = [];
    socket.opts!["extraHeaders"] = {"minecraft_uuid": minecraftUUID};
    socket = socket
      ..disconnect()
      ..connect();

    socket.onConnect((_) async {
      await wait(scale: 2);
      socket.emit('clientMessage', json.encode({"message": message}));
    });

    socket.onError((e) async => errors.add(e));

    socket.on('sentMessage',
        (msg) => messages.add(CosmicChatMessage.fromJson(msg)));

    await wait(scale: 5);

    expect(errors.isEmpty, true);
    expect(messages.isEmpty, false);
    expect(messages.first.message, message);
    expect(messages.first.username, contains("SiongSng"));
    expect(messages.first.nickname, null);
    expect(messages.first.avatarUrl, contains(minecraftUUID));
    socket.disconnect();
  });
}
