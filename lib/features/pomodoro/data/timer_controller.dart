import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/app_settings.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/preferences_provider.dart';
import '../../sounds/data/audio_service.dart';
import '../../sounds/data/sound_settings_controller.dart';
import '../../sounds/domain/sound_settings.dart';
import '../domain/segment_record.dart';
import '../domain/timer_config.dart';
import '../domain/timer_engine.dart';
import '../domain/timer_plan.dart';
import '../domain/timer_snapshot.dart';
import 'active_task_controller.dart';
import 'history_repository.dart';
import 'timer_config_controller.dart';

const _snapshotKey = 'timer_snapshot';
const _askedExactKey = 'asked_exact_alarm';

/// Emits "now" (epoch ms) four times per second. Only used to repaint the UI
/// and to detect segment boundaries; the source of truth is the snapshot.
final timerClockProvider = StreamProvider<int>((ref) {
  return Stream<int>.periodic(
    const Duration(milliseconds: 250),
    (_) => DateTime.now().millisecondsSinceEpoch,
  );
});

class TimerController extends Notifier<TimerSnapshot> {
  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  TimerSnapshot build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final config = ref.read(timerConfigProvider);

    var snap = TimerSnapshot.tryParse(prefs.getString(_snapshotKey)) ??
        TimerEngine.idle(config);

    // Recover after an app restart: fast-forward elapsed segments.
    final res = TimerEngine.sync(snap, _now());
    snap = res.snapshot;
    if (snap.status == TimerStatus.idle && !snap.finished) {
      snap = TimerEngine.idle(config);
    }

    ref.listen<AsyncValue<int>>(timerClockProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null) _onTick(v);
    });

    ref.listen<TimerConfig>(timerConfigProvider, (_, next) {
      if (state.status == TimerStatus.idle) {
        _setState(TimerEngine.idle(next));
      }
    });

    final recovered = res.records;
    final planFinished = res.planFinished;
    Future.microtask(() {
      _saveRecords(recovered);
      if (planFinished) _clearActiveTask();
      _persist();
      _scheduleNotifications();
    });
    return snap;
  }

  // ---------------------------------------------------------------- helpers

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_snapshotKey, jsonEncode(state.toJson()));
  }

  void _setState(TimerSnapshot s) {
    state = s;
    _persist();
  }

  /// Stores finished segments, linked to the active task (if any).
  void _saveRecords(List<SegmentRecord> records) {
    if (records.isEmpty) return;
    final taskId = ref.read(activeTaskIdProvider);
    unawaited(
      ref.read(historyRepositoryProvider).addAll(records, taskId: taskId),
    );
  }

  void _record(SegmentRecord? r) {
    if (r != null) _saveRecords([r]);
  }

  void _clearActiveTask() {
    unawaited(ref.read(activeTaskIdProvider.notifier).set(null));
  }

  AppLocalizations _l10n() {
    final locale =
        ref.read(localeProvider) ?? PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.delegate.isSupported(locale);
    return lookupAppLocalizations(supported ? locale : const Locale('en'));
  }

  bool _inForeground() {
    if (!(Platform.isAndroid || Platform.isIOS)) return true;
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  void _vibrate() {
    unawaited(Future(() async {
      for (var i = 0; i < 3; i++) {
        await HapticFeedback.vibrate();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }));
  }

  void _playStart(SegmentType type) {
    final s = ref.read(soundSettingsProvider);
    final e = type == SegmentType.study
        ? SoundEvent.studyStart
        : SoundEvent.breakStart;
    unawaited(ref.read(audioServiceProvider).playOnce(s.idFor(e), s));
  }

  void _alertBoundary(SegmentType finished) {
    if (!_inForeground()) return; // the system notification covers this case
    final s = ref.read(soundSettingsProvider);
    final e = finished == SegmentType.study
        ? SoundEvent.studyEnd
        : SoundEvent.breakEnd;
    unawaited(ref.read(audioServiceProvider).playAlarm(s.idFor(e), s));
    if (s.vibrate) _vibrate();
  }

  void _scheduleNotifications() {
    final s = state;
    final l10n = _l10n();
    final alerts = <ScheduledAlert>[];
    for (final b in TimerEngine.upcomingBoundaries(s)) {
      final String title;
      final String body;
      if (b.nextType == null) {
        title = l10n.notifPlanDone;
        body = l10n.notifPlanDoneBody;
      } else if (b.finished == SegmentType.study) {
        title = l10n.notifStudyDone;
        body = l10n.notifStudyDoneBody;
      } else {
        title = l10n.notifBreakDone;
        body = l10n.notifBreakDoneBody;
      }
      alerts.add(ScheduledAlert(atMs: b.atMs, title: title, body: body));
    }
    final vibrate = ref.read(soundSettingsProvider).vibrate;
    unawaited(
      ref.read(notificationServiceProvider).schedule(alerts, vibrate: vibrate),
    );
  }

  void _onTick(int now) {
    final s = state;
    if (s.status != TimerStatus.running || now < s.segmentEndsAtMs) return;
    final res = TimerEngine.sync(s, now);
    _setState(res.snapshot);
    _saveRecords(res.records);
    if (res.planFinished) _clearActiveTask();
    if (res.lastCompleted != null) _alertBoundary(res.lastCompleted!);
    _scheduleNotifications();
  }

  // ----------------------------------------------------------------- actions

  /// Starts the plan. [taskId] links the study time to a task (null = free).
  Future<void> start({String? taskId}) async {
    unawaited(ref.read(activeTaskIdProvider.notifier).set(taskId));
    final cfg = ref.read(timerConfigProvider);
    _setState(TimerEngine.start(cfg, _now()));
    _playStart(state.segment.type);

    final prefs = ref.read(sharedPreferencesProvider);
    final asked = prefs.getBool(_askedExactKey) ?? false;
    await ref
        .read(notificationServiceProvider)
        .requestPermissions(askExact: !asked);
    await prefs.setBool(_askedExactKey, true);
    _scheduleNotifications();
  }

  void pause() {
    _setState(TimerEngine.pause(state, _now()));
    _scheduleNotifications();
  }

  void resume() {
    final wasWaiting = state.awaitingNext;
    _setState(TimerEngine.resume(state, _now()));
    if (wasWaiting) _playStart(state.segment.type);
    _scheduleNotifications();
  }

  void stop() {
    final r = TimerEngine.stop(state, _now(), ref.read(timerConfigProvider));
    _record(r.record);
    _setState(r.snapshot);
    _clearActiveTask();
    _scheduleNotifications();
    stopAlarm();
  }

  void restart() {
    final r = TimerEngine.restart(state, _now());
    _record(r.record);
    _setState(r.snapshot);
    _scheduleNotifications();
  }

  void skip() {
    if (state.status == TimerStatus.idle) return;
    final r = TimerEngine.skip(state, _now());
    _record(r.record);
    _setState(r.snapshot);
    _scheduleNotifications();
    if (r.finished) {
      _clearActiveTask();
    } else {
      _playStart(r.snapshot.segment.type);
    }
  }

  void stopAlarm() {
    unawaited(ref.read(audioServiceProvider).stopAlarm());
  }
}

final timerControllerProvider =
    NotifierProvider<TimerController, TimerSnapshot>(TimerController.new);
