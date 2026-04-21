import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/app/theme.dart';
import 'package:sakunaflow/shared/widgets/edit_panel_scaffold.dart';

void main() {
  Widget host({required Size size}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
          body: EditPanelScaffold(
            title: '編輯任務',
            saveStatus: EditSaveStatus.saved,
            onClose: null,
            child: Text('欄位內容'),
          ),
        ),
      ),
    );
  }

  testWidgets('uses right drawer on wide layouts', (tester) async {
    await tester.pumpWidget(host(size: const Size(1200, 800)));

    final panel = tester.widget<ConstrainedBox>(
      find.byKey(const ValueKey('edit-panel-wide')),
    );
    expect(panel.constraints.maxWidth, 420);
    expect(find.text('編輯任務'), findsOneWidget);
    expect(find.text('已儲存'), findsOneWidget);
  });

  testWidgets('uses bottom sheet on narrow layouts', (tester) async {
    await tester.pumpWidget(host(size: const Size(420, 800)));

    expect(find.byKey(const ValueKey('edit-panel-narrow')), findsOneWidget);
    expect(find.text('欄位內容'), findsOneWidget);
  });
}
