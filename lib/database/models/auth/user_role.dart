import 'package:rpmtw_server/database/models/auth/user_role_permission.dart';

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
      'roles': roles.map((x) => x.name).toList(),
      'botType': botType?.name,
    };
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      roles: List<UserRoleType>.from(
          map['roles']?.map((x) => UserRoleType.values.byName(x))),
      botType:
          map['botType'] != null ? BotType.values.byName(map['botType']) : null,
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
  // can delete universe chat messages, ban universe chat users
  universeChatManager,
  // general user
  general
}

enum BotType { discord, githubAction }
