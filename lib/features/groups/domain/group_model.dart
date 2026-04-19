class Group {
  Group({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.isPublic = false,
    this.memberCount,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final bool isPublic;
  final int? memberCount;
  final DateTime? createdAt;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isPublic: (json['is_public'] as bool?) ?? false,
        memberCount: _extractCount(json['group_members']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  static int? _extractCount(dynamic raw) {
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return (raw.first as Map)['count'] as int?;
    }
    return null;
  }
}
