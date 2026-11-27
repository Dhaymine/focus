import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus/features/pomodoro/domain/timer_config.dart';
import 'package:focus/features/pomodoro/domain/timer_engine.dart';
import 'package:focus/features/pomodoro/domain/timer_plan.dart';
import 'package:focus/features/pomodoro/domain/timer_snapshot.dart';

const _min = 60000;

void main() {
  const base = TimerConfig(
    studyMinutes: 1,
    shortBreakMinutes: 1,
    longBreakMinutes: 1,
    sessionsBeforeLongBreak: 2,
    cycles: 1,
  );

  test('plan matches 50/10/50/10/50/30 example when repeating', () {
    const cfg = TimerConfig(
      studyMinutes: 50,
      shortBreakMinutes: 10,
      longBreakMinutes: 30,
      sessionsBeforeLongBreak: 3,
      cycles: 1,
      autoRepeat: true,
    );
    final plan = TimerPlan.fromConfig(cfg);
    expect(plan.segments.map((s) => s.type).toList(), [
      SegmentType.study,
      SegmentType.shortBreak,
      SegmentType.study,
      SegmentType.shortBreak,
      SegmentType.study,
      SegmentType.longBreak,
    ]);
    expect(plan.segments.map((s) => s.durationMs).toList(),
        [50, 10, 50, 10, 50, 30].map((m) => m * _min).toList());
  });

  test('plan has no trailing break when not repeating', () {
    final plan = TimerPlan.fromConfig(base);
    expect(plan.length, 3);
    expect(plan.segments.last.type, SegmentType.study);
  });

  test('sync does nothing before the segment ends', () {
    final s = TimerEngine.start(base, 0);
    final r = TimerEngine.sync(s, 30000);
    expect(r.records, isEmpty);
    expect(r.snapshot.status, TimerStatus.running);
    expect(r.snapshot.remainingMs(30000), 30000);
  });

  test('sync fast-forwards to the next segment', () {
    final s = TimerEngine.start(base, 0);
    final r = TimerEngine.sync(s, 90000);
    expect(r.records.length, 1);
    expect(r.records.first.type, SegmentType.study);
    expect(r.records.first.completed, isTrue);
    expect(r.lastCompleted, SegmentType.study);
    expect(r.snapshot.segmentIndex, 1);
    expect(r.snapshot.status, TimerStatus.running);
    expect(r.snapshot.remainingMs(90000), 30000);
  });

  test('pause keeps remaining time and resume recomputes the end', () {
    final s = TimerEngine.start(base, 0);
    final p = TimerEngine.pause(s, 10000);
    expect(p.status, TimerStatus.paused);
    expect(p.remainingMsAtPause, 50000);
    final r = TimerEngine.resume(p, 100000);
    expect(r.status, TimerStatus.running);
    expect(r.segmentEndsAtMs, 150000);
  });

  test('without automatic transitions the next segment waits', () {
    final cfg = base.copyWith(autoTransition: false);
    final s = TimerEngine.start(cfg, 0);
    final r = TimerEngine.sync(s, 61000);
    expect(r.snapshot.status, TimerStatus.paused);
    expect(r.snapshot.awaitingNext, isTrue);
    expect(r.snapshot.segmentIndex, 1);
    expect(r.snapshot.remainingMsAtPause, _min);
  });

  test('finishing the plan returns to idle with finished flag', () {
    final cfg = base.copyWith(sessionsBeforeLongBreak: 1);
    final s = TimerEngine.start(cfg, 0);
    final r = TimerEngine.sync(s, 61000);
    expect(r.records.length, 1);
    expect(r.snapshot.status, TimerStatus.idle);
    expect(r.snapshot.finished, isTrue);
    expect(r.planFinished, isTrue);
  });

  test('upcoming boundaries follow the plan', () {
    final s = TimerEngine.start(base, 0);
    final b = TimerEngine.upcomingBoundaries(s);
    expect(b.map((e) => e.atMs).toList(), [60000, 120000, 180000]);
    expect(b.last.nextType, isNull);
  });

  test('snapshot survives a JSON round trip', () {
    final s = TimerEngine.start(base, 5000);
    final parsed = TimerSnapshot.tryParse(jsonEncode(s.toJson()));
    expect(parsed, isNotNull);
    expect(parsed!.status, TimerStatus.running);
    expect(parsed.segmentEndsAtMs, s.segmentEndsAtMs);
    expect(parsed.config.studyMinutes, 1);
  });
}
