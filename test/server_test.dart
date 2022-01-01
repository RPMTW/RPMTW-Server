@TestOn("vm")

import 'package:http/http.dart';
import 'package:test/test.dart';
import "../bin/server.dart" as server;

void main() {
  final port = '8080';
  final host = 'http://0.0.0.0:$port';

  setUpAll(() {
    return Future.sync(() async => await server.run());
  });

  tearDownAll(() async {
    return Future.sync(() async => await server.server?.close(force: true));
  });

  test('Root', () async {
    final response = await get(Uri.parse(host + '/'));
    expect(response.statusCode, 200);
    expect(response.body, 'Hello RPMTW World!');
  });

  test('404', () async {
    final response = await get(Uri.parse(host + '/foobar'));
    expect(response.statusCode, 404);
  });
}
