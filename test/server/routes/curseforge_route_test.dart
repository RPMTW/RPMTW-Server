import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import '../../test_utility.dart';

void main() async {
  final host = 'http://0.0.0.0:8080';

  setUpAll(() {
    return TestUttily.setUpAll();
  });

  tearDownAll(() {
    return TestUttily.tearDownAll();
  });

  test("get mod", () async {
    final response =
        await get(Uri.parse(host + '/curseforge/?path=v1/mods/461500'));
    Map data = json.decode(response.body)['data']['data'];
    expect(response.statusCode, 200);
    expect(data['id'], 461500);
    expect(data['name'], contains("RPMTW"));
  });
  test("get mods (post method)", () async {
    final response = await post(Uri.parse(host + '/curseforge/?path=v1/mods'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "modIds": [461500]
        }));
    List data = json.decode(response.body)['data']['data'];
    expect(response.statusCode, 200);
    expect(data[0]['id'], 461500);
    expect(data[0]['name'], contains("RPMTW"));
  });
  test("missing required fields", () async {
    final response = await get(Uri.parse(host + '/curseforge/'));
    expect(response.statusCode, 400);
  });
}
