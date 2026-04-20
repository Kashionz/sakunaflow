import 'dart:math' as math;

typedef Clock = DateTime Function();
typedef PomodoroCompletionCallback =
    void Function(PomodoroCompletion completion);

enum PomodoroPhase { ready, working, paused, breakReady, shortBreak, longBreak }

class PomodoroSettings {
  const PomodoroSettings({
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.longBreakInterval,
  });

  final Duration workDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int longBreakInterval;
}

class PomodoroState {
  const PomodoroState({
    required this.phase,
    required this.remaining,
    required this.total,
    required this.completedWorkSessions,
    this.taskId,
  });

  PomodoroState.ready({PomodoroSettings? settings})
    : phase = PomodoroPhase.ready,
      remaining = settings?.workDuration ?? const Duration(minutes: 25),
      total = settings?.workDuration ?? const Duration(minutes: 25),
      completedWorkSessions = 0,
      taskId = null;

  final PomodoroPhase phase;
  final Duration remaining;
  final Duration total;
  final int completedWorkSessions;
  final String? taskId;

  PomodoroState copyWith({
    PomodoroPhase? phase,
    Duration? remaining,
    Duration? total,
    int? completedWorkSessions,
    String? taskId,
    bool clearTask = false,
  }) {
    return PomodoroState(
      phase: phase ?? this.phase,
      remaining: remaining ?? this.remaining,
      total: total ?? this.total,
      completedWorkSessions:
          completedWorkSessions ?? this.completedWorkSessions,
      taskId: clearTask ? null : taskId ?? this.taskId,
    );
  }
}

class PomodoroCompletion {
  const PomodoroCompletion({
    required this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
  });

  final String taskId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
}

class PomodoroController {
  PomodoroController({
    required this.settings,
    required this.now,
    required PomodoroCompletionCallback onComplete,
  }) : _onComplete = onComplete,
       _state = PomodoroState.ready(settings: settings);

  final PomodoroSettings settings;
  final Clock now;
  final PomodoroCompletionCallback _onComplete;

  PomodoroState _state;
  PomodoroPhase? _pausedPhase;
  DateTime? _sessionStartedAt;
  DateTime? _phaseStartedAt;
  Duration _remainingAtPhaseStart = Duration.zero;
  bool _completionSent = false;

  PomodoroState get state => _state;

  void startWork({required String taskId}) {
    final stamp = now();
    _sessionStartedAt = stamp;
    _phaseStartedAt = stamp;
    _remainingAtPhaseStart = settings.workDuration;
    _completionSent = false;
    _pausedPhase = null;
    _state = PomodoroState(
      phase: PomodoroPhase.working,
      remaining: settings.workDuration,
      total: settings.workDuration,
      completedWorkSessions: _state.completedWorkSessions,
      taskId: taskId,
    );
  }

  void pause() {
    recalculate();
    if (_state.phase != PomodoroPhase.working &&
        _state.phase != PomodoroPhase.shortBreak &&
        _state.phase != PomodoroPhase.longBreak) {
      return;
    }
    _pausedPhase = _state.phase;
    _remainingAtPhaseStart = _state.remaining;
    _phaseStartedAt = null;
    _state = _state.copyWith(phase: PomodoroPhase.paused);
  }

  void resume() {
    if (_state.phase != PomodoroPhase.paused || _pausedPhase == null) return;
    _phaseStartedAt = now();
    _remainingAtPhaseStart = _state.remaining;
    _state = _state.copyWith(phase: _pausedPhase);
    _pausedPhase = null;
  }

  void abandon() {
    _sessionStartedAt = null;
    _phaseStartedAt = null;
    _remainingAtPhaseStart = settings.workDuration;
    _completionSent = false;
    _pausedPhase = null;
    _state = PomodoroState.ready(settings: settings);
  }

  void recalculate() {
    if (_phaseStartedAt == null || _state.phase == PomodoroPhase.paused) return;
    if (_state.phase != PomodoroPhase.working &&
        _state.phase != PomodoroPhase.shortBreak &&
        _state.phase != PomodoroPhase.longBreak) {
      return;
    }

    final elapsed = now().difference(_phaseStartedAt!);
    final remaining = _clampRemaining(_remainingAtPhaseStart - elapsed);
    _state = _state.copyWith(remaining: remaining);

    if (remaining > Duration.zero || _state.phase != PomodoroPhase.working) {
      return;
    }
    _completeWorkSession();
  }

  void _completeWorkSession() {
    if (_completionSent || _state.taskId == null || _sessionStartedAt == null) {
      return;
    }
    _completionSent = true;
    final endedAt = _sessionStartedAt!.add(settings.workDuration);
    _onComplete(
      PomodoroCompletion(
        taskId: _state.taskId!,
        startedAt: _sessionStartedAt!,
        endedAt: endedAt,
        duration: settings.workDuration,
      ),
    );

    final completedCount = _state.completedWorkSessions + 1;
    final breakDuration = completedCount % settings.longBreakInterval == 0
        ? settings.longBreakDuration
        : settings.shortBreakDuration;
    _phaseStartedAt = null;
    _remainingAtPhaseStart = breakDuration;
    _state = _state.copyWith(
      phase: PomodoroPhase.breakReady,
      remaining: breakDuration,
      total: breakDuration,
      completedWorkSessions: completedCount,
    );
  }

  Duration _clampRemaining(Duration duration) {
    final micros = math.max(0, duration.inMicroseconds);
    return Duration(microseconds: micros);
  }
}
