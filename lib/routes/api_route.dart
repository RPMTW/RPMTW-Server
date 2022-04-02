import 'package:shelf_router/shelf_router.dart';

abstract class APIRoute {
  String get routeName;
  void router(Router router) => throw UnimplementedError();

  void register(Router mainRouter) {
    final Router _router = Router();
    router(_router);
    mainRouter.mount('/$routeName/', _router);
  }
}
