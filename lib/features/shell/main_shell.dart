import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../notifications/domain/notifications_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  static const _tabs = <({IconData icon, String label, String path})>[
    (icon: Icons.home_rounded, label: 'Home', path: '/dashboard'),
    (icon: Icons.group_rounded, label: 'Groups', path: '/groups'),
    (icon: Icons.calendar_month_rounded, label: 'Calendar', path: '/calendar'),
    (icon: Icons.search_rounded, label: 'Search', path: '/search'),
    (icon: Icons.notifications_rounded, label: 'Alerts', path: '/notifications'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);
    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i].path);
        },
        items: [
          for (var i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: i == 4
                  ? _BadgedIcon(icon: _tabs[i].icon, count: unread)
                  : Icon(_tabs[i].icon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: const BoxDecoration(
              color: AppColors.hudleRose,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
