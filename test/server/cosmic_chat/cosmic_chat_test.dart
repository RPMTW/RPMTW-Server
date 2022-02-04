import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:test/test.dart';

import '../../test_utility.dart';

void main() async {
  final cosmicChatHost = 'http://0.0.0.0:2087';
  late io.Socket socket;

  setUpAll(() {
    socket = io.io(
        cosmicChatHost,
        OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test("send message (unauthorized)", () async {
    String? error;
    socket = socket.connect();

    socket.onConnect((_) async {
      socket.emit('clientMessage', 'Hello,World!');
    });

    socket.on('serverError', (_error) => error = _error);

    await Future.delayed(Duration(seconds: 1));

    expect(error, contains('Unauthorized'));
  });
}
