import "package:rpmtw_server/database/models/auth/user_role.dart";

class UserRolePermission {
  final List<UserRoleType> _roles;

  bool get general => _roles.isEmpty || _hasPermission(UserRoleType.general);
  bool get admin => _hasPermission(UserRoleType.admin);
  bool get bot => _hasPermission(UserRoleType.bot);
  bool get translationManager =>
      _hasPermission(UserRoleType.translationManager, byID: false);
  bool get wikiManager => _hasPermission(UserRoleType.wikiManager, byID: false);
  bool get cosmicChatManager =>
      _hasPermission(UserRoleType.cosmicChatManager, byID: false);

  const UserRolePermission(this._roles);

  bool hasPermission(UserRoleType role) {
    switch (role) {
      case UserRoleType.admin:
        return admin;
      case UserRoleType.bot:
        return bot;
      case UserRoleType.translationManager:
        return translationManager;
      case UserRoleType.wikiManager:
        return wikiManager;
      case UserRoleType.cosmicChatManager:
        return cosmicChatManager;
      case UserRoleType.general:
        return general;
    }
  }

  bool _hasPermission(UserRoleType role, {bool byID = true}) {
    if (byID) {
      return _roles.any((r) => r.id >= role.id);
    } else {
      return _roles.any((r) => r == role);
    }
  }
}
