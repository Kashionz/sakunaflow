import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/theme.dart';
import 'package:sakunaflow/data/local/database.dart';
import 'package:sakunaflow/shared/widgets/task_item.dart';

void main() {
  final now = DateTime(2026, 4, 20, 9);

  Task task({required TaskStatus status}) {
    return Task(
      id: 'task-animation',
      userId: localUserId,
      title: '確認勾選動畫',
      priority: 2,
      dueDate: now,
      estimatedPomodoros: 0,
      actualPomodoros: 0,
      status: status.name,
      tags: const [],
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      completedAt: status == TaskStatus.done ? now : null,
    );
  }

  testWidgets('done task title is struck through and checkbox is animated', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TaskItem(
            task: task(status: TaskStatus.done),
            projects: const [],
            onToggleDone: (_) async {},
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(find.text('確認勾選動畫'));
    expect(titleText.style?.decoration, TextDecoration.lineThrough);
    expect(find.byType(AnimatedContainer), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
  });

  testWidgets('checkbox animates to checked immediately on tap', (
    tester,
  ) async {
    bool? toggled;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TaskItem(
            task: task(status: TaskStatus.todo),
            projects: const [],
            onToggleDone: (done) async => toggled = done,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(toggled, isTrue);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('edit button fires without toggling checkbox', (tester) async {
    var editCount = 0;
    var toggleCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TaskItem(
            task: task(status: TaskStatus.todo),
            projects: const [],
            onToggleDone: (_) async => toggleCount++,
            onEdit: () => editCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('task-edit-task-animation')));
    await tester.pump();

    expect(editCount, 1);
    expect(toggleCount, 0);
  });
}
