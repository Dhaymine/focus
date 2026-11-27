import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../pomodoro/data/timer_controller.dart';
import '../../pomodoro/domain/timer_snapshot.dart';
import '../../pomodoro/presentation/segment_labels.dart';
import '../../pomodoro/presentation/timer_view.dart';
import '../../sounds/data/audio_service.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alarm = ref.watch(alarmActiveProvider);

    const timer = LiveTimerView(height: 380);
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _InfoCard(),
        SizedBox(height: 16),
        _Controls(),
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (alarm) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.alarmRinging)),
                    FilledButton(
                      onPressed:
                          ref.read(timerControllerProvider.notifier).stopAlarm,
                      child: Text(l10n.stopAlarm),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 860) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 3, child: timer),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: side),
                    ],
                  );
                }
                return Column(
                  children: [timer, const SizedBox(height: 16), side],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/timer-settings'),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(l10n.timerSettings),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/sound-settings'),
                  icon: const Icon(Icons.music_note_rounded),
                  label: Text(l10n.soundSettings),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/appearance'),
                  icon: const Icon(Icons.palette_outlined),
                  label: Text(l10n.appearanceSettings),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/timer-fullscreen'),
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(l10n.fullScreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final snap = ref.watch(timerControllerProvider);
    final nowMs = ref.watch(timerClockProvider).valueOrNull ??
        DateTime.now().millisecondsSinceEpoch;

    final seg = snap.segment;
    final next = snap.nextSegment;
    final nextText = next == null
        ? l10n.lastSession
        : l10n.nextSession(
            segmentName(l10n, next.type),
            l10n.minutesShort((next.durationMs / 60000).round()),
          );
    final overall = snap.plan.length == 0
        ? 0.0
        : ((snap.segmentIndex + snap.progress(nowMs)) / snap.plan.length)
            .clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(label: Text(statusText(l10n, snap))),
          const SizedBox(height: 12),
          Text(
            l10n.currentSession,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          Text(
            segmentName(l10n, seg.type),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(nextText, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            '${l10n.sessionProgress(seg.session, snap.config.sessionsBeforeLongBreak)}'
            ' · ${l10n.cycleProgress(seg.cycle, snap.config.cycles)}',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: overall, minHeight: 8),
          ),
        ],
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(timerControllerProvider);
    final c = ref.read(timerControllerProvider.notifier);

    Widget filled(IconData icon, String text, VoidCallback onPressed) =>
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(text),
        );
    Widget outlined(IconData icon, String text, VoidCallback onPressed) =>
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(text),
        );

    final buttons = <Widget>[];
    switch (snap.status) {
      case TimerStatus.idle:
        buttons.add(
            filled(Icons.play_arrow_rounded, l10n.actionStart, c.start));
      case TimerStatus.running:
        buttons.addAll([
          filled(Icons.pause_rounded, l10n.actionPause, c.pause),
          outlined(Icons.replay_rounded, l10n.actionRestart, c.restart),
          outlined(Icons.skip_next_rounded, l10n.actionSkip, c.skip),
          outlined(Icons.stop_rounded, l10n.actionStop, c.stop),
        ]);
      case TimerStatus.paused:
        buttons.add(filled(
          Icons.play_arrow_rounded,
          snap.awaitingNext ? l10n.actionStartNext : l10n.actionResume,
          c.resume,
        ));
        if (!snap.awaitingNext) {
          buttons.add(
              outlined(Icons.replay_rounded, l10n.actionRestart, c.restart));
        }
        buttons.addAll([
          outlined(Icons.skip_next_rounded, l10n.actionSkip, c.skip),
          outlined(Icons.stop_rounded, l10n.actionStop, c.stop),
        ]);
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }
}
