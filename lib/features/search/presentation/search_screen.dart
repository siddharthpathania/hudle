import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../domain/search_models.dart';
import '../domain/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Search tasks, announcements, groups…',
            border: InputBorder.none,
            hintStyle:
                GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _ctrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Builder(builder: (_) {
        if (query.trim().length < 2) {
          return const _Prompt();
        }
        return results.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed: $e',
                  style: const TextStyle(color: AppColors.hudleRose)),
            ),
          ),
          data: (hits) {
            if (hits.isEmpty) return const _NoResults();
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: hits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _HitTile(hit: hits[i]),
            );
          },
        );
      }),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});
  final SearchHit hit;

  IconData get _icon => switch (hit.kind) {
        SearchKind.task => Icons.task_alt_rounded,
        SearchKind.announcement => Icons.campaign_rounded,
        SearchKind.group => Icons.groups_rounded,
      };
  Color get _color => switch (hit.kind) {
        SearchKind.task => AppColors.emberOrange,
        SearchKind.announcement => AppColors.amberGold,
        SearchKind.group => AppColors.hudleTeal,
      };

  String get _kindLabel => switch (hit.kind) {
        SearchKind.task => 'Task',
        SearchKind.announcement => 'Announcement',
        SearchKind.group => 'Group',
      };

  void _navigate(BuildContext context) {
    switch (hit.kind) {
      case SearchKind.task:
        if (hit.groupId != null) {
          context.push('/groups/${hit.groupId}/tasks/${hit.id}');
        }
      case SearchKind.announcement:
        if (hit.groupId != null) {
          context.push('/groups/${hit.groupId}');
        }
      case SearchKind.group:
        context.push('/groups/${hit.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(UI.radiusSm),
          ),
          child: Icon(_icon, color: _color, size: 18),
        ),
        title: Text(
          hit.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          hit.groupName != null ? '$_kindLabel · ${hit.groupName}' : _kindLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () => _navigate(context),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 56, color: AppColors.hudleTeal),
            SizedBox(height: 12),
            Text('Search across everything'),
            SizedBox(height: 4),
            Text('Type at least 2 characters',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No results'),
          ],
        ),
      ),
    );
  }
}
