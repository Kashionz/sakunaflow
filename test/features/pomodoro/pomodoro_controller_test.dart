import 'package:flutter_test/flutter_test.dart';
import 'package:sakunaflow/features/pomodoro/pomodoro_controller.dart';

void main() {
  test(
    'work session uses wall-clock deltas so background ticks stay accurate',
    () {
      var now = DateTime(2026, 4, 20, 10);
      final completed = <PomodoroCompletion>[];
      final controller = PomodoroController(
        settings: const PomodoroSettings(
          workDuration: Duration(minutes: 25),
          shortBreakDuration: Duration(minutes: 5),
          longBreakDuration: Duration(minutes: 15),
          longBreakInterval: 4,
        ),
        now: () => now,
        onComplete: completed.add,
      );

      controller.startWork(taskId: 'task-1');
      now = now.add(const Duration(minutes: 10, seconds: 30));
      controller.recalculate();

      expect(controller.state.phase, PomodoroPhase.working);
      expect(
        controller.state.remaining,
        const Duration(minutes: 14, seconds: 30),
      );
    },
  );

  test('pause and resume preserve remaining duration', () {
    var now = DateTime(2026, 4, 20, 10);
    final controller = PomodoroController(
      settings: const PomodoroSettings(
        workDuration: Duration(minutes: 25),
        shortBreakDuration: Duration(minutes: 5),
        longBreakDuration: Duration(minutes: 15),
        longBreakInterval: 4,
      ),
      now: () => now,
      onComplete: (_) {},
    );

    controller.startWork(taskId: 'task-1');
    now = now.add(const Duration(minutes: 6));
    controller.pause();
    now = now.add(const Duration(minutes: 30));
    controller.recalculate();

    expect(controller.state.phase, PomodoroPhase.paused);
    expect(controller.state.remaining, const Duration(minutes: 19));

    controller.resume();
    now = now.add(const Duration(minutes: 4));
    controller.recalculate();

    expect(controller.state.phase, PomodoroPhase.working);
    expect(controller.state.remaining, const Duration(minutes: 15));
  });

  test('completion callback fires once and advances to break-ready state', () {
    var now = DateTime(2026, 4, 20, 10);
    final completed = <PomodoroCompletion>[];
    final controller = PomodoroController(
      settings: const PomodoroSettings(
        workDuration: Duration(minutes: 25),
        shortBreakDuration: Duration(minutes: 5),
        longBreakDuration: Duration(minutes: 15),
        longBreakInterval: 4,
      ),
      now: () => now,
      onComplete: completed.add,
    );

    controller.startWork(taskId: 'task-1');
    now = now.add(const Duration(minutes: 26));
    controller.recalculate();
    controller.recalculate();

    expect(completed, hasLength(1));
    expect(completed.single.taskId, 'task-1');
    expect(completed.single.duration, const Duration(minutes: 25));
    expect(controller.state.phase, PomodoroPhase.breakReady);
    expect(controller.state.remaining, const Duration(minutes: 5));
  });
}
