import "dart:typed_data";

import "package:byte_size/byte_size.dart";
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import "package:shelf/shelf.dart";
import "../database/database.dart";
import "../database/models/storage/storage.dart";
import "../utilities/extension.dart";
import "base_route.dart";

class StorageRoute extends APIRoute {
  @override
  String get routeName => "storage";

  @override
  void router(router) {
    router.postRoute("/create", (req, data) async {
      String contentType =
          req.headers["content-type"] ?? "application/octet-stream";

      Storage storage = Storage(
          type: StorageType.temp,
          contentType: contentType,
          uuid: Uuid().v4(),
          createAt: DateTime.now().toUtc());
      GridIn gridIn =
          DataBase.instance.gridFS.createFile(data.byteStream, storage.uuid);
      ByteSize size = ByteSize.FromBytes(req.contentLength!);
      if (size.MegaBytes > 8) {
        // 限制最大檔案大小為 8 MB
        return APIResponse.badRequest(message: "File size is too large");
      }
      await gridIn.save();
      await storage.insert();

      return APIResponse.success(data: storage.outputMap());
    });

    router.getRoute("/<uuid>", (req, data) async {
      String uuid = data.fields["uuid"]!;
      Storage? storage = await Storage.getByUUID(uuid);
      if (storage == null) {
        return APIResponse.modelNotFound<Storage>();
      }
      return APIResponse.success(data: storage.outputMap());
    });

    router.getRoute("/<uuid>/download", (req, data) async {
      String uuid = data.fields["uuid"]!;
      Storage? storage = await Storage.getByUUID(uuid);
      if (storage == null) {
        return APIResponse.modelNotFound<Storage>();
      }

      Uint8List bytes = await storage.readAsBytes();

      return Response.ok(bytes, headers: {
        "Content-Type": storage.contentType,
      });
    });
  }
}
