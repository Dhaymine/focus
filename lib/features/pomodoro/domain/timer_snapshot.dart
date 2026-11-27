import 'dart:convert';
import 'dart:math' as math;

import 'timer_config.dart';
import 'timer_plan.dart';

enum TimerStatus { idle, running, paused }

/// Persisted timer state. Time is stored as absolute timestamps, never as ticks.
class TimerSnapshot {
  TimerSnapshot({
    required this.status,
    required this.config,
    this.segmentIndex = 0,
    this.segmentStartedAtMs = 0,
    this.segmentEndsAtMs = 0,
    this.remainingMsAtPause = 0,
    this.awaitingNext = false,
    this.finished = false,
  });

  final TimerStatus status;
  final TimerConfig config;
  final int segmentIndex;
  final int segmentStartedAtMs;

  /// Valid while running.
  final int segmentEndsAtMs;

  /// Valid while paused or idle.
  final int remainingMsAtPause;

  /// Paused only because the previous segment ended and automatic
  /// transitions are off.
  final bool awaitingNext;

  /// The whole plan has just been completed.
  final bool finished;

  late final TimerPlan plan = TimerPlan.fromConfig(config);

  PlanSegment get segment => plan.segments[segmentIndex];

  int? get nextIndex {
    final n = segmentIndex + 1;
    if (n < plan.length) return n;
    return config.autoRepeat ? 0 : null;
  }

  PlanSegment? get nextSegment {
    final i = nextIndex;
    return i == null ? null : plan.segments[i];
  }

  int remainingMs(int nowMs) {
    if (status == TimerStatus.running) {
      return math.max(0, segmentEndsAtMs - nowMs);
    }
    return remainingMsAtPause;
  }

  double progress(int nowMs) {
    if (status == TimerStatus.idle) return 0;
    final d = segment.durationMs;
    if (d <= 0) return 0;
    return (1 - remainingMs(nowMs) / d).clamp(0.0, 1.0);
  }

  TimerSnapshot copyWith({
    TimerStatus? status,
    TimerConfig? config,
    int? segmentIndex,
    int? segmentStartedAtMs,
    int? segmentEndsAtMs,
    int? remainingMsAtPause,
    bool? awaitingNext,
    bool? finished,
  }) {
    return TimerSnapshot(
      status: status ?? this.status,
      config: config ?? this.config,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      segmentStartedAtMs: segmentStartedAtMs ?? this.segmentStartedAtMs,
      segmentEndsAtMs: segmentEndsAtMs ?? this.segmentEndsAtMs,
      remainingMsAtPause: remainingMsAtPause ?? this.remainingMsAtPause,
      awaitingNext: awaitingNext ?? this.awaitingNext,
      finished: finished ?? this.finished,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'config': config.toJson(),
        'index': segmentIndex,
        'startedAt': segmentStartedAtMs,
        'endsAt': segmentEndsAtMs,
        'remaining': remainingMsAtPause,
        'awaitingNext': awaitingNext,
        'finished': finished,
      };

  static TimerSnapshot? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final cfg =
          TimerConfig.fromJson((j['config'] as Map).cast<String, dynamic>());
      final len = TimerPlan.fromConfig(cfg).length;
      int geti(String k) => (j[k] as num?)?.toInt() ?? 0;
      final status = TimerStatus.values.firstWhere(
        (e) => e.name == j['status'],
        orElse: () => TimerStatus.idle,
      );
      return TimerSnapshot(
        status: status,
        config: cfg,
        segmentIndex: geti('index').clamp(0, len - 1),
        segmentStartedAtMs: geti('startedAt'),
        segmentEndsAtMs: geti('endsAt'),
        remainingMsAtPause: geti('remaining'),
        awaitingNext: j['awaitingNext'] == true,
        finished: j['finished'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
