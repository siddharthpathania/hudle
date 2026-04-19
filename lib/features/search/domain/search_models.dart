enum SearchKind { task, announcement, group }

class SearchHit {
  SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.groupId,
    this.groupName,
    this.createdAt,
  });

  final String id;
  final SearchKind kind;
  final String title;
  final String? subtitle;
  final String? groupId;
  final String? groupName;
  final DateTime? createdAt;
}
