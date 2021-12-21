import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthRoute {
  Router get router {
    final router = Router();

    router.post('/user/create', (Request req) async {
      return Response.ok('test');
    });

    return router;
  }
}
