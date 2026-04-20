import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/app.dart';
import 'package:sakunaflow/data/local/database.dart';

void main() {
  late AppDatabase database;
  final today = DateTime(2026, 4, 20, 9);

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.seedDemoData(now: today);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('renders desktop shell with today tasks and navigation', (
    tester,
  ) async {
    await tester.pumpWidget(SakunaFlowApp(database: database, now: today));
    await tester.pumpAndSettle();

    expect(find.text('SakunaFlow'), findsWidgets);
    expect(find.text('今日'), findsWidgets);
    expect(find.text('實作 SyncService push 機制'), findsOneWidget);
    expect(find.text('修復番茄鐘背景計時 bug'), findsOneWidget);

    await tester.tap(find.text('番茄鐘').first);
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('開始專注'), findsOneWidget);

    await tester.tap(find.text('專案').first);
    await tester.pumpAndSettle();

    expect(find.text('個人網站 v3'), findsWidgets);
    expect(find.text('HomeServer'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('quick add creates a task in the local database', (tester) async {
    await tester.pumpWidget(SakunaFlowApp(database: database, now: today));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('quick-add-task-field')),
      '整理 Phase 1 驗收清單',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('整理 Phase 1 驗收清單'), findsOneWidget);
    final todayTasks = await database.getTodayTasks(today);
    expect(todayTasks.map((task) => task.title), contains('整理 Phase 1 驗收清單'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
