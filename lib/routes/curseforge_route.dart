import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:rpmtw_server/utilities/messages.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class CurseForgeRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.all('/', (Request req) async {
      try {
        final Map<String, String> queryParameters = req.url.queryParameters;

        bool validateFields =
            Utility.validateRequiredFields(queryParameters, ["path"]);

        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        final Uri url =
            Uri.parse("https://api.curseforge.com/${queryParameters['path']}");
        final Map<String, String> headers = {
          "x-api-key": env["CurseForge_API_KEY"]!.replaceAll("\\", ""),
          "content-type": "application/json"
        };

        late http.Response response;

        if (req.method == "GET") {
          response = await http.get(url, headers: headers);
        } else if (req.method == "POST") {
          response = await http.post(url,
              headers: headers, body: await req.readAsString());
        }

        return ResponseExtension.success(data: json.decode(response.body));
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
