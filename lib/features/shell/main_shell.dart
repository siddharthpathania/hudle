import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => context.go(_tabs[i].path),
        items: [
          for (final t in _tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
