import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/theme.dart';
import 'package:sakunaflow/shared/widgets/debounced_autosave_field.dart';
import 'package:sakunaflow/shared/widgets/edit_panel_scaffold.dart';

void main() {
  Widget host({
    required String initialValue,
    required Future<void> Function(String value) onSave,
    void Function(EditSaveStatus status, String? message)? onStatusChanged,
    bool isRequired = false,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: DebouncedAutosaveField(
          key: const ValueKey('field'),
          label: '標題',
          initialValue: initialValue,
          isRequired: isRequired,
          debounceDuration: const Duration(milliseconds: 500),
          onSave: onSave,
          onStatusChanged: onStatusChanged,
        ),
      ),
    );
  }

  testWidgets('saves text after debounce', (tester) async {
    final saved = <String>[];
    final statuses = <EditSaveStatus>[];

    await tester.pumpWidget(
      host(
        initialValue: '舊值',
        onSave: (value) async => saved.add(value),
        onStatusChanged: (status, _) => statuses.add(status),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '新值');
    await tester.pump(const Duration(milliseconds: 499));
    expect(saved, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(saved, const ['新值']);
    expect(statuses, contains(EditSaveStatus.saving));
    expect(statuses, contains(EditSaveStatus.saved));
  });

  testWidgets('required field does not save blank text', (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(
      host(
        initialValue: '舊值',
        isRequired: true,
        onSave: (_) async => saveCount++,
      ),
    );

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump(const Duration(milliseconds: 600));

    expect(saveCount, 0);
    expect(find.text('必填'), findsOneWidget);
  });

  testWidgets('reports failed save and keeps input', (tester) async {
    EditSaveStatus? status;
    String? message;

    await tester.pumpWidget(
      host(
        initialValue: '舊值',
        onSave: (_) async => throw Exception('db down'),
        onStatusChanged: (nextStatus, nextMessage) {
          status = nextStatus;
          message = nextMessage;
        },
      ),
    );

    await tester.enterText(find.byType(TextFormField), '新值');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(status, EditSaveStatus.failed);
    expect(message, contains('Exception'));
    expect(find.text('新值'), findsOneWidget);
  });
}
