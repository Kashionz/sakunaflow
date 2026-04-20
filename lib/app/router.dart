import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/pomodoro/pomodoro_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tasks/today_screen.dart';
import '../shared/widgets/app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) =>
                _shellPage(state, const TodayScreen()),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) =>
                _shellPage(state, const CalendarScreen()),
          ),
          GoRoute(
            path: '/pomodoro',
            pageBuilder: (context, state) =>
                _shellPage(state, const PomodoroScreen()),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) =>
                _shellPage(state, const ProjectsScreen()),
            routes: [
              GoRoute(
                path: ':projectId',
                pageBuilder: (context, state) => _shellPage(
                  state,
                  ProjectsScreen(projectId: state.pathParameters['projectId']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) =>
                _shellPage(state, const StatsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _shellPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('找不到頁面：${state.uri}'))),
  );
}

Page<void> _shellPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}
