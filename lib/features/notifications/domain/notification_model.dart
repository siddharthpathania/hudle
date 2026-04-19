class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.isRead,
    this.body,
    this.entityType,
    this.entityId,
    this.groupId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? entityType;
  final String? entityId;
  final String? groupId;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        entityType: json['entity_type'] as String?,
        entityId: json['entity_id'] as String?,
        groupId: json['group_id'] as String?,
        isRead: (json['is_read'] as bool?) ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
