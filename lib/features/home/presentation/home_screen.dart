import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/page_body.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../pomodoro/data/history_controller.dart';
import '../../pomodoro/data/timer_config_controller.dart';
import '../../pomodoro/data/timer_controller.dart';
import '../../pomodoro/domain/timer_snapshot.dart';
import '../../pomodoro/presentation/segment_labels.dart';

/// Dashboard. Study time and focus status are live; tasks and events stay
/// placeholders until Phases 5 and 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final localeName = Localizations.localeOf(context).toString();
    final today = DateFormat.yMMMMEEEEd(localeName).format(DateTime.now());

    final snap = ref.watch(timerControllerProvider);
    final studyMs = ref.watch(todayStudyMsProvider);
    final goalMin = ref.watch(timerConfigProvider).dailyGoalMinutes;

    final studyMin = studyMs ~/ 60000;
    final double progress =
        goalMin <= 0 ? 0.0 : (studyMin / goalMin).clamp(0.0, 1.0);

    final idle = snap.status == TimerStatus.idle;
    final statusLine = idle
        ? statusText(l10n, snap)
        : '${statusText(l10n, snap)} · ${segmentName(l10n, snap.segment.type)}';

    return PageBody(
      children: [
        AppCard(
          gradient: AppColors.accentGradient,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                today,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 320,
          children: [
            AppCard(
              child: Row(
                children: [
                  ProgressRing(
                    value: progress,
                    size: 110,
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dailyGoal,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.goalOf(
                              l10n.durationHm(goalMin ~/ 60, goalMin % 60)),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.focusStatus,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusLine,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (idle) {
                        ref.read(timerControllerProvider.notifier).start();
                      }
                      context.go('/focus');
                    },
                    icon: Icon(idle
                        ? Icons.play_arrow_rounded
                        : Icons.timer_rounded),
                    label: Text(
                        idle ? l10n.quickStartPomodoro : l10n.openTimer),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 200,
          children: [
            StatTile(
              icon: Icons.schedule_rounded,
              label: l10n.studyTime,
              value: l10n.durationHm(studyMin ~/ 60, studyMin % 60),
            ),
            StatTile(
              icon: Icons.task_alt_rounded,
              label: l10n.completedTasks,
              value: '0',
            ),
            StatTile(
              icon: Icons.event_available_rounded,
              label: l10n.upcomingEvents,
              value: '0',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          minItemWidth: 320,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.upcomingEvents,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noUpcomingEvents,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyProgress,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
