import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';

import '../database/database.dart';
import '../database/models/storage/storage.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';
import 'base_route.dart';
import 'root_route.dart';

class StorageRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.post("/create", (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;
        Storage storage = Storage.fromMap(data);
        storage = storage.copyWith(uuid: Uuid().v4(), type: StorageType.temp);
        DataBase.instance.insertOneModel<Storage>(storage);
        return ResponseExtension.success(data: {});
      } catch (e) {
        return ResponseExtension.badRequest();
      }
    });

    router.get("/<uuid>", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        Storage? storage = await DataBase.instance.getModelFromUUID<Storage>(uuid);
        if (storage == null) {
          return ResponseExtension.notFound();
        }
        return ResponseExtension.success(data: storage.outputMap());
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
