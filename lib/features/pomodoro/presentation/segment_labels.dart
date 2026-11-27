import '../../../core/localization/generated/app_localizations.dart';
import '../domain/timer_plan.dart';
import '../domain/timer_snapshot.dart';

String segmentName(AppLocalizations l10n, SegmentType type) => switch (type) {
      SegmentType.study => l10n.sessionStudy,
      SegmentType.shortBreak => l10n.sessionShortBreak,
      SegmentType.longBreak => l10n.sessionLongBreak,
    };

String statusText(AppLocalizations l10n, TimerSnapshot s) {
  switch (s.status) {
    case TimerStatus.idle:
      return s.finished ? l10n.statusFinished : l10n.statusIdle;
    case TimerStatus.running:
      return l10n.statusRunning;
    case TimerStatus.paused:
      return s.awaitingNext ? l10n.statusWaiting : l10n.statusPaused;
  }
}
