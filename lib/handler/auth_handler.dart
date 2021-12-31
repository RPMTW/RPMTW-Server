import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:googleapis/gmail/v1.dart' as googleapi;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';
import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';

class AuthHandler {
  static SecretKey secretKey = SecretKey(env['DATA_BASE_SecretKey']!);
  static late googleapi.GmailApi gmailApi;

  // TODO: google api
  static Future<void> initGoogleApis() async {
    List<String> scopes = [googleapi.GmailApi.mailGoogleComScope];

    AutoRefreshingAuthClient httpClient = autoRefreshingClient(
      ClientId(
          '504357039485-65inr6tkht8vuumkpb6m2f1ksog83dpo.apps.googleusercontent.com',
          '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'),
      AccessCredentials(
          AccessToken("Bearer", "", DateTime.parse("")), "", scopes),
      Client(),
    );

    httpClient.credentialUpdates.listen((cred) {
      print('Credential updated\n${cred.toJson()}');
    });

    print(httpClient.credentials.toJson());

    gmailApi = googleapi.GmailApi(httpClient);
  }

  static String generateAuthToken(String userUUID) {
    JWT jwt = JWT({'uuid': userUUID});
    return jwt.sign(AuthHandler.secretKey);
  }

  static Middleware authorizationToken() => (innerHandler) {
        return (request) {
          return Future.sync(() async {
            String path = request.url.path;
            List<String> needAuthorizationPaths = ["auth/user/me"];
            if (needAuthorizationPaths.contains(path)) {
              String? token = request.headers['Authorization']
                  ?.toString()
                  .replaceAll('Bearer ', '');
              if (token == null) {
                return ResponseExtension.unauthorized();
              }
              try {
                JWT jwt = JWT.verify(token, secretKey);
                Map<String, dynamic> payload = jwt.payload;
                String uuid = payload['uuid'];
                User? user =
                    await DataBase.instance.getModelFromUUID<User>(uuid);
                if (user == null) {
                  return ResponseExtension.unauthorized();
                }
                request = request.change(context: {"user": user});
              } on JWTError catch (e) {
                logger.e(e.message, null, e.stackTrace);
                return ResponseExtension.unauthorized();
              } catch (e, stack) {
                logger.e(e, null, stack);
                return ResponseExtension.internalServerError();
              }
            }
            return await innerHandler(request);
          }).then((response) {
            return response;
          });
        };
      };

  static _EmailValidatedResult validateEmail(String email) {
    String spliter = '@';
    List<String> topEmails = [
      'gmail.com',
      'yahoo.com',
      'yahoo.com.tw',
      'yahoo.com.hk',
      'yahoo.co.uk',
      'yahoo.co.jp',
      'hotmail.com',
      "hotmail.co.uk",
      "hotmail.fr",
      'aol.com',
      'outlook.com',
      'icloud.com',
      'mail.com',
      'me.com',
      'msn.com',
      'live.com',
      'mac.com',
      'qq.com',
      "wanadoo.fr",
    ];

    _EmailValidatedResult successfull =
        _EmailValidatedResult(true, 0, "no issue");
    _EmailValidatedResult unkownDomain =
        _EmailValidatedResult(false, 1, "unkown email domain");
    _EmailValidatedResult invalid =
        _EmailValidatedResult(false, 1, "invalid email");

    if (email.contains(spliter)) {
      String domain = email.split(spliter)[1];
      //驗證網域格式
      if (domain.contains('.')) {
        // 驗證網域是否為知名 Email 網域
        if (topEmails.contains(domain)) {
          return successfull;
        } else {
          // 未知網域
          return unkownDomain;
        }
      } else {
        return invalid;
      }
    } else {
      return invalid;
    }
  }

  static _PasswordValidatedResult validatePassword(String password) {
    if (password.length < 6) {
      //密碼至少需要6個字元
      return _PasswordValidatedResult(
          false, 1, "Password must be at least 6 characters long");
    } else if (password.length > 30) {
      // 密碼最多30個字元
      return _PasswordValidatedResult(
          false, 2, "Password must be less than 30 characters long");
    } else if (!password.contains(RegExp(r'[A-Za-z]'))) {
      // 密碼必須至少包含一個英文字母
      return _PasswordValidatedResult(
          false, 3, "Password must contain at least one letter of English.");
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      // 密碼必須至少包含一個數字
      return _PasswordValidatedResult(
          false, 4, "Password must contain at least one number");
    } else {
      return _PasswordValidatedResult(true, 0, "no issue");
    }
  }

  // TODO: 完成密碼驗證信件發送
  static Future<bool> sendVerifyEmail() async {
    String email = env["SMTP_User"]!;
    SmtpServer smtpServer = qq(email, env["SMTP_Password"]!);

    final message = Message()
      ..from = Address(email, 'RPMTW Team Support')
      ..recipients.add('rrt467778@gmail.com')
      ..ccRecipients.add('rrt467778@gmail.com')
      ..bccRecipients.add('rrt467778@gmail.com')
      ..subject = 'test rpmtw server email'
      ..text = 'Hello World! now time is ${DateTime.now()}';
    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e, stack) {
      logger.e(e, null, stack);
      return false;
    }
  }
}

abstract class _BaseValidatedResult {
  /// 是否驗證成功
  bool isValid;

  /// 驗證結果代碼
  int code;

  /// 驗證結果訊息
  String message;
  _BaseValidatedResult(this.isValid, this.code, this.message);

  Map toMap() {
    return {"isValid": isValid, "code": code, "message": message};
  }
}

class _PasswordValidatedResult extends _BaseValidatedResult {
  _PasswordValidatedResult(bool isValid, int code, String message)
      : super(isValid, code, message);
}

class _EmailValidatedResult extends _BaseValidatedResult {
  _EmailValidatedResult(bool isValid, int code, String message)
      : super(isValid, code, message);
}
