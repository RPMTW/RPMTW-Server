import 'package:http/http.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:test/test.dart';
import '../../../bin/server.dart' as server;

void main() async {
  final host = 'http://0.0.0.0:8080';

  setUpAll(() {
    kTestMode = true;
    return Future.sync(() async => await server.run());
  });

  tearDownAll(() {
    return Future.sync(() async {
      await DataBase.instance.db.drop(); // 刪除測試用資料庫
      await server.server?.close(force: true); // 關閉伺服器
    });
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
