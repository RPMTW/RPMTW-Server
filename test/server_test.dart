@TestOn("vm")

import 'package:http/http.dart';
import 'package:test/test.dart';
import "../bin/server.dart" as server;

void main() {
  final port = '8080';
  final host = 'http://0.0.0.0:$port';

  setUp(() async {
    // await server.run();
  });

  tearDown(() async {
    // await server.server.close(force: true);
  });

  test('Root', () async {
    final response = await get(Uri.parse(host + '/'));
    expect(response.statusCode, 200);
    expect(response.body, 'Hello RPMTW World!');
  }, skip: true);

  test('404', () async {
    final response = await get(Uri.parse(host + '/foobar'));
    expect(response.statusCode, 404);
  }, skip: true);
}
