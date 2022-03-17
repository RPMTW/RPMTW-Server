import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import '../../test_utility.dart';

void main() async {
  final host = TestUttily.host;

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test('Root', () async {
    final response = await get(Uri.parse(host + '/'));
    Map data = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(data['message'], 'Hello RPMTW World');
  });

  test('IP', () async {
    final response = await get(Uri.parse(host + '/ip'));
    Map data = json.decode(response.body)['data'];
    expect(response.statusCode, 200);
    expect(data['ip'], contains("127.0.0.1"));
  });

  test('404', () async {
    final response = await get(Uri.parse(host + '/foobar'));
    expect(response.statusCode, 404);
  });
}
