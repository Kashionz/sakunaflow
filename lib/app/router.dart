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
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/pomodoro',
            builder: (context, state) => const PomodoroScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':projectId',
                builder: (context, state) => ProjectsScreen(
                  projectId: state.pathParameters['projectId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('找不到頁面：${state.uri}'))),
  );
}
