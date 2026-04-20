import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final projects = ref.watch(projectsProvider);

    return tasks.when(
      data: (taskItems) => projects.when(
        data: (projectItems) =>
            _StatsContent(tasks: taskItems, projects: projectItems),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('專案載入失敗：$error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('任務載入失敗：$error')),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.tasks, required this.projects});

  final List<Task> tasks;
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final done = tasks
        .where((task) => task.status == TaskStatus.done.name)
        .length;
    final progress = tasks
        .where((task) => task.status == TaskStatus.inProgress.name)
        .length;
    final bars = [3, 5, 2, 4, 1, 0, 0];

    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
      children: [
        Text(
          '統計',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _Metric(value: done, label: '完成任務', color: AppColors.green),
            const SizedBox(width: 10),
            _Metric(value: progress, label: '進行中', color: AppColors.orange),
            const SizedBox(width: 10),
            _Metric(
              value: projects.length,
              label: '專案',
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          '本週任務完成趨勢',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].toDouble(),
                        width: 18,
                        color: i == 4
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '進行中專案',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final project in projects)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 5,
              backgroundColor: Color(
                int.parse(project.color.substring(1), radix: 16) + 0xff000000,
              ),
            ),
            title: Text(project.name),
            trailing: Text(
              '${tasks.where((task) => task.projectId == project.id && task.status != TaskStatus.done.name).length} 個任務',
            ),
          ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: const TextStyle(color: AppColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}
