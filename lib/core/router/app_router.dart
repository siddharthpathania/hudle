import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../features/announcements/presentation/approval_queue_screen.dart';
import '../../features/announcements/presentation/create_announcement_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/group_settings_screen.dart';
import '../../features/groups/presentation/groups_list_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/onboarding_screen.dart';
import '../../features/shell/splash_screen.dart';
import '../../features/tasks/presentation/create_edit_task_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../services/supabase_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: _redirect,
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: '/auth/profile-setup',
      builder: (_, __) => const ProfileSetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(path: '/groups', builder: (_, __) => const GroupsListScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/groups/:groupId',
      builder: (_, state) =>
          GroupDetailScreen(groupId: state.pathParameters['groupId']!),
      routes: [
        GoRoute(
          path: 'tasks/new',
          builder: (_, state) => CreateEditTaskScreen(
            groupId: state.pathParameters['groupId']!,
          ),
        ),
        GoRoute(
          path: 'tasks/:taskId',
          builder: (_, state) =>
              TaskDetailScreen(taskId: state.pathParameters['taskId']!),
        ),
        GoRoute(
          path: 'settings',
          builder: (_, state) =>
              GroupSettingsScreen(groupId: state.pathParameters['groupId']!),
        ),
        GoRoute(
          path: 'announcements/new',
          builder: (_, state) => CreateAnnouncementScreen(
            groupId: state.pathParameters['groupId']!,
          ),
        ),
        GoRoute(
          path: 'announcements/queue',
          builder: (_, state) => ApprovalQueueScreen(
            groupId: state.pathParameters['groupId']!,
          ),
        ),
      ],
    ),
  ],
);

String? _redirect(BuildContext context, GoRouterState state) {
  supa.Session? session;
  try {
    session = SupabaseService.currentSession;
  } catch (_) {
    // Supabase not initialised (no env) — let splash handle.
    return null;
  }
  final isAuth = session != null;
  final loc = state.matchedLocation;
  final isAuthRoute = loc.startsWith('/auth');
  final isSplashOrOnboarding = loc == '/splash' || loc == '/onboarding';

  if (!isAuth && !isAuthRoute && !isSplashOrOnboarding) {
    return '/auth/login';
  }
  if (isAuth && (isAuthRoute || loc == '/splash')) {
    return '/dashboard';
  }
  return null;
}
