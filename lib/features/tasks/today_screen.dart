import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/task_item.dart';
import 'task_edit_panel.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _quickAddController = TextEditingController();
  bool _adding = false;
  String? _editingTaskId;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(currentDateProvider);
    final tasks = ref.watch(todayTasksProvider);
    final projects = ref.watch(projectsProvider);

    return tasks.when(
      data: (items) => projects.when(
        data: (projectItems) {
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('專案載入失敗：$error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('任務載入失敗：$error')),
    );
  }

  Future<void> _createQuickTask() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) {
      setState(() => _adding = false);
      return;
    }
    final now = ref.read(currentDateProvider);
    await ref
        .read(databaseProvider)
        .createTask(title: title, dueDate: now, now: now);
    setState(() {
      _adding = false;
      _quickAddController.clear();
    });
  }

  Future<void> _toggleTask(Task task, bool done) async {
    await ref
        .read(databaseProvider)
        .updateTaskStatus(
          task.id,
          done ? TaskStatus.done : TaskStatus.todo,
          now: ref.read(currentDateProvider),
        );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.today,
    required this.tasks,
    required this.projects,
    required this.adding,
    required this.controller,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSubmitAdd,
    required this.onToggleTask,
    required this.onEditTask,
  });

  final DateTime today;
  final List<Task> tasks;
  final List<Project> projects;
  final bool adding;
  final TextEditingController controller;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final Future<void> Function() onSubmitAdd;
  final Future<void> Function(Task task, bool done) onToggleTask;
  final void Function(Task task) onEditTask;

  @override
  Widget build(BuildContext context) {
    final inProgress = tasks
        .where((task) => task.status == TaskStatus.inProgress.name)
        .toList();
    final todo = tasks
        .where((task) => task.status == TaskStatus.todo.name)
        .toList();
    final done = tasks
        .where((task) => task.status == TaskStatus.done.name)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
      children: [
        Text(
          '今日',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${today.year}年${today.month}月${today.day}日',
          style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatCard(value: todo.length, label: '今日待辦'),
            const SizedBox(width: 10),
            _StatCard(value: inProgress.length, label: '進行中'),
            const SizedBox(width: 10),
            _StatCard(value: done.length, label: '今日完成'),
          ],
        ),
        if (inProgress.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionHeader(label: '進行中', count: inProgress.length),
          for (final task in inProgress)
            TaskItem(
              task: task,
              projects: projects,
              onToggleDone: (done) => onToggleTask(task, done),
              onEdit: () => onEditTask(task),
            ),
        ],
        const SizedBox(height: 18),
        SectionHeader(
          label: '今日待辦',
          count: todo.length,
          actionLabel: '新增',
          onAction: onStartAdd,
        ),
        if (todo.isEmpty && done.isEmpty && !adding)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '今天沒有待辦事項。要新增一個，或查看所有專案嗎？',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ),
          )
        else
          for (final task in [...todo, ...done])
            TaskItem(
              task: task,
              projects: projects,
              onToggleDone: (done) => onToggleTask(task, done),
              onEdit: () => onEditTask(task),
            ),
        const SizedBox(height: 12),
        if (adding)
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('quick-add-task-field'),
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmitAdd(),
                  decoration: const InputDecoration(
                    hintText: '輸入任務標題，按 Enter 新增',
                  ),
                ),
              ),
              IconButton(onPressed: onCancelAdd, icon: const Icon(Icons.close)),
            ],
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onStartAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('新增任務'),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
