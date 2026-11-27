import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/number_stepper.dart';
import '../../../shared/widgets/page_body.dart';
import '../data/timer_config_controller.dart';
import '../domain/timer_config.dart';

class TimerSettingsScreen extends ConsumerWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final cfg = ref.watch(timerConfigProvider);
    void update(TimerConfig c) =>
        ref.read(timerConfigProvider.notifier).update(c);

    String minutes(int n) => l10n.minutesShort(n);

    final total = cfg.totalStudyMinutes;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timerSettings)),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              children: [
                NumberStepper(
                  label: l10n.studyDuration,
                  value: cfg.studyMinutes,
                  min: 1,
                  max: 180,
                  step: 5,
                  valueText: minutes(cfg.studyMinutes),
                  onChanged: (v) => update(cfg.copyWith(studyMinutes: v)),
                ),
                NumberStepper(
                  label: l10n.shortBreakDuration,
                  value: cfg.shortBreakMinutes,
                  min: 1,
                  max: 60,
                  valueText: minutes(cfg.shortBreakMinutes),
                  onChanged: (v) => update(cfg.copyWith(shortBreakMinutes: v)),
                ),
                NumberStepper(
                  label: l10n.longBreakDuration,
                  value: cfg.longBreakMinutes,
                  min: 1,
                  max: 120,
                  step: 5,
                  valueText: minutes(cfg.longBreakMinutes),
                  onChanged: (v) => update(cfg.copyWith(longBreakMinutes: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NumberStepper(
                  label: l10n.sessionsBeforeLongBreak,
                  value: cfg.sessionsBeforeLongBreak,
                  min: 1,
                  max: 12,
                  onChanged: (v) =>
                      update(cfg.copyWith(sessionsBeforeLongBreak: v)),
                ),
                NumberStepper(
                  label: l10n.cyclesCount,
                  value: cfg.cycles,
                  min: 1,
                  max: 20,
                  onChanged: (v) => update(cfg.copyWith(cycles: v)),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.totalStudyLabel(l10n.durationHm(total ~/ 60, total % 60)),
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.autoTransitions),
                  subtitle: Text(l10n.autoTransitionsDesc),
                  value: cfg.autoTransition,
                  onChanged: (v) => update(cfg.copyWith(autoTransition: v)),
                ),
                SwitchListTile(
                  title: Text(l10n.autoRepeat),
                  subtitle: Text(l10n.autoRepeatDesc),
                  value: cfg.autoRepeat,
                  onChanged: (v) => update(cfg.copyWith(autoRepeat: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: NumberStepper(
              label: l10n.dailyGoalMinutes,
              value: cfg.dailyGoalMinutes,
              min: 10,
              max: 1440,
              step: 15,
              valueText: minutes(cfg.dailyGoalMinutes),
              onChanged: (v) => update(cfg.copyWith(dailyGoalMinutes: v)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appliesNextStart,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => update(const TimerConfig()),
              icon: const Icon(Icons.restore_rounded),
              label: Text(l10n.resetDefaults),
            ),
          ),
        ],
      ),
    );
  }
}
