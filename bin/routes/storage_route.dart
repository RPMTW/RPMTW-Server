import 'dart:typed_data';

import 'package:byte_size/byte_size.dart';
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
        Uint8List bytes =
            Uint8List.fromList((data['bytes'] as List).cast<int>());
        ByteSize size = ByteSize.FromBytes(bytes.lengthInBytes);
        if (size.MegaBytes >= 50) {
          // 限制最大檔案大小為 50 MB
          return ResponseExtension.badRequest(
              message: "File size is too large");
        }
        Storage storage =
            Storage(uuid: Uuid().v4(), bytes: bytes, type: StorageType.temp);
        DataBase.instance.insertOneModel<Storage>(storage);
        return ResponseExtension.success(data: {
          'uuid': storage.uuid,
        });
      } catch (e) {
        return ResponseExtension.badRequest();
      }
    });

    router.get("/<uuid>", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        Storage? storage =
            await DataBase.instance.getModelFromUUID<Storage>(uuid);
        if (storage == null) {
          return ResponseExtension.notFound();
        }
        return ResponseExtension.success(data: storage.outputMap());
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/download/<uuid>", (Request req) async {
      try {
        String uuid = req.params['uuid']!;
        Storage? storage =
            await DataBase.instance.getModelFromUUID<Storage>(uuid);
        if (storage == null) {
          return ResponseExtension.notFound();
        }
        return Response.ok(storage.bytes, headers: {
          'Content-Type': 'binary/octet-stream',
        });
      } catch (e) {
        logger.e(e);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
