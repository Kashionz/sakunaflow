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
            fieldKey: const ValueKey('project-edit-name'),
            label: '名稱',
            initialValue: widget.project.name,
            isRequired: true,
            onSave: (value) => _saveProject(name: value),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('project-edit-description'),
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
            initialValue: ProjectStatus.values.firstWhere(
              (status) => status.name == widget.project.status,
              orElse: () => ProjectStatus.active,
            ),
            decoration: const InputDecoration(labelText: '狀態'),
            items: const [
              DropdownMenuItem(value: ProjectStatus.active, child: Text('進行中')),
              DropdownMenuItem(value: ProjectStatus.paused, child: Text('暫停')),
              DropdownMenuItem(
                value: ProjectStatus.archived,
                child: Text('已封存'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _saveProject(status: value);
              }
            },
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('project-edit-tech-tags'),
            label: '技術標籤，以逗號分隔',
            initialValue: widget.project.techTags.join(', '),
            onSave: (value) => _saveProject(techTags: _splitTags(value)),
            onStatusChanged: _setSaveStatus,
          ),
          const SizedBox(height: 14),
          DebouncedAutosaveField(
            fieldKey: const ValueKey('project-edit-git-url'),
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
      await ref
          .read(databaseProvider)
          .updateProject(
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
    return value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
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
