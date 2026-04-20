import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/data/local/database.dart';

void main() {
  late AppDatabase database;
  final frozenNow = DateTime(2026, 4, 20, 9);

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.seedDemoData(now: frozenNow);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds demo projects and default local preferences', () async {
    final projects = await database.watchProjects().first;
    final preferences = await database.getPreferences();

    expect(projects.map((project) => project.name), contains('SakunaFlow'));
    expect(projects.map((project) => project.name), contains('個人網站 v3'));
    expect(preferences.workDuration, 25);
    expect(preferences.shortBreakDuration, 5);
    expect(preferences.longBreakDuration, 15);
    expect(preferences.weekStartsOn, 1);
  });

  test(
    'today query includes overdue todo tasks and in-progress tasks',
    () async {
      final project = (await database.watchProjects().first).first;
      final overdue = await database.createTask(
        title: '修復番茄鐘背景計時 bug',
        projectId: project.id,
        priority: 0,
        dueDate: DateTime(2026, 4, 19),
        now: frozenNow,
      );
      final later = await database.createTask(
        title: '下週整理 release notes',
        projectId: project.id,
        dueDate: DateTime(2026, 4, 27),
        now: frozenNow,
      );
      await database.updateTaskStatus(
        later.id,
        TaskStatus.inProgress,
        now: frozenNow.add(const Duration(minutes: 3)),
      );

      final todayTasks = await database.watchTodayTasks(frozenNow).first;

      expect(todayTasks.map((task) => task.id), contains(overdue.id));
      expect(todayTasks.map((task) => task.id), contains(later.id));
    },
  );

  test(
    'completing a task records completedAt and hides it from today',
    () async {
      final task = await database.createTask(
        title: '完成 Drift schema migration',
        dueDate: frozenNow,
        now: frozenNow,
      );

      await database.completeTask(
        task.id,
        now: frozenNow.add(const Duration(hours: 1)),
      );

      final updated = await database.getTask(task.id);
      final todayTasks = await database.watchTodayTasks(frozenNow).first;

      expect(updated.status, TaskStatus.done.name);
      expect(updated.completedAt, frozenNow.add(const Duration(hours: 1)));
      expect(todayTasks.map((task) => task.id), isNot(contains(task.id)));
    },
  );

  test(
    'completed work pomodoro inserts append-only session and increments task actual count',
    () async {
      final task = await database.createTask(
        title: '實作 SyncService push 機制',
        estimatedPomodoros: 3,
        dueDate: frozenNow,
        now: frozenNow,
      );

      final session = await database.addPomodoroSession(
        taskId: task.id,
        startedAt: frozenNow,
        endedAt: frozenNow.add(const Duration(minutes: 25)),
        durationMinutes: 25,
        type: PomodoroSessionType.work,
        completed: true,
        note: '完成本地 queue API 草稿',
      );

      final updatedTask = await database.getTask(task.id);
      final sessions = await database.sessionsForDay(frozenNow);

      expect(updatedTask.actualPomodoros, 1);
      expect(sessions.single.id, session.id);
      expect(sessions.single.note, '完成本地 queue API 草稿');
      expect(sessions.single.completed, isTrue);
    },
  );
}
