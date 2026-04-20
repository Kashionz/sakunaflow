import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/task_item.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key, this.projectId});

  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final tasks = ref.watch(tasksProvider);

    return projects.when(
      data: (items) => tasks.when(
        data: (taskItems) {
          if (projectId != null) {
            final project = items
                .where((item) => item.id == projectId)
                .firstOrNull;
            if (project == null) {
              return const Center(child: Text('找不到專案'));
            }
            return _ProjectDetail(
              project: project,
              tasks: taskItems,
              projects: items,
            );
          }
          return _ProjectList(projects: items, tasks: taskItems);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('任務載入失敗：$error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('專案載入失敗：$error')),
    );
  }
}

class _ProjectList extends ConsumerWidget {
  const _ProjectList({required this.projects, required this.tasks});

  final List<Project> projects;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
      children: [
        Row(
          children: [
            Text(
              '專案',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showProjectDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('新增專案'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final project in projects) ...[
          _ProjectCard(
            project: project,
            openTasks: tasks
                .where(
                  (task) =>
                      task.projectId == project.id &&
                      task.status != TaskStatus.done.name,
                )
                .length,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _showProjectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增專案'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '專案名稱'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              await ref.read(databaseProvider).createProject(name: title);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.openTasks});

  final Project project;
  final int openTasks;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(project.color.substring(1), radix: 16) + 0xff000000,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: project.status),
                    ],
                  ),
                  if (project.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      project.description!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final tag in project.techTags)
                        Chip(
                          label: Text(tag),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  '$openTasks',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '進行中任務',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetail extends ConsumerWidget {
  const _ProjectDetail({
    required this.project,
    required this.tasks,
    required this.projects,
  });

  final Project project;
  final List<Task> tasks;
  final List<Project> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectTasks = tasks
        .where((task) => task.projectId == project.id)
        .toList();
    final openTasks = projectTasks
        .where((task) => task.status != TaskStatus.done.name)
        .toList();
    final doneTasks = projectTasks
        .where((task) => task.status == TaskStatus.done.name)
        .toList();
    final color = Color(
      int.parse(project.color.substring(1), radix: 16) + 0xff000000,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          project.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(status: project.status),
                    ],
                  ),
                  if (project.description != null)
                    Text(
                      project.description!,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(label: '待辦', count: openTasks.length),
        for (final task in openTasks)
          TaskItem(
            task: task,
            projects: projects,
            onToggleDone: (done) => ref
                .read(databaseProvider)
                .updateTaskStatus(
                  task.id,
                  done ? TaskStatus.done : TaskStatus.todo,
                ),
          ),
        if (doneTasks.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionHeader(label: '已完成', count: doneTasks.length),
          for (final task in doneTasks)
            TaskItem(
              task: task,
              projects: projects,
              onToggleDone: (done) => ref
                  .read(databaseProvider)
                  .updateTaskStatus(
                    task.id,
                    done ? TaskStatus.done : TaskStatus.todo,
                  ),
            ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final spec = switch (status) {
      'paused' => ('暫停', const Color(0xfffff3e0), AppColors.orange),
      'archived' => ('已封存', const Color(0xfff5f5f5), AppColors.mutedText),
      _ => ('進行中', const Color(0xffe8f8ee), AppColors.green),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          spec.$1,
          style: TextStyle(
            color: spec.$3,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
