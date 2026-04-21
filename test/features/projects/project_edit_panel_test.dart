import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/app.dart';
import 'package:sakunaflow/data/local/database.dart';
import 'package:sakunaflow/features/projects/project_edit_panel.dart';

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

  testWidgets('autosaves project text fields', (tester) async {
    final project = (await tester.runAsync(
      () => database.watchProjects().first,
    ))!.first;

    await tester.pumpWidget(
      SakunaFlowApp(
        database: database,
        now: now,
        childOverride: ProjectEditPanel(project: project, onClose: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('project-edit-name')),
      '更新後專案',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('project-edit-description')),
      '新的專案描述',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    final updated = (await tester.runAsync(
      () => database.getProject(project.id),
    ))!;
    expect(updated.name, '更新後專案');
    expect(updated.description, '新的專案描述');
  });

  testWidgets('autosaves project color status tags and git url', (
    tester,
  ) async {
    final project = (await tester.runAsync(
      () => database.watchProjects().first,
    ))!.first;

    await tester.pumpWidget(
      SakunaFlowApp(
        database: database,
        now: now,
        childOverride: ProjectEditPanel(project: project, onClose: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('project-edit-color-#dd5b00')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('project-edit-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暫停').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('project-edit-tech-tags')),
      'Flutter, Drift',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('project-edit-git-url')),
      'https://github.com/example/sakunaflow',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    final updated = (await tester.runAsync(
      () => database.getProject(project.id),
    ))!;
    expect(updated.color, '#dd5b00');
    expect(updated.status, ProjectStatus.paused.name);
    expect(updated.techTags, const ['Flutter', 'Drift']);
    expect(updated.gitUrl, 'https://github.com/example/sakunaflow');
  });
}
