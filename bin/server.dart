import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'Utility/utility.dart';
import 'database/database.dart';

final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello RPMTW World!');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  load();
  final InternetAddress ip = InternetAddress.anyIPv4;

  final Handler _handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router);

  final int port = int.parse(env['API_PORT'] ?? '8080');
  final HttpServer server = await serve(_handler, ip, port);
  print('Server listening on port http://${ip.host}:${server.port}');

  Utility.hotReload();
  await DataBase.init();
}
