import 'timer_config.dart';

enum SegmentType { study, shortBreak, longBreak }

class PlanSegment {
  const PlanSegment({
    required this.type,
    required this.durationMs,
    required this.session,
    required this.cycle,
  });

  final SegmentType type;
  final int durationMs;

  /// 1-based study session index inside the cycle (breaks keep the preceding one).
  final int session;

  /// 1-based cycle index.
  final int cycle;

  bool get isStudy => type == SegmentType.study;
}

class TimerPlan {
  const TimerPlan(this.segments);

  final List<PlanSegment> segments;

  int get length => segments.length;

  factory TimerPlan.fromConfig(TimerConfig c) {
    final list = <PlanSegment>[];
    const minute = 60000;
    for (var cycle = 1; cycle <= c.cycles; cycle++) {
      for (var s = 1; s <= c.sessionsBeforeLongBreak; s++) {
        list.add(PlanSegment(
          type: SegmentType.study,
          durationMs: c.studyMinutes * minute,
          session: s,
          cycle: cycle,
        ));
        final isLastSession = s == c.sessionsBeforeLongBreak;
        final isVeryLast = isLastSession && cycle == c.cycles;
        // Nothing follows the very last study session unless the plan repeats.
        if (isVeryLast && !c.autoRepeat) continue;
        list.add(PlanSegment(
          type: isLastSession ? SegmentType.longBreak : SegmentType.shortBreak,
          durationMs:
              (isLastSession ? c.longBreakMinutes : c.shortBreakMinutes) *
                  minute,
          session: s,
          cycle: cycle,
        ));
      }
    }
    return TimerPlan(list);
  }
}
