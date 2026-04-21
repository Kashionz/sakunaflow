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
    'completing a today task records completedAt and keeps it in today',
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
      expect(todayTasks.map((task) => task.id), contains(task.id));
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

  test('updateTask updates editable fields and updatedAt', () async {
    final project = (await database.watchProjects().first).first;
    final task = await database.createTask(
      title: '舊任務',
      description: '舊描述',
      projectId: project.id,
      priority: 2,
      estimatedPomodoros: 1,
      dueDate: frozenNow,
      tags: const ['Flutter'],
      now: frozenNow,
    );
    final nextProject = (await database.watchProjects().first)[1];
    final savedAt = frozenNow.add(const Duration(minutes: 7));
    final nextDueDate = DateTime(2026, 4, 25);

    await database.updateTask(
      task.id,
      title: '  新任務  ',
      description: '  新描述  ',
      projectId: nextProject.id,
      priority: 0,
      dueDate: nextDueDate,
      estimatedPomodoros: 4,
      tags: const [' Dart ', '', 'SQLite'],
      now: savedAt,
    );

    final updated = await database.getTask(task.id);

    expect(updated.title, '新任務');
    expect(updated.description, '新描述');
    expect(updated.projectId, nextProject.id);
    expect(updated.priority, 0);
    expect(updated.dueDate, nextDueDate);
    expect(updated.estimatedPomodoros, 4);
    expect(updated.tags, const ['Dart', 'SQLite']);
    expect(updated.updatedAt, savedAt);
    expect(updated.status, task.status);
    expect(updated.completedAt, task.completedAt);
  });

  test(
    'updateTask stores blank optional text as null and can clear project and due date',
    () async {
      final project = (await database.watchProjects().first).first;
      final task = await database.createTask(
        title: '可清空欄位',
        description: '會被清空',
        projectId: project.id,
        dueDate: frozenNow,
        now: frozenNow,
      );

      await database.updateTask(
        task.id,
        description: '   ',
        clearProject: true,
        clearDueDate: true,
        now: frozenNow.add(const Duration(minutes: 1)),
      );

      final updated = await database.getTask(task.id);

      expect(updated.description, isNull);
      expect(updated.projectId, isNull);
      expect(updated.dueDate, isNull);
    },
  );

  test('updateTask rejects empty title and invalid priority', () async {
    final task = await database.createTask(title: '合法任務', now: frozenNow);

    expect(
      () => database.updateTask(task.id, title: '   ', now: frozenNow),
      throwsArgumentError,
    );
    expect(
      () => database.updateTask(task.id, priority: 4, now: frozenNow),
      throwsArgumentError,
    );
    expect(
      () =>
          database.updateTask(task.id, estimatedPomodoros: -1, now: frozenNow),
      throwsArgumentError,
    );
  });

  test('updateProject updates editable fields and updatedAt', () async {
    final project = (await database.watchProjects().first).first;
    final savedAt = frozenNow.add(const Duration(minutes: 12));

    await database.updateProject(
      project.id,
      name: '  新專案  ',
      description: '  新描述  ',
      color: '#dd5b00',
      status: ProjectStatus.paused,
      techTags: const [' Flutter ', '', 'Drift'],
      gitUrl: '  https://github.com/example/sakunaflow  ',
      now: savedAt,
    );

    final updated = await database.getProject(project.id);

    expect(updated.name, '新專案');
    expect(updated.description, '新描述');
    expect(updated.color, '#dd5b00');
    expect(updated.status, ProjectStatus.paused.name);
    expect(updated.techTags, const ['Flutter', 'Drift']);
    expect(updated.gitUrl, 'https://github.com/example/sakunaflow');
    expect(updated.updatedAt, savedAt);
  });

  test('updateProject stores blank optional text as null', () async {
    final project = (await database.watchProjects().first).first;

    await database.updateProject(
      project.id,
      description: '   ',
      gitUrl: '   ',
      now: frozenNow.add(const Duration(minutes: 2)),
    );

    final updated = await database.getProject(project.id);

    expect(updated.description, isNull);
    expect(updated.gitUrl, isNull);
  });

  test('updateProject rejects empty name and unsupported color', () async {
    final project = (await database.watchProjects().first).first;

    expect(
      () => database.updateProject(project.id, name: '   ', now: frozenNow),
      throwsArgumentError,
    );
    expect(
      () =>
          database.updateProject(project.id, color: '#123456', now: frozenNow),
      throwsArgumentError,
    );
  });
}
