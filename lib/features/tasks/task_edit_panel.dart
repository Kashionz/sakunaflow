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
            fieldKey: const ValueKey('task-edit-title'),
            label: '標題',
            initialValue: widget.task.title,
            isRequired: true,
            onSave: (value) => _saveTask(title: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('task-edit-description'),
            label: '描述',
            initialValue: widget.task.description ?? '',
            maxLines: 4,
            onSave: (value) => _saveTask(description: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            key: const ValueKey('task-edit-project'),
            initialValue: widget.task.projectId,
            decoration: const InputDecoration(labelText: '專案'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('無專案')),
              for (final project in widget.projects)
                DropdownMenuItem<String?>(
                  value: project.id,
                  child: Text(project.name),
                ),
            ],
            onChanged: (value) {
              _saveTask(projectId: value, clearProject: value == null);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            key: const ValueKey('task-edit-priority'),
            initialValue: widget.task.priority,
            decoration: const InputDecoration(labelText: '優先度'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('P0')),
              DropdownMenuItem(value: 1, child: Text('P1')),
              DropdownMenuItem(value: 2, child: Text('P2')),
              DropdownMenuItem(value: 3, child: Text('P3')),
            ],
            onChanged: (value) {
              if (value != null) {
                _saveTask(priority: value);
              }
            },
          ),
          const SizedBox(height: 14),
          ListTile(
            key: const ValueKey('task-edit-due-date'),
            contentPadding: EdgeInsets.zero,
            title: const Text('期限'),
            subtitle: Text(_dueDateLabel(widget.task.dueDate)),
            trailing: IconButton(
              key: const ValueKey('task-edit-clear-due-date'),
              tooltip: '清除期限',
              onPressed: widget.task.dueDate == null
                  ? null
                  : () => _saveTask(clearDueDate: true),
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
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('task-edit-estimate'),
            label: '預估番茄數',
            initialValue: '${widget.task.estimatedPomodoros}',
            keyboardType: TextInputType.number,
            onSave: (value) async {
              final trimmed = value.trim();
              await _saveTask(
                estimatedPomodoros: trimmed.isEmpty ? 0 : int.parse(trimmed),
              );
            },
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('task-edit-tags'),
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
      await ref
          .read(databaseProvider)
          .updateTask(
            widget.task.id,
            title: title,
            description: description,
            projectId: projectId,
            priority: priority,
            dueDate: dueDate,
            estimatedPomodoros: estimatedPomodoros,
            tags: tags,
            clearProject: clearProject,
            clearDueDate: clearDueDate,
          );
      _setSaveStatus(EditSaveStatus.saved, null);
    } catch (error) {
      _setSaveStatus(EditSaveStatus.failed, error.toString());
    }
  }

  List<String> _splitTags(String value) {
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  String _dueDateLabel(DateTime? value) {
    if (value == null) {
      return '未設定';
    }
    return '${value.year}/${value.month}/${value.day}';
  }

  void _setSaveStatus(EditSaveStatus status, String? message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _saveStatus = status;
      _errorMessage = message;
    });
  }
}
