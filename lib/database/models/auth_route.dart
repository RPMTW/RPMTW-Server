import "package:rpmtw_server/database/models/auth/user_role.dart";

class AuthConfig {
  final String? path;
  final UserRoleType role;

  AuthConfig({this.role = UserRoleType.general, this.path});
}
