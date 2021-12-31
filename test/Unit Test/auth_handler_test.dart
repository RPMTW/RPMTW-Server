import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';

void main() {
  group("password validate - ", () {
    test("successful", () {
      String password = "testPassword12345";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isTrue);
    });
    test("3 characters", () {
      /// 密碼少於6個字元的情況下
      String password = "123";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isFalse);
      expect(result.code, 1);
      expect(result.message, "Password must be at least 6 characters long");
    });
  });
}
