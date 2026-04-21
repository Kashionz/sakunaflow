import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../shared/providers/database_provider.dart';
import 'router.dart';
import 'theme.dart';

class SakunaFlowApp extends StatelessWidget {
  const SakunaFlowApp({super.key, this.database, this.now, this.childOverride});

  final AppDatabase? database;
  final DateTime? now;
  final Widget? childOverride;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (database != null) databaseProvider.overrideWithValue(database!),
        if (now != null) currentDateProvider.overrideWithValue(now!),
      ],
      child: childOverride == null
          ? const _SakunaFlowRoot()
          : MaterialApp(
              title: 'SakunaFlow',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: Scaffold(body: childOverride),
            ),
    );
  }
}

class _SakunaFlowRoot extends ConsumerWidget {
  const _SakunaFlowRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      data: (_) => MaterialApp.router(
        title: 'SakunaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: createAppRouter(),
      ),
      loading: () => MaterialApp(
        title: 'SakunaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _StartupScreen(),
      ),
      error: (error, _) => MaterialApp(
        title: 'SakunaFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _StartupError(error: error),
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('啟動失敗：$error')));
  }
}
