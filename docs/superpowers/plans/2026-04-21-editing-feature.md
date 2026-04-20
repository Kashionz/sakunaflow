# Editing Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build autosaved task and project editing for SakunaFlow using a shared responsive edit panel.

**Architecture:** Add focused Drift update methods first, then build reusable editing infrastructure, then task and project editor panels, then wire the panels into Today and Projects screens. UI writes go through `AppDatabase`; screens own only selected edit target state.

**Tech Stack:** Flutter, Dart, Riverpod, Drift, flutter_test, Material 3.

---

## File Structure

- Modify: `lib/data/local/database.dart`
  - Add `updateTask` and `updateProject`.
  - Add private validation helpers for priority, project status, and project palette.
- Modify: `test/data/local/app_database_test.dart`
  - Add database tests for full-field updates, blank optional strings, and invalid required values.
- Create: `lib/shared/widgets/edit_panel_scaffold.dart`
  - Responsive panel shell, save status enum, and save-state label.
- Create: `test/shared/widgets/edit_panel_scaffold_test.dart`
  - Verify wide drawer and narrow bottom-sheet behavior.
- Create: `lib/shared/widgets/debounced_autosave_field.dart`
  - Small text-field wrapper that debounces successful async saves and reports save state.
- Create: `test/shared/widgets/debounced_autosave_field_test.dart`
  - Verify debounce, required-field validation, and failed-save state.
- Create: `lib/features/tasks/task_edit_panel.dart`
  - Task editor fields and autosave handlers.
- Create: `test/features/tasks/task_edit_panel_test.dart`
  - Verify task field autosave against an in-memory `AppDatabase`.
- Create: `lib/features/projects/project_edit_panel.dart`
  - Project editor fields and autosave handlers.
- Create: `test/features/projects/project_edit_panel_test.dart`
  - Verify project field autosave against an in-memory `AppDatabase`.
- Modify: `lib/shared/widgets/task_item.dart`
  - Add edit affordance without breaking checkbox behavior.
- Modify: `test/shared/widgets/task_item_test.dart`
  - Verify edit affordance fires independently from checkbox.
- Modify: `lib/features/tasks/today_screen.dart`
  - Track selected task and show task editor.
- Modify: `lib/features/projects/projects_screen.dart`
  - Track selected project/task and show project or task editor.
- Modify: `test/app/sakunaflow_app_test.dart`
  - Add end-to-end widget coverage for editing from Today and Projects.

---

## Task 1: Data Layer Update APIs

**Files:**
- Modify: `lib/data/local/database.dart`
- Modify: `test/data/local/app_database_test.dart`

- [ ] **Step 1: Write failing database tests for task updates**

Add this test group near the existing task tests in `test/data/local/app_database_test.dart`:

```dart
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

  test('updateTask stores blank optional text as null and can clear project and due date', () async {
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
  });

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
      () => database.updateTask(task.id, estimatedPomodoros: -1, now: frozenNow),
      throwsArgumentError,
    );
  });
```

- [ ] **Step 2: Run task update tests and verify they fail**

Run:

```bash
flutter test test/data/local/app_database_test.dart --plain-name updateTask
```

Expected: FAIL because `AppDatabase.updateTask` does not exist.

- [ ] **Step 3: Implement `updateTask` and helpers**

In `lib/data/local/database.dart`, add these helpers inside `AppDatabase` near the other private helpers:

```dart
  String _requiredTrimmed(String value, String fieldName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be blank');
    }
    return trimmed;
  }

  List<String> _cleanTags(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  int _validPriority(int value) {
    if (value < 0 || value > 3) {
      throw ArgumentError.value(value, 'priority', 'must be between 0 and 3');
    }
    return value;
  }

  int _nonNegativePomodoros(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'estimatedPomodoros',
        'must not be negative',
      );
    }
    return value;
  }
```

Then add this method after `getTask`:

```dart
  Future<void> updateTask(
    String id, {
    String? title,
    String? description,
    String? projectId,
    String? parentTaskId,
    int? priority,
    DateTime? dueDate,
    int? estimatedPomodoros,
    List<String>? tags,
    bool clearProject = false,
    bool clearDueDate = false,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        title: title == null
            ? const Value.absent()
            : Value(_requiredTrimmed(title, 'title')),
        description: description == null
            ? const Value.absent()
            : Value(_blankToNull(description)),
        projectId: clearProject
            ? const Value(null)
            : projectId == null
            ? const Value.absent()
            : Value(projectId),
        parentTaskId: parentTaskId == null
            ? const Value.absent()
            : Value(_blankToNull(parentTaskId)),
        priority: priority == null
            ? const Value.absent()
            : Value(_validPriority(priority)),
        dueDate: clearDueDate
            ? const Value(null)
            : dueDate == null
            ? const Value.absent()
            : Value(dueDate),
        estimatedPomodoros: estimatedPomodoros == null
            ? const Value.absent()
            : Value(_nonNegativePomodoros(estimatedPomodoros)),
        tags: tags == null ? const Value.absent() : Value(_cleanTags(tags)),
        updatedAt: Value(stamp),
      ),
    );
  }
```

Implementation note: this signature uses `clearProject` and `clearDueDate` so callers can distinguish "leave unchanged" from "clear this nullable field".

- [ ] **Step 4: Run task update tests and verify they pass**

Run:

```bash
flutter test test/data/local/app_database_test.dart --plain-name updateTask
```

Expected: PASS.

- [ ] **Step 5: Write failing database tests for project updates**

Add this test group near the project seed test in `test/data/local/app_database_test.dart`:

```dart
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
      () => database.updateProject(
        project.id,
        color: '#123456',
        now: frozenNow,
      ),
      throwsArgumentError,
    );
  });
```

- [ ] **Step 6: Run project update tests and verify they fail**

Run:

```bash
flutter test test/data/local/app_database_test.dart --plain-name updateProject
```

Expected: FAIL because `AppDatabase.updateProject` does not exist.

- [ ] **Step 7: Implement `updateProject` and palette helper**

In `lib/data/local/database.dart`, add this top-level palette constant near the enums:

```dart
const projectPalette = [
  '#8c52ff',
  '#0075de',
  '#2a9d99',
  '#dd5b00',
  '#d93838',
  '#2f7d4f',
  '#888888',
];
```

Add this helper inside `AppDatabase`:

```dart
  String _validProjectColor(String value) {
    final trimmed = value.trim().toLowerCase();
    if (!projectPalette.contains(trimmed)) {
      throw ArgumentError.value(value, 'color', 'must be in projectPalette');
    }
    return trimmed;
  }
```

Add this method after `getProject`:

```dart
  Future<void> updateProject(
    String id, {
    String? name,
    String? description,
    String? color,
    ProjectStatus? status,
    List<String>? techTags,
    String? gitUrl,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    return (update(projects)..where((project) => project.id.equals(id))).write(
      ProjectsCompanion(
        name: name == null
            ? const Value.absent()
            : Value(_requiredTrimmed(name, 'name')),
        description: description == null
            ? const Value.absent()
            : Value(_blankToNull(description)),
        color: color == null
            ? const Value.absent()
            : Value(_validProjectColor(color)),
        status: status == null ? const Value.absent() : Value(status.name),
        techTags: techTags == null
            ? const Value.absent()
            : Value(_cleanTags(techTags)),
        gitUrl: gitUrl == null
            ? const Value.absent()
            : Value(_blankToNull(gitUrl)),
        updatedAt: Value(stamp),
      ),
    );
  }
```

- [ ] **Step 8: Run database tests**

Run:

```bash
flutter test test/data/local/app_database_test.dart
```

Expected: PASS.

- [ ] **Step 9: Format and commit data layer**

Run:

```bash
dart format lib/data/local/database.dart test/data/local/app_database_test.dart
flutter analyze
git add lib/data/local/database.dart test/data/local/app_database_test.dart
git commit -m "feat: add editable task and project persistence"
```

Expected: format changes only in touched files, analyzer PASS, commit succeeds.

---

## Task 2: Shared Edit Panel and Autosave Field

**Files:**
- Create: `lib/shared/widgets/edit_panel_scaffold.dart`
- Create: `test/shared/widgets/edit_panel_scaffold_test.dart`
- Create: `lib/shared/widgets/debounced_autosave_field.dart`
- Create: `test/shared/widgets/debounced_autosave_field_test.dart`

- [ ] **Step 1: Write failing tests for responsive edit panel**

Create `test/shared/widgets/edit_panel_scaffold_test.dart`:

```dart
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
```

- [ ] **Step 2: Run panel tests and verify they fail**

Run:

```bash
flutter test test/shared/widgets/edit_panel_scaffold_test.dart
```

Expected: FAIL because `edit_panel_scaffold.dart` does not exist.

- [ ] **Step 3: Implement `EditPanelScaffold`**

Create `lib/shared/widgets/edit_panel_scaffold.dart`:

```dart
import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum EditSaveStatus { idle, saving, saved, failed }

class EditPanelScaffold extends StatelessWidget {
  const EditPanelScaffold({
    super.key,
    required this.title,
    required this.saveStatus,
    required this.child,
    this.errorMessage,
    this.onClose,
  });

  final String title;
  final EditSaveStatus saveStatus;
  final String? errorMessage;
  final VoidCallback? onClose;
  final Widget child;

  static const narrowBreakpoint = 720.0;
  static const widePanelWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panel = _PanelBody(
      title: title,
      saveStatus: saveStatus,
      errorMessage: errorMessage,
      onClose: onClose,
      child: child,
    );

    if (width < narrowBreakpoint) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          key: const ValueKey('edit-panel-narrow'),
          elevation: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: panel,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        key: const ValueKey('edit-panel-wide'),
        constraints: const BoxConstraints(
          maxWidth: widePanelWidth,
          minWidth: widePanelWidth,
          minHeight: double.infinity,
        ),
        child: Material(elevation: 18, child: panel),
      ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.title,
    required this.saveStatus,
    required this.child,
    this.errorMessage,
    this.onClose,
  });

  final String title;
  final EditSaveStatus saveStatus;
  final String? errorMessage;
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      _SaveStatusLabel(
                        status: saveStatus,
                        errorMessage: errorMessage,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: '關閉',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveStatusLabel extends StatelessWidget {
  const _SaveStatusLabel({required this.status, this.errorMessage});

  final EditSaveStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      EditSaveStatus.saving => '儲存中',
      EditSaveStatus.failed => '儲存失敗',
      EditSaveStatus.saved => '已儲存',
      EditSaveStatus.idle => '尚未變更',
    };
    final color = switch (status) {
      EditSaveStatus.failed => AppColors.red,
      EditSaveStatus.saving => AppColors.orange,
      _ => AppColors.mutedText,
    };

    return Text(
      errorMessage == null || status != EditSaveStatus.failed
          ? text
          : '$text：$errorMessage',
      style: TextStyle(color: color, fontSize: 12),
    );
  }
}
```

- [ ] **Step 4: Run panel tests and verify they pass**

Run:

```bash
flutter test test/shared/widgets/edit_panel_scaffold_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write failing tests for debounced autosave text field**

Create `test/shared/widgets/debounced_autosave_field_test.dart`:

```dart
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
```

- [ ] **Step 6: Run autosave tests and verify they fail**

Run:

```bash
flutter test test/shared/widgets/debounced_autosave_field_test.dart
```

Expected: FAIL because `debounced_autosave_field.dart` does not exist.

- [ ] **Step 7: Implement `DebouncedAutosaveField`**

Create `lib/shared/widgets/debounced_autosave_field.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'edit_panel_scaffold.dart';

class DebouncedAutosaveField extends StatefulWidget {
  const DebouncedAutosaveField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.onStatusChanged,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String initialValue;
  final Future<void> Function(String value) onSave;
  final void Function(EditSaveStatus status, String? message)? onStatusChanged;
  final Duration debounceDuration;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<DebouncedAutosaveField> createState() => _DebouncedAutosaveFieldState();
}

class _DebouncedAutosaveFieldState extends State<DebouncedAutosaveField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _errorText;
  String _lastSaved = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _lastSaved = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant DebouncedAutosaveField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        !_controller.selection.isValid &&
        _controller.text == _lastSaved) {
      _controller.text = widget.initialValue;
      _lastSaved = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      onChanged: _scheduleSave,
      decoration: InputDecoration(labelText: widget.label, errorText: _errorText),
    );
  }

  void _scheduleSave(String value) {
    _debounce?.cancel();
    setState(() => _errorText = null);
    _debounce = Timer(widget.debounceDuration, () => _save(value));
  }

  Future<void> _save(String value) async {
    final trimmed = value.trim();
    if (widget.isRequired && trimmed.isEmpty) {
      setState(() => _errorText = '必填');
      return;
    }
    if (value == _lastSaved) return;

    widget.onStatusChanged?.call(EditSaveStatus.saving, null);
    try {
      await widget.onSave(value);
      _lastSaved = value;
      widget.onStatusChanged?.call(EditSaveStatus.saved, null);
    } catch (error) {
      widget.onStatusChanged?.call(EditSaveStatus.failed, error.toString());
    }
  }
}
```

Implementation note: if this `didUpdateWidget` guard proves too conservative in real tests, simplify it to only update the controller when `_controller.text == _lastSaved`. The important behavior is: do not overwrite active unsaved input with a stream refresh.

- [ ] **Step 8: Run shared widget tests**

Run:

```bash
flutter test test/shared/widgets/edit_panel_scaffold_test.dart test/shared/widgets/debounced_autosave_field_test.dart
```

Expected: PASS.

- [ ] **Step 9: Format and commit shared editing infrastructure**

Run:

```bash
dart format lib/shared/widgets/edit_panel_scaffold.dart lib/shared/widgets/debounced_autosave_field.dart test/shared/widgets/edit_panel_scaffold_test.dart test/shared/widgets/debounced_autosave_field_test.dart
flutter analyze
git add lib/shared/widgets/edit_panel_scaffold.dart lib/shared/widgets/debounced_autosave_field.dart test/shared/widgets/edit_panel_scaffold_test.dart test/shared/widgets/debounced_autosave_field_test.dart
git commit -m "feat: add shared edit panel autosave widgets"
```

Expected: tests and analyzer PASS, commit succeeds.

---

## Task 3: Task Edit Panel

**Files:**
- Create: `lib/features/tasks/task_edit_panel.dart`
- Create: `test/features/tasks/task_edit_panel_test.dart`

- [ ] **Step 1: Write failing task panel widget tests**

Create `test/features/tasks/task_edit_panel_test.dart`:

```dart
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
    final task = (await database.getTodayTasks(now)).first;
    final projects = await database.watchProjects().first;

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

    final updated = await database.getTask(task.id);
    expect(updated.title, '更新後的任務');
    expect(updated.description, '新的任務描述');
    expect(find.text('已儲存'), findsOneWidget);
  });

  testWidgets('autosaves task project, priority, estimate, due date, and tags', (tester) async {
    final task = (await database.getTodayTasks(now)).first;
    final projects = await database.watchProjects().first;

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

    await tester.enterText(find.byKey(const ValueKey('task-edit-estimate')), '5');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('task-edit-tags')),
      'Flutter, Drift',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    final updated = await database.getTask(task.id);
    expect(updated.projectId, projects[1].id);
    expect(updated.priority, 0);
    expect(updated.estimatedPomodoros, 5);
    expect(updated.tags, const ['Flutter', 'Drift']);
  });
}
```

Before running these tests, Task 3 Step 3 adds `childOverride` to `SakunaFlowApp`. This keeps the test in the app ProviderScope and theme without routing through a full page.

- [ ] **Step 2: Run task panel tests and verify they fail**

Run:

```bash
flutter test test/features/tasks/task_edit_panel_test.dart
```

Expected: FAIL because `TaskEditPanel` and `SakunaFlowApp.childOverride` do not exist.

- [ ] **Step 3: Add test-only child override to `SakunaFlowApp`**

Modify `lib/app/app.dart`:

```dart
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
```

- [ ] **Step 4: Implement `TaskEditPanel`**

Create `lib/features/tasks/task_edit_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';
import '../../shared/widgets/debounced_autosave_field.dart';
import '../../shared/widgets/edit_panel_scaffold.dart';

class TaskEditPanel extends ConsumerStatefulWidget {
  const TaskEditPanel({
    super.key,
    required this.task,
    required this.projects,
    required this.onClose,
  });

  final Task task;
  final List<Project> projects;
  final VoidCallback onClose;

  @override
  ConsumerState<TaskEditPanel> createState() => _TaskEditPanelState();
}

class _TaskEditPanelState extends ConsumerState<TaskEditPanel> {
  EditSaveStatus _saveStatus = EditSaveStatus.saved;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return EditPanelScaffold(
      title: '編輯任務',
      saveStatus: _saveStatus,
      errorMessage: _errorMessage,
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedAutosaveField(
            key: const ValueKey('task-edit-title'),
            label: '標題',
            initialValue: widget.task.title,
            isRequired: true,
            onSave: (value) => _saveTask(title: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('task-edit-description'),
            label: '描述',
            initialValue: widget.task.description ?? '',
            maxLines: 4,
            onSave: (value) => _saveTask(description: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            key: const ValueKey('task-edit-project'),
            value: widget.task.projectId,
            decoration: const InputDecoration(labelText: '專案'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('無專案')),
              for (final project in widget.projects)
                DropdownMenuItem<String?>(
                  value: project.id,
                  child: Text(project.name),
                ),
            ],
            onChanged: (value) => _saveTask(
              projectId: value,
              clearProject: value == null,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            key: const ValueKey('task-edit-priority'),
            value: widget.task.priority,
            decoration: const InputDecoration(labelText: '優先度'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('P0')),
              DropdownMenuItem(value: 1, child: Text('P1')),
              DropdownMenuItem(value: 2, child: Text('P2')),
              DropdownMenuItem(value: 3, child: Text('P3')),
            ],
            onChanged: (value) {
              if (value != null) _saveTask(priority: value);
            },
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('task-edit-estimate'),
            label: '預估番茄數',
            initialValue: '${widget.task.estimatedPomodoros}',
            keyboardType: TextInputType.number,
            onSave: (value) =>
                _saveTask(estimatedPomodoros: int.tryParse(value.trim()) ?? 0),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('task-edit-tags'),
            label: '標籤，以逗號分隔',
            initialValue: widget.task.tags.join(', '),
            onSave: (value) => _saveTask(tags: _splitTags(value)),
            onStatusChanged: _setSaveStatus,
          ),
        ],
      ),
    );
  }

  Future<void> _saveTask({
    String? title,
    String? description,
    String? projectId,
    int? priority,
    DateTime? dueDate,
    int? estimatedPomodoros,
    List<String>? tags,
    bool clearProject = false,
    bool clearDueDate = false,
  }) async {
    _setSaveStatus(EditSaveStatus.saving, null);
    try {
      await ref.read(databaseProvider).updateTask(
        widget.task.id,
        title: title,
        description: description,
        projectId: projectId ?? widget.task.projectId,
        clearProject: clearProject,
        priority: priority,
        dueDate: dueDate ?? widget.task.dueDate,
        clearDueDate: clearDueDate,
        estimatedPomodoros: estimatedPomodoros,
        tags: tags,
      );
      _setSaveStatus(EditSaveStatus.saved, null);
    } catch (error) {
      _setSaveStatus(EditSaveStatus.failed, error.toString());
    }
  }

  List<String> _splitTags(String value) {
    return value.split(',').map((tag) => tag.trim()).where((tag) {
      return tag.isNotEmpty;
    }).toList(growable: false);
  }

  void _setSaveStatus(EditSaveStatus status, String? message) {
    if (!mounted) return;
    setState(() {
      _saveStatus = status;
      _errorMessage = message;
    });
  }
}
```

Important follow-up in Task 5: add date picker support with key `task-edit-due-date` when wiring the panel into real screens. If adding it now is straightforward, include a `ListTile` that calls `showDatePicker` and then `_saveTask(dueDate: picked)`.

- [ ] **Step 5: Run task panel tests and fix compile errors only**

Run:

```bash
flutter test test/features/tasks/task_edit_panel_test.dart
```

Expected: PASS after adjusting imports and any analyzer-driven const/style issues. Do not add page wiring in this task.

- [ ] **Step 6: Format and commit task panel**

Run:

```bash
dart format lib/app/app.dart lib/features/tasks/task_edit_panel.dart test/features/tasks/task_edit_panel_test.dart
flutter analyze
git add lib/app/app.dart lib/features/tasks/task_edit_panel.dart test/features/tasks/task_edit_panel_test.dart
git commit -m "feat: add autosaved task edit panel"
```

Expected: analyzer PASS, commit succeeds.

---

## Task 4: Project Edit Panel

**Files:**
- Create: `lib/features/projects/project_edit_panel.dart`
- Create: `test/features/projects/project_edit_panel_test.dart`

- [ ] **Step 1: Write failing project panel widget tests**

Create `test/features/projects/project_edit_panel_test.dart`:

```dart
import 'package:drift/native.dart';
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
    final project = (await database.watchProjects().first).first;

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

    final updated = await database.getProject(project.id);
    expect(updated.name, '更新後專案');
    expect(updated.description, '新的專案描述');
  });

  testWidgets('autosaves project color status tags and git url', (tester) async {
    final project = (await database.watchProjects().first).first;

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

    final updated = await database.getProject(project.id);
    expect(updated.color, '#dd5b00');
    expect(updated.status, ProjectStatus.paused.name);
    expect(updated.techTags, const ['Flutter', 'Drift']);
    expect(updated.gitUrl, 'https://github.com/example/sakunaflow');
  });
}
```

- [ ] **Step 2: Run project panel tests and verify they fail**

Run:

```bash
flutter test test/features/projects/project_edit_panel_test.dart
```

Expected: FAIL because `ProjectEditPanel` does not exist.

- [ ] **Step 3: Implement `ProjectEditPanel`**

Create `lib/features/projects/project_edit_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';
import '../../shared/widgets/debounced_autosave_field.dart';
import '../../shared/widgets/edit_panel_scaffold.dart';

class ProjectEditPanel extends ConsumerStatefulWidget {
  const ProjectEditPanel({
    super.key,
    required this.project,
    required this.onClose,
  });

  final Project project;
  final VoidCallback onClose;

  @override
  ConsumerState<ProjectEditPanel> createState() => _ProjectEditPanelState();
}

class _ProjectEditPanelState extends ConsumerState<ProjectEditPanel> {
  EditSaveStatus _saveStatus = EditSaveStatus.saved;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return EditPanelScaffold(
      title: '編輯專案',
      saveStatus: _saveStatus,
      errorMessage: _errorMessage,
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedAutosaveField(
            key: const ValueKey('project-edit-name'),
            label: '名稱',
            initialValue: widget.project.name,
            isRequired: true,
            onSave: (value) => _saveProject(name: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('project-edit-description'),
            label: '描述',
            initialValue: widget.project.description ?? '',
            maxLines: 3,
            onSave: (value) => _saveProject(description: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in projectPalette)
                InkWell(
                  key: ValueKey('project-edit-color-$color'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _saveProject(color: color),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.project.color == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(color.substring(1), radix: 16) +
                                0xff000000,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const SizedBox(width: 28, height: 28),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ProjectStatus>(
            key: const ValueKey('project-edit-status'),
            value: ProjectStatus.values.firstWhere(
              (status) => status.name == widget.project.status,
              orElse: () => ProjectStatus.active,
            ),
            decoration: const InputDecoration(labelText: '狀態'),
            items: const [
              DropdownMenuItem(value: ProjectStatus.active, child: Text('進行中')),
              DropdownMenuItem(value: ProjectStatus.paused, child: Text('暫停')),
              DropdownMenuItem(value: ProjectStatus.archived, child: Text('已封存')),
            ],
            onChanged: (value) {
              if (value != null) _saveProject(status: value);
            },
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('project-edit-tech-tags'),
            label: '技術標籤，以逗號分隔',
            initialValue: widget.project.techTags.join(', '),
            onSave: (value) => _saveProject(techTags: _splitTags(value)),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            key: const ValueKey('project-edit-git-url'),
            label: 'Git URL',
            initialValue: widget.project.gitUrl ?? '',
            keyboardType: TextInputType.url,
            onSave: (value) => _saveProject(gitUrl: value),
            onStatusChanged: _setSaveStatus,
          ),
        ],
      ),
    );
  }

  Future<void> _saveProject({
    String? name,
    String? description,
    String? color,
    ProjectStatus? status,
    List<String>? techTags,
    String? gitUrl,
  }) async {
    _setSaveStatus(EditSaveStatus.saving, null);
    try {
      await ref.read(databaseProvider).updateProject(
        widget.project.id,
        name: name,
        description: description,
        color: color,
        status: status,
        techTags: techTags,
        gitUrl: gitUrl,
      );
      _setSaveStatus(EditSaveStatus.saved, null);
    } catch (error) {
      _setSaveStatus(EditSaveStatus.failed, error.toString());
    }
  }

  List<String> _splitTags(String value) {
    return value.split(',').map((tag) => tag.trim()).where((tag) {
      return tag.isNotEmpty;
    }).toList(growable: false);
  }

  void _setSaveStatus(EditSaveStatus status, String? message) {
    if (!mounted) return;
    setState(() {
      _saveStatus = status;
      _errorMessage = message;
    });
  }
}
```

- [ ] **Step 4: Run project panel tests**

Run:

```bash
flutter test test/features/projects/project_edit_panel_test.dart
```

Expected: PASS after minor compile fixes.

- [ ] **Step 5: Format and commit project panel**

Run:

```bash
dart format lib/features/projects/project_edit_panel.dart test/features/projects/project_edit_panel_test.dart
flutter analyze
git add lib/features/projects/project_edit_panel.dart test/features/projects/project_edit_panel_test.dart
git commit -m "feat: add autosaved project edit panel"
```

Expected: analyzer PASS, commit succeeds.

---

## Task 5: Wire Editors Into Today and Projects Screens

**Files:**
- Modify: `lib/shared/widgets/task_item.dart`
- Modify: `test/shared/widgets/task_item_test.dart`
- Modify: `lib/features/tasks/today_screen.dart`
- Modify: `lib/features/projects/projects_screen.dart`
- Modify: `test/app/sakunaflow_app_test.dart`

- [ ] **Step 1: Write failing `TaskItem` edit affordance test**

Append this test to `test/shared/widgets/task_item_test.dart`:

```dart
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
```

- [ ] **Step 2: Run `TaskItem` tests and verify they fail**

Run:

```bash
flutter test test/shared/widgets/task_item_test.dart
```

Expected: FAIL because `TaskItem.onEdit` and edit button key do not exist.

- [ ] **Step 3: Add edit affordance to `TaskItem`**

Modify the `TaskItem` constructor in `lib/shared/widgets/task_item.dart`:

```dart
  const TaskItem({
    super.key,
    required this.task,
    required this.projects,
    required this.onToggleDone,
    this.onEdit,
  });

  final Task task;
  final List<Project> projects;
  final Future<void> Function(bool done) onToggleDone;
  final VoidCallback? onEdit;
```

Then add this icon button before `PriorityBadge`:

```dart
              if (onEdit != null)
                IconButton(
                  key: ValueKey('task-edit-${task.id}'),
                  tooltip: '編輯任務',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              const SizedBox(width: 4),
```

Keep the checkbox `InkWell` unchanged so completion behavior remains independent.

- [ ] **Step 4: Run `TaskItem` tests**

Run:

```bash
flutter test test/shared/widgets/task_item_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write failing app tests for opening and autosaving from screens**

Append these tests to `test/app/sakunaflow_app_test.dart`:

```dart
  testWidgets('edits a today task from the edit panel', (tester) async {
    await tester.pumpWidget(SakunaFlowApp(database: database, now: today));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('task-edit-task-calendar-ui')));
    await tester.pumpAndSettle();

    expect(find.text('編輯任務'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('task-edit-title')),
      '更新 CalendarScreen UI',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final task = await database.getTask('task-calendar-ui');
    expect(task.title, '更新 CalendarScreen UI');
    expect(find.text('更新 CalendarScreen UI'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('edits a project from the projects list', (tester) async {
    await tester.pumpWidget(SakunaFlowApp(database: database, now: today));
    await tester.pumpAndSettle();

    await tester.tap(find.text('專案').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('project-edit-project-sakunaflow')));
    await tester.pumpAndSettle();

    expect(find.text('編輯專案'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('project-edit-name')),
      'SakunaFlow Local',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final project = await database.getProject('project-sakunaflow');
    expect(project.name, 'SakunaFlow Local');
    expect(find.text('SakunaFlow Local'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
```

- [ ] **Step 6: Run app tests and verify they fail**

Run:

```bash
flutter test test/app/sakunaflow_app_test.dart --plain-name edits
```

Expected: FAIL because Today and Projects screens do not show edit panels.

- [ ] **Step 7: Wire `TaskEditPanel` into Today screen**

Modify `lib/features/tasks/today_screen.dart`:

1. Import the panel:

```dart
import 'task_edit_panel.dart';
```

2. Add selected task state to `_TodayScreenState`:

```dart
  String? _editingTaskId;
```

3. In the `data` branch, derive selected task:

```dart
          final editingTask = _editingTaskId == null
              ? null
              : items.where((task) => task.id == _editingTaskId).firstOrNull;
          return Stack(
            children: [
              _TodayContent(
                today: today,
                tasks: items,
                projects: projectItems,
                adding: _adding,
                controller: _quickAddController,
                onStartAdd: () => setState(() => _adding = true),
                onCancelAdd: () => setState(() {
                  _adding = false;
                  _quickAddController.clear();
                }),
                onSubmitAdd: _createQuickTask,
                onToggleTask: _toggleTask,
                onEditTask: (task) => setState(() => _editingTaskId = task.id),
              ),
              if (editingTask != null)
                TaskEditPanel(
                  task: editingTask,
                  projects: projectItems,
                  onClose: () => setState(() => _editingTaskId = null),
                ),
            ],
          );
```

4. Add callback plumbing to `_TodayContent`:

```dart
  final void Function(Task task) onEditTask;
```

5. Pass it into each `TaskItem`:

```dart
              onEdit: () => onEditTask(task),
```

- [ ] **Step 8: Wire `ProjectEditPanel` and `TaskEditPanel` into Projects screen**

Modify `lib/features/projects/projects_screen.dart`:

1. Convert `ProjectsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` and keep:

```dart
  String? _editingProjectId;
  String? _editingTaskId;
```

2. Import panels:

```dart
import '../tasks/task_edit_panel.dart';
import 'project_edit_panel.dart';
```

3. Wrap current returned list/detail content in a `Stack`, derive selected objects from `items` and `taskItems`, and render:

```dart
              if (editingProject != null)
                ProjectEditPanel(
                  project: editingProject,
                  onClose: () => setState(() => _editingProjectId = null),
                ),
              if (editingTask != null)
                TaskEditPanel(
                  task: editingTask,
                  projects: items,
                  onClose: () => setState(() => _editingTaskId = null),
                ),
```

4. Add `onEditProject` to `_ProjectList` and `_ProjectCard`; add icon button key:

```dart
IconButton(
  key: ValueKey('project-edit-${project.id}'),
  tooltip: '編輯專案',
  onPressed: onEdit,
  icon: const Icon(Icons.edit_outlined, size: 18),
)
```

5. Add edit button to `_ProjectDetail` header with the same key and call `onEditProject(project)`.

6. Pass `onEdit` to every `TaskItem` in project detail:

```dart
onEdit: () => onEditTask(task),
```

- [ ] **Step 9: Run app edit tests**

Run:

```bash
flutter test test/app/sakunaflow_app_test.dart --plain-name edits
```

Expected: PASS after fixing compile errors and any duplicate text finder issues.

- [ ] **Step 10: Run all widget tests touched by wiring**

Run:

```bash
flutter test test/shared/widgets/task_item_test.dart test/app/sakunaflow_app_test.dart
```

Expected: PASS.

- [ ] **Step 11: Format and commit screen wiring**

Run:

```bash
dart format lib/shared/widgets/task_item.dart test/shared/widgets/task_item_test.dart lib/features/tasks/today_screen.dart lib/features/projects/projects_screen.dart test/app/sakunaflow_app_test.dart
flutter analyze
git add lib/shared/widgets/task_item.dart test/shared/widgets/task_item_test.dart lib/features/tasks/today_screen.dart lib/features/projects/projects_screen.dart test/app/sakunaflow_app_test.dart
git commit -m "feat: wire edit panels into task and project screens"
```

Expected: analyzer PASS, commit succeeds.

---

## Task 6: Final Validation, Date Editing, and Polish

**Files:**
- Modify: `lib/features/tasks/task_edit_panel.dart`
- Modify: `test/features/tasks/task_edit_panel_test.dart`
- Modify as needed: files touched by prior tasks

- [ ] **Step 1: Add failing due-date edit test**

Append this test to `test/features/tasks/task_edit_panel_test.dart`:

```dart
  testWidgets('clears task due date from the panel', (tester) async {
    final task = (await database.getTodayTasks(now)).first;
    final projects = await database.watchProjects().first;

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

    final updated = await database.getTask(task.id);
    expect(updated.dueDate, isNull);
  });
```

- [ ] **Step 2: Run due-date test and verify it fails**

Run:

```bash
flutter test test/features/tasks/task_edit_panel_test.dart --plain-name due
```

Expected: FAIL because due-date controls do not exist.

- [ ] **Step 3: Add due-date controls to `TaskEditPanel`**

Add this block below the priority dropdown in `lib/features/tasks/task_edit_panel.dart`:

```dart
          const SizedBox(height: 14),
          ListTile(
            key: const ValueKey('task-edit-due-date'),
            contentPadding: EdgeInsets.zero,
            title: const Text('期限'),
            subtitle: Text(
              widget.task.dueDate == null
                  ? '未設定'
                  : '${widget.task.dueDate!.year}/${widget.task.dueDate!.month}/${widget.task.dueDate!.day}',
            ),
            trailing: IconButton(
              key: const ValueKey('task-edit-clear-due-date'),
              tooltip: '清除期限',
              onPressed: () => _saveTask(clearDueDate: true),
              icon: const Icon(Icons.close),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.task.dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                await _saveTask(dueDate: picked);
              }
            },
          ),
```

If `updateTask` currently cannot distinguish clearing a due date from leaving it unchanged, introduce a private sentinel in `TaskEditPanel` instead:

```dart
  static final Object _unset = Object();
```

Then change `_saveTask` to accept `Object? dueDate = _unset` and pass either `widget.task.dueDate`, `null`, or the picked `DateTime` explicitly. Keep tests green.

- [ ] **Step 4: Run full task panel tests**

Run:

```bash
flutter test test/features/tasks/task_edit_panel_test.dart
```

Expected: PASS.

- [ ] **Step 5: Run complete test suite**

Run:

```bash
flutter test
```

Expected: PASS.

- [ ] **Step 6: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 7: Manually smoke test the app on desktop**

Run:

```bash
flutter run -d windows
```

Expected:

- App launches.
- Today task edit icon opens a right-side drawer on desktop.
- Title and description autosave after a short pause.
- Project list edit icon opens project editor.
- Checkbox still toggles completion without opening editor.
- Closing the panel leaves saved values visible.

- [ ] **Step 8: Commit final polish**

Run:

```bash
dart format lib test
git status --short
git add lib test
git commit -m "test: validate editing flows"
```

Expected: only intentional files are staged; commit succeeds.

---

## Self-Review Checklist

- Spec coverage:
  - Task field editing is covered by Tasks 1, 3, 5, and 6.
  - Project field editing is covered by Tasks 1, 4, and 5.
  - Autosave and save-state UI are covered by Task 2 and panel tests.
  - Responsive drawer/bottom-sheet behavior is covered by Task 2.
  - Today, Projects list, and Project detail entry points are covered by Task 5.
  - Existing checkbox behavior is covered by Task 5.
- Red-flag scan:
  - No vague "add tests" steps remain.
  - Each code-changing step includes concrete code or exact implementation guidance.
- Type consistency:
  - `EditSaveStatus` is defined before panel usage.
  - `TaskEditPanel` and `ProjectEditPanel` use `AppDatabase.updateTask` and `AppDatabase.updateProject` from Task 1.
  - Test keys are defined in the same tasks that introduce their widgets.
