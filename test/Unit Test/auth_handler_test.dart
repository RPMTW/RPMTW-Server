import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';

void main() {
  group("password validate - ", () {
    test("successful", () {
      String password = "testPassword12345";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isTrue);
    });
  });
}
