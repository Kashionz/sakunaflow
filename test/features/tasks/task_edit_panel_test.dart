import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/app.dart';
import 'package:sakunaflow/data/local/database.dart';
import 'package:sakunaflow/features/tasks/task_edit_panel.dart';

void main() {
  late AppDatabase database;
  final now = DateTime(2026, 4, 20, 9);

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.seedDemoData(now: now);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('autosaves task title and description', (tester) async {
    final task = (await tester.runAsync(
      () => database.getTodayTasks(now),
    ))!.first;
    final projects = (await tester.runAsync(
      () => database.watchProjects().first,
    ))!;

    await tester.pumpWidget(
      SakunaFlowApp(
        database: database,
        now: now,
        childOverride: TaskEditPanel(
          task: task,
          projects: projects,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('task-edit-title')),
      '更新後的任務',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('task-edit-description')),
      '新的任務描述',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    final updated = (await tester.runAsync(() => database.getTask(task.id)))!;
    expect(updated.title, '更新後的任務');
    expect(updated.description, '新的任務描述');
    expect(find.text('已儲存'), findsOneWidget);
  });

  testWidgets(
    'autosaves task project, priority, estimate, due date, and tags',
    (tester) async {
      final task = (await tester.runAsync(
        () => database.getTodayTasks(now),
      ))!.first;
      final projects = (await tester.runAsync(
        () => database.watchProjects().first,
      ))!;

      await tester.pumpWidget(
        SakunaFlowApp(
          database: database,
          now: now,
          childOverride: TaskEditPanel(
            task: task,
            projects: projects,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('task-edit-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(projects[1].name).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('task-edit-priority')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('P0').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('task-edit-estimate')),
        '5',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('task-edit-tags')),
        'Flutter, Drift',
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      final updated = (await tester.runAsync(() => database.getTask(task.id)))!;
      expect(updated.projectId, projects[1].id);
      expect(updated.priority, 0);
      expect(updated.estimatedPomodoros, 5);
      expect(updated.tags, const ['Flutter', 'Drift']);
    },
  );

  testWidgets('clears task due date from the panel', (tester) async {
    final task = (await tester.runAsync(
      () => database.getTodayTasks(now),
    ))!.first;
    final projects = (await tester.runAsync(
      () => database.watchProjects().first,
    ))!;

    await tester.pumpWidget(
      SakunaFlowApp(
        database: database,
        now: now,
        childOverride: TaskEditPanel(
          task: task,
          projects: projects,
          onClose: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('task-edit-clear-due-date')));
    await tester.pumpAndSettle();

    final updated = (await tester.runAsync(() => database.getTask(task.id)))!;
    expect(updated.dueDate, isNull);
  });
}
