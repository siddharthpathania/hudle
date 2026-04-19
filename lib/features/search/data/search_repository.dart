import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/search_models.dart';

final searchRepositoryProvider =
    Provider<SearchRepository>((_) => SearchRepository());

class SearchRepository {
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final results = await Future.wait([
      _searchTasks(q),
      _searchAnnouncements(q),
      _searchGroups(q),
    ]);
    final hits = [...results[0], ...results[1], ...results[2]];
    hits.sort((a, b) {
      final ac = a.createdAt ?? DateTime(1970);
      final bc = b.createdAt ?? DateTime(1970);
      return bc.compareTo(ac);
    });
    return hits;
  }

  Future<List<SearchHit>> _searchTasks(String q) async {
    final data = await SupabaseService.client
        .from('tasks')
        .select('id, title, description, group_id, created_at, groups(name)')
        .textSearch('search_vector', q, config: 'english')
        .limit(25) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return SearchHit(
        id: m['id'] as String,
        kind: SearchKind.task,
        title: m['title'] as String,
        subtitle: m['description'] as String?,
        groupId: m['group_id'] as String?,
        groupName: (m['groups'] as Map?)?['name'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );
    }).toList();
  }

  Future<List<SearchHit>> _searchAnnouncements(String q) async {
    final data = await SupabaseService.client
        .from('announcements')
        .select('id, content, group_id, created_at, groups(name)')
        .eq('status', 'approved')
        .textSearch('search_vector', q, config: 'english')
        .limit(25) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final content = m['content'] as String;
      return SearchHit(
        id: m['id'] as String,
        kind: SearchKind.announcement,
        title: content.length > 80 ? '${content.substring(0, 80)}…' : content,
        subtitle: null,
        groupId: m['group_id'] as String?,
        groupName: (m['groups'] as Map?)?['name'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );
    }).toList();
  }

  Future<List<SearchHit>> _searchGroups(String q) async {
    final data = await SupabaseService.client
        .from('groups')
        .select('id, name, description, created_at')
        .ilike('name', '%$q%')
        .limit(15) as List;
    return data.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return SearchHit(
        id: m['id'] as String,
        kind: SearchKind.group,
        title: m['name'] as String,
        subtitle: m['description'] as String?,
        groupId: m['id'] as String,
        createdAt: m['created_at'] != null
            ? DateTime.tryParse(m['created_at'] as String)
            : null,
      );
    }).toList();
  }
}
