import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/local/database.dart';
import '../../shared/providers/database_provider.dart';
import '../notifications/local_notification_service.dart';
import 'pomodoro_controller.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  PomodoroController? _controller;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final prefs = ref.watch(preferencesProvider);

    return tasks.when(
      data: (taskItems) => prefs.when(
        data: (preference) {
          final activeTask = taskItems.firstWhere(
            (task) => task.status != TaskStatus.done.name,
            orElse: () => taskItems.first,
          );
          final settings = PomodoroSettings(
            workDuration: Duration(minutes: preference.workDuration),
            shortBreakDuration: Duration(
              minutes: preference.shortBreakDuration,
            ),
            longBreakDuration: Duration(minutes: preference.longBreakDuration),
            longBreakInterval: preference.longBreakInterval,
          );
          _controller ??= PomodoroController(
            settings: settings,
            now: DateTime.now,
            onComplete: _recordCompletion,
          );

          return _PomodoroContent(
            task: activeTask,
            state: _controller!.state,
            onStart: () => _start(activeTask.id),
            onPause: () => setState(_controller!.pause),
            onResume: () => setState(_controller!.resume),
            onAbandon: () => setState(_controller!.abandon),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('設定載入失敗：$error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('任務載入失敗：$error')),
    );
  }

  void _start(String taskId) {
    setState(() => _controller!.startWork(taskId: taskId));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() => _controller!.recalculate());
    });
  }

  Future<void> _recordCompletion(PomodoroCompletion completion) async {
    final task = await ref.read(databaseProvider).getTask(completion.taskId);
    await ref
        .read(databaseProvider)
        .addPomodoroSession(
          taskId: completion.taskId,
          startedAt: completion.startedAt,
          endedAt: completion.endedAt,
          durationMinutes: completion.duration.inMinutes,
          type: PomodoroSessionType.work,
          completed: true,
        );
    await LocalNotificationService.instance.showPomodoroComplete(
      taskTitle: task.title,
    );
  }
}

class _PomodoroContent extends StatelessWidget {
  const _PomodoroContent({
    required this.task,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onAbandon,
  });

  final Task task;
  final PomodoroState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final progress = state.total == Duration.zero
        ? 0.0
        : 1 - state.remaining.inMilliseconds / state.total.inMilliseconds;

    return ListView(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 48),
      children: [
        Text(
          '番茄鐘',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '以系統時間差計算，背景喚醒後仍會校準',
          style: TextStyle(color: AppColors.mutedText, fontSize: 13),
        ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 256,
            height: 256,
            child: CustomPaint(
              painter: _RingPainter(progress: progress.clamp(0, 1)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(state.remaining),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 46,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _phaseLabel(state.phase),
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '目前任務',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${task.actualPomodoros}/${task.estimatedPomodoros} 番茄',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: _Controls(
            state: state,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onAbandon: onAbandon,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _phaseLabel(PomodoroPhase phase) {
    return switch (phase) {
      PomodoroPhase.working => '工作中',
      PomodoroPhase.paused => '暫停',
      PomodoroPhase.breakReady => '準備休息',
      PomodoroPhase.shortBreak => '短休',
      PomodoroPhase.longBreak => '長休',
      PomodoroPhase.ready => '就緒',
    };
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onAbandon,
  });

  final PomodoroState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: switch (state.phase) {
        PomodoroPhase.ready => [
          FilledButton(onPressed: onStart, child: const Text('開始專注')),
        ],
        PomodoroPhase.working => [
          FilledButton(onPressed: onPause, child: const Text('暫停')),
          OutlinedButton(onPressed: onAbandon, child: const Text('放棄')),
        ],
        PomodoroPhase.paused => [
          FilledButton(onPressed: onResume, child: const Text('繼續')),
          OutlinedButton(onPressed: onAbandon, child: const Text('放棄')),
        ],
        PomodoroPhase.breakReady => [
          FilledButton(onPressed: onAbandon, child: const Text('完成')),
        ],
        _ => [OutlinedButton(onPressed: onAbandon, child: const Text('重置'))],
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = AppColors.border;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
