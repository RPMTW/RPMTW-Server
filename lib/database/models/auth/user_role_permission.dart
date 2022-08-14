import 'package:rpmtw_server/database/models/auth/user_role.dart';

class UserRolePermission {
  final List<UserRoleType> _roles;

  const UserRolePermission(this._roles);

  bool hasPermission(UserRoleType role) {
    // if the user has admin permission, will have all permissions
    if (_roles.any((r) => r == UserRoleType.admin)) return true;

    return _roles.any((r) => r == role);
  }
}
