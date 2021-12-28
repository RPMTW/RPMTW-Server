import 'dart:typed_data';

import 'package:byte_size/byte_size.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';
import '../database/database.dart';
import '../database/models/storage/storage.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';
import 'base_route.dart';

class StorageRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.post("/create", (Request req) async {
      try {
        Stream<List<int>> stream = req.read();

        Storage storage = Storage(type: StorageType.temp, uuid: Uuid().v4());
        GridIn gridIn =
            DataBase.instance.gridFS.createFile(stream, storage.uuid);
        ByteSize size = ByteSize.FromBytes(req.contentLength!);
        if (size.MegaBytes > 8) {
          // 限制最大檔案大小為 8 MB
          return ResponseExtension.badRequest(
              message: "File size is too large");
        }
        await gridIn.save();

        return ResponseExtension.success(data: {
          'uuid': storage.uuid,
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/<uuid>", (Request req) async {
      // TODO: GridFS
      try {
        // String uuid = req.params['uuid']!;
        // Storage? storage =
        //     await DataBase.instance.getModelFromUUID<Storage>(uuid);
        // if (storage == null) {
        //   return ResponseExtension.notFound();
        // }
        // return ResponseExtension.success(data: storage.outputMap());
        return ResponseExtension.success(data: {});
      } catch (e, stack) {
        logger.e(e, null, stack);
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
        GridFS fs = DataBase.instance.gridFS;
        GridOut? gridOut = await fs.getFile(storage.uuid);
        if (gridOut == null) {
          return ResponseExtension.notFound();
        }
        List<Map<String, dynamic>> chunks = await (fs.chunks
            .find(where.eq('files_id', gridOut.id).sortBy('n'))
            .toList());
        List<List<int>> bytes = [];

        for (Map<String, dynamic> chunk in chunks) {
          final data = chunk['data'] as BsonBinary;
          bytes.add(data.byteList);
        }

        return Response.ok(bytes, headers: {
          'Content-Type': 'binary/octet-stream',
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
