import "package:rpmtw_server/database/models/auth/user_role.dart";

class UserRolePermission {
  final List<UserRoleType> _roles;

  bool get general => _hasPermission(UserRoleType.general) || _roles.isEmpty;
  bool get admin => _hasPermission(UserRoleType.admin);
  bool get bot => _hasPermission(UserRoleType.bot);
  bool get translationManager =>
      _hasPermission(UserRoleType.translationManager);
  bool get wikiManager => _hasPermission(UserRoleType.wikiManager);
  bool get cosmicChatManager => _hasPermission(UserRoleType.cosmicChatManager);

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

  bool _hasPermission(UserRoleType role) {
    return _roles.any((e) => e.id >= role.id);
  }
}
