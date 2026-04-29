import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../auth/data/auth_repository.dart';
import '../../tasks/domain/task_model.dart';
import '../../tasks/domain/tasks_provider.dart';
import '../../tasks/presentation/widgets/task_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TaskDateFilter _filter = TaskDateFilter.all;
  bool _doneOnly = false;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd().format(DateTime.now());
    final all = ref.watch(dashboardTasksProvider(TaskDateFilter.all));
    final filtered = _doneOnly
        ? all
        : ref.watch(dashboardTasksProvider(_filter));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardTasksProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(date,
                            style: GoogleFonts.dmSans(
                                color: AppColors.mutedText(context))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => _openSettings(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              all.when(
                loading: () => const Row(
                  children: [
                    Expanded(
                        child: ShimmerBox(height: 88, radius: UI.radiusLg)),
                    SizedBox(width: 12),
                    Expanded(
                        child: ShimmerBox(height: 88, radius: UI.radiusLg)),
                    SizedBox(width: 12),
                    Expanded(
                        child: ShimmerBox(height: 88, radius: UI.radiusLg)),
                  ],
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (tasks) {
                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);
                  final todayEnd = todayStart.add(const Duration(days: 1));
                  final weekStart =
                      todayStart.subtract(const Duration(days: 7));

                  final today = tasks
                      .where((t) =>
                          t.dueAt != null &&
                          !t.dueAt!.isBefore(todayStart) &&
                          t.dueAt!.isBefore(todayEnd) &&
                          !t.isDone)
                      .length;
                  final overdue = tasks.where((t) => t.isOverdue).length;
                  final doneThisWeek = tasks
                      .where((t) =>
                          t.isDone &&
                          t.createdAt != null &&
                          t.createdAt!.isAfter(weekStart))
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Today',
                          value: '$today',
                          color: AppColors.emberOrange,
                          selected: !_doneOnly &&
                              _filter == TaskDateFilter.today,
                          onTap: () => setState(() {
                            _filter = TaskDateFilter.today;
                            _doneOnly = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Overdue',
                          value: '$overdue',
                          color: AppColors.hudleRose,
                          selected: !_doneOnly &&
                              _filter == TaskDateFilter.overdue,
                          onTap: () => setState(() {
                            _filter = TaskDateFilter.overdue;
                            _doneOnly = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Done this week',
                          value: '$doneThisWeek',
                          color: AppColors.hudleTeal,
                          selected: _doneOnly,
                          onTap: () => setState(() {
                            _doneOnly = true;
                            _filter = TaskDateFilter.all;
                          }),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    _doneOnly ? 'Done this week' : 'Your tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_doneOnly || _filter != TaskDateFilter.all)
                    TextButton(
                      onPressed: () => setState(() {
                        _filter = TaskDateFilter.all;
                        _doneOnly = false;
                      }),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              filtered.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: UI.space8),
                      child: ShimmerBox(height: 90, radius: UI.radiusLg),
                    ),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Failed to load: $e',
                        style: const TextStyle(color: AppColors.hudleRose)),
                  ),
                ),
                data: (list) {
                  final visible = _doneOnly
                      ? list.where((t) {
                          if (!t.isDone) return false;
                          final ref = t.createdAt;
                          if (ref == null) return false;
                          return ref.isAfter(
                              DateTime.now().subtract(const Duration(days: 7)));
                        }).toList()
                      : list;
                  if (visible.isEmpty) return const _EmptyDashboard();
                  return Column(
                    children: [
                      for (final t in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: UI.space8),
                          child: TaskCard(task: t, showGroup: true),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UI.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(UI.radiusLg),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.8 : 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text('Theme',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeControllerProvider.notifier).set(s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.hudleRose),
              title: const Text('Sign out'),
              onTap: () async {
                final nav = Navigator.of(context);
                await ref.read(authRepositoryProvider).signOut();
                if (nav.canPop()) nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppColors.hudleTeal),
            const SizedBox(height: 12),
            Text(
              'All clear! No tasks pending',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tasks from your groups will appear here',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.mutedText(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
