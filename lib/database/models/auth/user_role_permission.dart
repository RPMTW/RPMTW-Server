import "package:rpmtw_server/database/models/auth/user_role.dart";

class UserRolePermission {
  final List<UserRoleType> _roles;

  bool get general => hasPermission(UserRoleType.general) || _roles.isEmpty;
  bool get admin => hasPermission(UserRoleType.admin);
  bool get bot => hasPermission(UserRoleType.bot);
  bool get translationManager => hasPermission(UserRoleType.translationManager);
  bool get wikiManager => hasPermission(UserRoleType.wikiManager);
  const UserRolePermission(this._roles);

  bool hasPermission(UserRoleType role) {
    return _roles.any((e) => e.id >= role.id);
  }
}
