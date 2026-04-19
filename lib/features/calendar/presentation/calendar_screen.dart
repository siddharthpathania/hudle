import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ui_constants.dart';
import '../../tasks/domain/task_model.dart';
import '../../tasks/domain/tasks_provider.dart';
import '../../tasks/presentation/widgets/task_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<Task>> _groupByDay(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    for (final t in tasks) {
      if (t.dueAt == null) continue;
      final k = _key(t.dueAt!);
      map.putIfAbsent(k, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(dashboardTasksProvider(TaskDateFilter.all));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: false,
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load: $e',
                style: const TextStyle(color: AppColors.hudleRose)),
          ),
        ),
        data: (tasks) {
          final byDay = _groupByDay(tasks);
          final selected = byDay[_key(_selectedDay)] ?? const [];

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: TableCalendar<Task>(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    calendarFormat: _format,
                    eventLoader: (d) => byDay[_key(d)] ?? const [],
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.twoWeeks: '2 Weeks',
                      CalendarFormat.week: 'Week',
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.emberOrange.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.emberOrange,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.hudleTeal,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 5,
                      markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonShowsNext: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(UI.radiusSm),
                        border: Border.all(color: AppColors.inkBorder),
                      ),
                      formatButtonTextStyle: GoogleFonts.dmSans(fontSize: 12),
                    ),
                    onDaySelected: (sel, foc) => setState(() {
                      _selectedDay = sel;
                      _focusedDay = foc;
                    }),
                    onFormatChanged: (f) => setState(() => _format = f),
                    onPageChanged: (foc) => _focusedDay = foc,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Text(
                      _prettyDay(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${selected.length} task${selected.length == 1 ? '' : 's'}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selected.isEmpty
                    ? const _EmptyDay()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: selected.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: UI.space8),
                        itemBuilder: (_, i) =>
                            TaskCard(task: selected[i], showGroup: true),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _prettyDay(DateTime d) {
    final now = DateTime.now();
    if (isSameDay(d, now)) return 'Today';
    if (isSameDay(d, now.add(const Duration(days: 1)))) return 'Tomorrow';
    if (isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded,
                size: 64, color: AppColors.hudleTeal),
            const SizedBox(height: 12),
            const Text('No tasks for this day'),
            const SizedBox(height: 4),
            Text(
              'Pick another day or add a new task',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
