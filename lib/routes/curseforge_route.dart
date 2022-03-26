import "dart:convert";

import "package:dotenv/dotenv.dart";
import "package:http/http.dart" as http;
import "package:rpmtw_server/routes/api_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/data.dart";
import "package:rpmtw_server/utilities/utility.dart";
import "package:shelf/shelf.dart";

class CurseForgeRoute extends APIRoute {
  @override
  String get routeName => "curseforge";

  @override
  void router(router) {
    router.all("/", (Request req) async {
      try {
        final Map<String, String> queryParameters = req.url.queryParameters;

        String? validateFields =
            Utility.validateRequiredFields(queryParameters, ["path"]);

        if (validateFields != null) {
          return APIResponse.missingRequiredFields(validateFields);
        }

        final Uri url =
            Uri.parse("https://api.curseforge.com/${queryParameters["path"]}");
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

        if (response.statusCode == 200) {
          return APIResponse.success(data: json.decode(response.body));
        } else {
          return APIResponse.badRequest();
        }
      } catch (e, stack) {
        logger.e(e, null, stack);
        return APIResponse.badRequest();
      }
    });
  }
}
