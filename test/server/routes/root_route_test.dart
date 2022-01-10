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
