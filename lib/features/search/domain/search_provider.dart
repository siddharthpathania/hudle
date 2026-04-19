import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/search_repository.dart';
import 'search_models.dart';

final searchQueryProvider = StateProvider<String>((_) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchHit>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().length < 2) return const [];
  return ref.read(searchRepositoryProvider).search(q);
});
