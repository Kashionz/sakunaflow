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
  });

  final Task task;
  final List<Project> projects;
  final ValueChanged<bool> onToggleDone;

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
              _TaskCheckbox(done: done, onChanged: onToggleDone),
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

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({required this.done, required this.onChanged});

  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(!done),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? AppColors.accent : Colors.transparent,
          shape: BoxShape.circle,
          border: done
              ? null
              : Border.all(color: AppColors.mutedText, width: 1.5),
        ),
        child: done
            ? const Icon(Icons.check, size: 13, color: Colors.white)
            : null,
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
