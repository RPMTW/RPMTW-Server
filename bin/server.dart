import 'dart:developer';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart';
import 'package:watcher/watcher.dart';

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
  final InternetAddress ip = InternetAddress.anyIPv4;

  final Handler _handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router);

  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final HttpServer server = await serve(_handler, ip, port);
  print('Server listening on port http://${ip.address}:${server.port}');

  Uri? observatoryUri = (await Service.getInfo()).serverUri;
  if (observatoryUri != null) {
    vm_service.VmService serviceClient = await vmServiceConnectUri(
      convertToWebSocketUrl(serviceProtocolUrl: observatoryUri).toString(),
    );
    vm_service.VM vm = await serviceClient.getVM();
    vm_service.IsolateRef? mainIsolate = vm.isolates?.first;
    if (mainIsolate != null && mainIsolate.id != null) {
      Watcher(Directory.current.path).events.listen((_) async {
        await serviceClient.reloadSources(mainIsolate.id!);
        log('App restarted ${DateTime.now()}');
      });
    }
  }
}
