class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: (json['display_name'] as String?) ?? '',
        username: (json['username'] as String?) ?? '',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
  }) =>
      UserProfile(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        createdAt: createdAt,
      );
}
