import 'dart:developer';
import 'dart:io';

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart';
import 'package:watcher/watcher.dart';

class Utility {
  static Future<void> hotReload() async {
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
          // log('App restarted ${DateTime.now()}');
        });
      }
    }
  }
}
