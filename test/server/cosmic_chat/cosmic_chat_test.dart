import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final cosmicChatHost = 'http://0.0.0.0:2087';
  final baseOption =
      OptionBuilder().setTransports(['websocket']).disableAutoConnect();

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test("send message (unauthorized)", () async {
    String? error;
    io.Socket socket = io.io(cosmicChatHost, baseOption.build());

    socket = socket.connect();

    socket.onConnect((_) async {
      socket.emit('clientMessage', json.encode({"message": 'Hello,World!'}));
    });

    socket.on('serverError', (_error) => error = _error);

    await Future.delayed(Duration(seconds: 1));

    expect(error, contains('Unauthorized'));

    socket.disconnect();
  });
  test("send message", () async {
    String? error;
    io.Socket socket = io.io(
        cosmicChatHost,
        baseOption.setExtraHeaders({
          "minecraft_uuid": "977e69fb-0b15-40bf-b25e-4718485bf72f"
        }).build());

    socket = socket.connect();

    socket.onConnect((_) async {
      socket.emit('clientMessage', json.encode({"message": 'Hello,World!'}));
    });

    socket.on('serverError', (_error) => error = _error);

    socket.on('serverMessage', (data) => print(data));

    await Future.delayed(Duration(seconds: 3));

    expect(error, null);
    socket.disconnect();
  });
}
