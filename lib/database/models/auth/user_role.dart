import "package:rpmtw_server/database/models/auth/user_role_permission.dart";

/// Role of the user.
/// Used to determine which permissions a user has
class UserRole {
  final List<UserRoleType> roles;

  /// Bot type
  /// This field is not null when the user role is bot
  final BotType? botType;

  UserRolePermission get permission => UserRolePermission(roles);

  const UserRole({this.roles = const [UserRoleType.general], this.botType});

  Map<String, dynamic> toMap() {
    return {
      "roles": roles.map((x) => x.name).toList(),
      "botType": botType?.name,
    };
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      roles: List<UserRoleType>.from(
          map["roles"]?.map((x) => UserRoleType.values.byName(x))),
      botType:
          map["botType"] != null ? BotType.values.byName(map["botType"]) : null,
    );
  }

  UserRole copyWith({
    List<UserRoleType>? roles,
    BotType? botType,
  }) {
    return UserRole(
      roles: roles ?? this.roles,
      botType: botType ?? this.botType,
    );
  }
}

enum UserRoleType {
  // all permissions
  admin,
  bot,
  // can create/edit source files/texts
  translationManager,
  wikiManager,
  // can delete cosmic chat messages, ban cosmic chat users
  cosmicChatManager,
  // general user
  general,
}

extension UserRoleTypeExtension on UserRoleType {
  int get id {
    switch (this) {
      case UserRoleType.admin:
        return 6;
      case UserRoleType.bot:
        return 5;
      case UserRoleType.translationManager:
        return 4;
      case UserRoleType.wikiManager:
        return 3;
      case UserRoleType.cosmicChatManager:
        return 2;
      case UserRoleType.general:
        return 1;
    }
  }
}

enum BotType { discord, githubAction }
