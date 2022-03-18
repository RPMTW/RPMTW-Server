import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/auth/auth_code_.dart';
import 'package:rpmtw_server/database/models/auth/ban_info.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:shelf/shelf.dart';
import '../database/database.dart';
import '../database/models/auth/user.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';

class AuthHandler {
  static SecretKey get secretKey => SecretKey(env['DATA_BASE_SecretKey']!);
  static final int saltRounds = 10;

  static String generateAuthToken(String userUUID) {
    JWT jwt = JWT({'uuid': userUUID});
    return jwt.sign(AuthHandler.secretKey);
  }

  static Future<AuthCode> generateAuthCode(
      String email, String userUUID) async {
    AuthCode authCode = AuthCode.create(email);
    await authCode.insert();
    return authCode;
  }

  static Middleware authorizationToken() => (innerHandler) {
        return (request) {
          return Future.sync(() async {
            String path = request.url.path;

            List<_AuthPath> needAuthorizationPaths = [
              _AuthPath("auth/user/me", method: "GET"),
              _AuthPath("auth/user/me/update", method: "POST"),
              _AuthPath("minecraft/mod/create", method: "POST"),
              _AuthPath("minecraft/mod/edit",
                  method: "PATCH", hasUrlParams: true),
              _AuthPath("translate/vote", method: "POST"),
              _AuthPath("translate/vote/", method: "DELETE", hasUrlParams: true),
            ];

            bool needAuth = needAuthorizationPaths.any((_path) =>
                _path.hasUrlParams
                    ? path.startsWith(_path.path)
                    : path == _path.path && request.method == _path.method);

            if (needAuth) {
              String? token = request.headers['Authorization']
                  ?.toString()
                  .replaceAll('Bearer ', '');

              if (token == null) {
                return APIResponse.unauthorized();
              }

              try {
                User? user = await User.getByToken(token);
                String clientIP = request.ip;
                BanInfo? banInfo = await BanInfo.getByIP(clientIP);
                if (user == null) {
                  return APIResponse.unauthorized();
                } else if (!user.emailVerified && !kTestMode) {
                  // 驗證是否已經驗證電子郵件，測試模式不需要驗證
                  return APIResponse.unauthorized(
                      message: "Unauthorized (email not verified)");
                } else if (banInfo != null) {
                  // 檢查是否被封鎖
                  return APIResponse.banned(reason: banInfo.reason);
                }

                List<String> loginIPs = user.loginIPs;

                /// 如果此登入IP尚未被紀錄過
                if (!loginIPs.contains(clientIP)) {
                  loginIPs.add(clientIP);
                  User _newUser = user.copyWith(loginIPs: loginIPs);

                  /// 寫入新的登入IP
                  await _newUser.update();
                }

                request = request
                    .change(context: {"user": user, "isAuthenticated": true});
              } on JWTError catch (e) {
                logger.e(e.message, null, e.stackTrace);
                return APIResponse.unauthorized();
              } catch (e, stack) {
                logger.e(e, null, stack);
                return APIResponse.internalServerError();
              }
            }
            return await innerHandler(request);
          }).then((response) {
            return response;
          });
        };
      };

  static Future<_EmailValidatedResult> validateEmail(String email,
      {bool skipDuplicate = false}) async {
    String splitter = '@';
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

    _EmailValidatedResult successful =
        _EmailValidatedResult(true, 0, "no issue");
    _EmailValidatedResult unknownDomain =
        _EmailValidatedResult(false, 1, "unknown email domain");
    _EmailValidatedResult invalid =
        _EmailValidatedResult(false, 2, "invalid email");
    _EmailValidatedResult duplicate =
        _EmailValidatedResult(false, 3, "the email has already been used");

    if (email.contains(splitter)) {
      String domain = email.split(splitter)[1];
      //驗證網域格式
      if (domain.contains('.')) {
        //驗證網域是否為已知 Email 網域
        if (topEmails.contains(domain)) {
          if (skipDuplicate) return successful;
          Map<String, dynamic>? map = await DataBase.instance
              .getCollection<User>()
              .findOne(where.eq('email', email));
          if (map == null) {
            // 如果為空代表尚未被使用過
            return successful;
          } else {
            return duplicate;
          }
        } else {
          // 未知網域
          return unknownDomain;
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
          false, 3, "Password must contain at least one letter of English");
    } else if (!password.contains(RegExp(r'[0-9]'))) {
      // 密碼必須至少包含一個數字
      return _PasswordValidatedResult(
          false, 4, "Password must contain at least one number");
    } else {
      return _PasswordValidatedResult(true, 0, "no issue");
    }
  }

  static Future<bool> sendVerifyEmail(String email, int authCode) async {
    if (kTestMode) return true;
    SmtpServer smtpServer;
    String smtpEmail;
    int randomInt = Random.secure().nextInt(100);

    /// 隨機選擇一種 smtp 服務使用
    if (randomInt % 2 == 0) {
      // 偶數
      String _qqSmtpEmail = env["SMTP_QQ_User"]!;
      SmtpServer _qqSmtp = qq(_qqSmtpEmail, env["SMTP_QQ_Password"]!);

      smtpEmail = _qqSmtpEmail;
      smtpServer = _qqSmtp;
    } else {
      // 奇數
      String _zohoSmtpEmail = env["SMTP_ZOHO_User"]!;
      SmtpServer _zohoSmtp = SmtpServer(
        "smtppro.zoho.com",
        port: 587,
        username: _zohoSmtpEmail,
        password: env["SMTP_ZOHO_Password"]!,
      );

      smtpEmail = _zohoSmtpEmail;
      smtpServer = _zohoSmtp;
    }

    String html = '''
Thank you for registering for an account on this site. Below is the verification code to complete registration for this account, which will expire in 30 minutes.<br>
感謝您註冊本網站的帳號，下方是完成註冊此帳號的驗證碼，此驗證碼將於 30 分鐘後失效。

<h1 style="color:orange">${authCode.toString()}<br></h1>

You are receiving this email to verify that the account is registered by you and that you can use the RPMTW account after verification.<br>
If you have not requested an RPMTW account, please ignore this email.<br><br>

您收到這封電子郵件是因為要驗證該帳號是否由您註冊，通過驗證後您才能使用 RPMTW 帳號。<br>
如果您並未提出註冊 RPMTW 帳號的請求，則請忽略此封電子郵件。<br><br>

<strong>Copyright © RPMTW 2021-2022 Powered by The RPMTW Team.</strong>
      ''';

    final message = Message()
      ..from = Address(smtpEmail, 'RPMTW Team Support')
      ..recipients.add(email)
      ..ccRecipients.add(email)
      ..bccRecipients.add(email)
      ..subject = '驗證您的 RPMTW 帳號電子郵件地址'
      ..html = html;
    // TODO:實現驗證電子郵件的界面

    try {
      if (kTestMode) return true; //在測試模式下不發送訊息
      print(email);
      await send(message, smtpServer);
      return true;
    } catch (e, stack) {
      logger.e(e, null, stack);
      return false;
    }
  }

  static bool checkPassword(String password, String hash) {
    DBCrypt dbCrypt = DBCrypt();
    return dbCrypt.checkpw(password, hash);
  }

  static Future<bool> validateAuthCode(String email, int authCode) async {
    try {
      AuthCode? model = await AuthCode.getByCode(authCode);
      if (model == null) {
        return false;
      } else {
        if (model.email == email) {
          //驗證碼的 email 與輸入的 email 是否相同
          if (model.isExpired) {
            //驗證碼過期
            return false;
          } else {
            //驗證碼未過期
            if (kTestMode) return true; //在測試模式下略過確認使用者
            User? user = await User.getByEmail(email);
            if (user != null) {
              user = user.copyWith(emailVerified: true);
              await user.update();
              return true;
            } else {
              return false;
            }
          }
        } else {
          return false;
        }
      }
    } catch (e) {
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

class _AuthPath {
  final String path;
  final bool hasUrlParams;
  final String method;

  _AuthPath(this.path, {this.hasUrlParams = false, required this.method});
}
