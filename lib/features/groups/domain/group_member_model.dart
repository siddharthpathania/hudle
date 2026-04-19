enum GroupRole { superAdmin, admin, member }

extension GroupRoleX on GroupRole {
  String get wire => switch (this) {
        GroupRole.superAdmin => 'super_admin',
        GroupRole.admin => 'admin',
        GroupRole.member => 'member',
      };
  String get label => switch (this) {
        GroupRole.superAdmin => 'Super admin',
        GroupRole.admin => 'Admin',
        GroupRole.member => 'Member',
      };
  static GroupRole fromWire(String? v) => switch (v) {
        'super_admin' => GroupRole.superAdmin,
        'admin' => GroupRole.admin,
        _ => GroupRole.member,
      };
}

class GroupMember {
  GroupMember({
    required this.userId,
    required this.role,
    required this.isBanned,
    this.displayName,
    this.avatarUrl,
    this.joinedAt,
  });

  final String userId;
  final GroupRole role;
  final bool isBanned;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final u = json['users'] as Map?;
    return GroupMember(
      userId: json['user_id'] as String,
      role: GroupRoleX.fromWire(json['role'] as String?),
      isBanned: (json['is_banned'] as bool?) ?? false,
      displayName: u?['display_name'] as String?,
      avatarUrl: u?['avatar_url'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }
}

class GroupInvite {
  GroupInvite({
    required this.id,
    required this.token,
    required this.useCount,
    this.maxUses,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String token;
  final int useCount;
  final int? maxUses;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory GroupInvite.fromJson(Map<String, dynamic> json) => GroupInvite(
        id: json['id'] as String,
        token: json['token'] as String,
        useCount: (json['use_count'] as int?) ?? 0,
        maxUses: json['max_uses'] as int?,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
