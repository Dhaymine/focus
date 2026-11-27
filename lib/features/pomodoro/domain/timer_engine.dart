import 'segment_record.dart';
import 'timer_config.dart';
import 'timer_plan.dart';
import 'timer_snapshot.dart';

class Boundary {
  const Boundary({required this.atMs, required this.finished, this.nextType});

  final int atMs;
  final SegmentType finished;

  /// null when the whole plan ends at this boundary.
  final SegmentType? nextType;
}

class SyncResult {
  const SyncResult({
    required this.snapshot,
    required this.records,
    this.lastCompleted,
    this.planFinished = false,
  });

  final TimerSnapshot snapshot;
  final List<SegmentRecord> records;
  final SegmentType? lastCompleted;
  final bool planFinished;
}

/// Pure, clock-injected state machine. No timers, no I/O.
class TimerEngine {
  TimerEngine._();

  static TimerSnapshot idle(TimerConfig c) {
    final plan = TimerPlan.fromConfig(c);
    return TimerSnapshot(
      status: TimerStatus.idle,
      config: c,
      remainingMsAtPause: plan.segments.first.durationMs,
    );
  }

  static TimerSnapshot start(TimerConfig c, int nowMs) {
    final first = TimerPlan.fromConfig(c).segments.first;
    return TimerSnapshot(
      status: TimerStatus.running,
      config: c,
      segmentStartedAtMs: nowMs,
      segmentEndsAtMs: nowMs + first.durationMs,
      remainingMsAtPause: first.durationMs,
    );
  }

  static TimerSnapshot pause(TimerSnapshot s, int nowMs) {
    if (s.status != TimerStatus.running) return s;
    return s.copyWith(
      status: TimerStatus.paused,
      remainingMsAtPause: s.remainingMs(nowMs),
    );
  }

  static TimerSnapshot resume(TimerSnapshot s, int nowMs) {
    if (s.status != TimerStatus.paused) return s;
    return s.copyWith(
      status: TimerStatus.running,
      segmentEndsAtMs: nowMs + s.remainingMsAtPause,
      segmentStartedAtMs: s.awaitingNext ? nowMs : s.segmentStartedAtMs,
      awaitingNext: false,
    );
  }

  static SegmentRecord? _partial(TimerSnapshot s, int nowMs) {
    if (s.status == TimerStatus.idle || s.awaitingNext) return null;
    final planned = s.segment.durationMs;
    final actual = planned - s.remainingMs(nowMs);
    if (actual < 5000) return null;
    return SegmentRecord(
      type: s.segment.type,
      startMs: s.segmentStartedAtMs,
      endMs: nowMs,
      plannedMs: planned,
      actualMs: actual,
      completed: false,
    );
  }

  static ({TimerSnapshot snapshot, SegmentRecord? record}) restart(
      TimerSnapshot s, int nowMs) {
    if (s.status == TimerStatus.idle) return (snapshot: s, record: null);
    final record = _partial(s, nowMs);
    final d = s.segment.durationMs;
    return (
      snapshot: s.copyWith(
        status: TimerStatus.running,
        segmentStartedAtMs: nowMs,
        segmentEndsAtMs: nowMs + d,
        remainingMsAtPause: d,
        awaitingNext: false,
      ),
      record: record,
    );
  }

  static ({TimerSnapshot snapshot, SegmentRecord? record}) stop(
      TimerSnapshot s, int nowMs, TimerConfig config) {
    return (snapshot: idle(config), record: _partial(s, nowMs));
  }

  static ({TimerSnapshot snapshot, SegmentRecord? record, bool finished}) skip(
      TimerSnapshot s, int nowMs) {
    if (s.status == TimerStatus.idle) {
      return (snapshot: s, record: null, finished: false);
    }
    final record = _partial(s, nowMs);
    final ni = s.nextIndex;
    if (ni == null) {
      return (
        snapshot: idle(s.config).copyWith(finished: true),
        record: record,
        finished: true,
      );
    }
    final next = s.plan.segments[ni];
    return (
      snapshot: TimerSnapshot(
        status: TimerStatus.running,
        config: s.config,
        segmentIndex: ni,
        segmentStartedAtMs: nowMs,
        segmentEndsAtMs: nowMs + next.durationMs,
        remainingMsAtPause: next.durationMs,
      ),
      record: record,
      finished: false,
    );
  }

  /// Fast-forwards through every segment boundary that has already passed.
  /// Safe to call on every tick and after an app restart.
  static SyncResult sync(TimerSnapshot s, int nowMs) {
    var cur = s;
    final records = <SegmentRecord>[];
    SegmentType? last;
    var finished = false;
    var guard = 0;

    while (cur.status == TimerStatus.running &&
        nowMs >= cur.segmentEndsAtMs &&
        guard < 2000) {
      guard++;
      final seg = cur.segment;
      records.add(SegmentRecord(
        type: seg.type,
        startMs: cur.segmentStartedAtMs,
        endMs: cur.segmentEndsAtMs,
        plannedMs: seg.durationMs,
        actualMs: seg.durationMs,
        completed: true,
      ));
      last = seg.type;

      final ni = cur.nextIndex;
      if (ni == null) {
        cur = idle(cur.config).copyWith(finished: true);
        finished = true;
        break;
      }
      final next = cur.plan.segments[ni];
      if (cur.config.autoTransition) {
        final startMs = cur.segmentEndsAtMs;
        cur = TimerSnapshot(
          status: TimerStatus.running,
          config: cur.config,
          segmentIndex: ni,
          segmentStartedAtMs: startMs,
          segmentEndsAtMs: startMs + next.durationMs,
          remainingMsAtPause: next.durationMs,
        );
      } else {
        cur = TimerSnapshot(
          status: TimerStatus.paused,
          config: cur.config,
          segmentIndex: ni,
          remainingMsAtPause: next.durationMs,
          awaitingNext: true,
        );
      }
    }

    return SyncResult(
      snapshot: cur,
      records: records,
      lastCompleted: last,
      planFinished: finished,
    );
  }

  /// Upcoming segment ends, used to schedule system notifications.
  static List<Boundary> upcomingBoundaries(TimerSnapshot s, {int max = 8}) {
    if (s.status != TimerStatus.running) return const [];
    final out = <Boundary>[];
    var idx = s.segmentIndex;
    var t = s.segmentEndsAtMs;
    var cfgSnapshot = s;
    for (var i = 0; i < max; i++) {
      final seg = cfgSnapshot.plan.segments[idx];
      final nextIdx = idx + 1 < cfgSnapshot.plan.length
          ? idx + 1
          : (s.config.autoRepeat ? 0 : null);
      out.add(Boundary(
        atMs: t,
        finished: seg.type,
        nextType:
            nextIdx == null ? null : cfgSnapshot.plan.segments[nextIdx].type,
      ));
      if (!s.config.autoTransition || nextIdx == null) break;
      idx = nextIdx;
      t += cfgSnapshot.plan.segments[idx].durationMs;
      cfgSnapshot = s;
    }
    return out;
  }
}
