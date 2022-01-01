import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:test/test.dart';

void main() {
  group("password validate - ", () {
    test("successful", () {
      String password = "testPassword12345";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isTrue);
      expect(result.code, 0);
      expect(result.message, contains("no issue"));
    });
    test("3 characters", () {
      /// 密碼少於6個字元的情況下
      String password = "123";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isFalse);
      expect(result.code, 1);
      expect(result.message,
          contains("Password must be at least 6 characters long"));
    });

    test("40 characters", () {
      /// 密碼超過30個字元的情況下
      String password = "1234567890123456789012345678901234567891";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isFalse);
      expect(result.code, 2);
      expect(result.message,
          contains("Password must be less than 30 characters long"));
    });
    test("does not contain English characters", () {
      /// 密碼不包含英文字母的情況下
      String password = "123456";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isFalse);
      expect(result.code, 3);
      expect(result.message,
          contains("Password must contain at least one letter of English"));
    });
    test("does not contain numbers", () {
      /// 密碼不包含數字的情況下
      String password = "testPassword";
      final result = AuthHandler.validatePassword(password);
      expect(result.isValid, isFalse);
      expect(result.code, 4);
      expect(result.message,
          contains("Password must contain at least one number"));
    });
  });

  group("email validate - ", () {
    test("successful", () {
      String email = "helloworld@gmail.com";
      final result = AuthHandler.validateEmail(email);
      expect(result.isValid, isTrue);
      expect(result.code, 0);
      expect(result.message, contains("no issue"));
    });
    test("unknown domain", () {
      String email = "helloworld@abc.com";
      final result = AuthHandler.validateEmail(email);
      expect(result.isValid, isFalse);
      expect(result.code, 1);
      expect(result.message, contains("unknown email domain"));
    });
    test("invalid (none @)", () {
      String email = "helloworldgmail.com";
      final result = AuthHandler.validateEmail(email);
      expect(result.isValid, isFalse);
      expect(result.code, 2);
      expect(result.message, contains("invalid email"));
    });

    test("invalid (none .)", () {
      String email = "helloworld@gmailcom";
      final result = AuthHandler.validateEmail(email);
      expect(result.isValid, isFalse);
      expect(result.code, 2);
      expect(result.message, contains("invalid email"));
    });
  });

  test("generateAuthToken", () {
    env['DATA_BASE_SecretKey'] = "testSecretKey";
    final String uuid = Uuid().v4();
    final String token = AuthHandler.generateAuthToken(uuid);

    JWT jwt = JWT.verify(token, AuthHandler.secretKey);

    /// 故意輸入錯誤的 secretKey 來測試是否會驗證失敗
    expect(() => JWT.verify(token, SecretKey("test")),
        throwsA(isA<JWTUndefinedError>()));

    expect(jwt.payload["uuid"], uuid);
  });
}
