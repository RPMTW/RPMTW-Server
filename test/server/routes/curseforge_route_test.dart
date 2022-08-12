import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import '../../test_utility.dart';

void main() async {
  final host = TestUttily.host;

  setUpAll(() => TestUttily.setUpAll());
  tearDownAll(() => TestUttily.tearDownAll());

  test('get mod', () async {
    final response = await get(Uri.parse(host + '/curseforge/')
        .replace(queryParameters: {'path': 'v1/mods/461500'}));
    Map data = json.decode(response.body)['data']['data'];
    expect(response.statusCode, 200);
    expect(data['id'], 461500);
    expect(data['name'], contains('RPMTW'));
  }, retry: 3);
  test('get mods (post method)', () async {
    final response = await post(
        Uri.parse(host + '/curseforge/')
            .replace(queryParameters: {'path': 'v1/mods'}),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'modIds': [461500]
        }));
    List data = json.decode(response.body)['data']['data'];
    expect(response.statusCode, 200);
    expect(data[0]['id'], 461500);
    expect(data[0]['name'], contains('RPMTW'));
  }, retry: 2);
  test('missing required fields', () async {
    final response = await get(Uri.parse(host + '/curseforge/'));
    expect(response.statusCode, 400);
  });
}
