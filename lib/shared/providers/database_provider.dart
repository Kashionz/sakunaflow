import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';

final currentDateProvider = Provider<DateTime>((ref) => DateTime.now());

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final appStartupProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(databaseProvider);
  await database.seedDemoData(now: ref.watch(currentDateProvider));
});

final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(databaseProvider).watchProjects();
});

final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(databaseProvider).watchTasks();
});

final todayTasksProvider = StreamProvider<List<Task>>((ref) {
  final today = ref.watch(currentDateProvider);
  return ref.watch(databaseProvider).watchTodayTasks(today);
});

final preferencesProvider = StreamProvider<UserPreference>((ref) {
  return ref.watch(databaseProvider).watchPreferences();
});
