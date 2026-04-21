import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/local/database.dart';
import 'priority_badge.dart';

class TaskItem extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done.name;
    final project = projects
        .where((item) => item.id == task.projectId)
        .firstOrNull;
    final urgentColor = !done && task.priority == 0
        ? AppColors.red
        : !done && task.priority == 1
        ? AppColors.orange
        : Colors.transparent;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: AppColors.border),
          left: BorderSide(color: urgentColor, width: 3),
        ),
      ),
      child: Opacity(
        opacity: done ? 0.45 : 1,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            urgentColor == Colors.transparent ? 12 : 9,
            10,
            12,
            10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskCheckbox(
                key: ValueKey('task-checkbox-${task.id}'),
                done: done,
                onChanged: onToggleDone,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (project != null) _ProjectLabel(project: project),
                        if (task.dueDate != null)
                          Text(
                            _dueLabel(task.dueDate!),
                            style: TextStyle(
                              color: _isToday(task.dueDate!)
                                  ? AppColors.red
                                  : AppColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        if (task.estimatedPomodoros > 0)
                          Text(
                            '${task.actualPomodoros}/${task.estimatedPomodoros} 番茄',
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null) ...[
                IconButton(
                  key: ValueKey('task-edit-${task.id}'),
                  tooltip: '編輯任務',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                const SizedBox(width: 4),
              ],
              const SizedBox(width: 8),
              PriorityBadge(priority: task.priority),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(DateTime dueDate) {
    if (_isToday(dueDate)) return '今天';
    return '${dueDate.month}/${dueDate.day}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _TaskCheckbox extends StatefulWidget {
  const _TaskCheckbox({super.key, required this.done, required this.onChanged});

  final bool done;
  final Future<void> Function(bool done) onChanged;

  @override
  State<_TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<_TaskCheckbox> {
  late bool _checked = widget.done;

  @override
  void didUpdateWidget(covariant _TaskCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done != oldWidget.done && widget.done != _checked) {
      _checked = widget.done;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        final previous = _checked;
        final next = !_checked;
        setState(() => _checked = next);
        try {
          await widget.onChanged(next);
        } catch (_) {
          if (mounted) {
            setState(() => _checked = previous);
          }
          rethrow;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _checked ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _checked ? AppColors.accent : AppColors.mutedText,
            width: 1.5,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          reverseDuration: const Duration(milliseconds: 90),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _checked
              ? const Icon(
                  Icons.check,
                  key: ValueKey('task-checkbox-checked'),
                  size: 13,
                  color: Colors.white,
                )
              : const SizedBox(
                  key: ValueKey('task-checkbox-unchecked'),
                  width: 13,
                  height: 13,
                ),
        ),
      ),
    );
  }
}

class _ProjectLabel extends StatelessWidget {
  const _ProjectLabel({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(project.color.substring(1), radix: 16) + 0xff000000,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 6, height: 6),
        ),
        const SizedBox(width: 4),
        Text(
          project.name,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}
