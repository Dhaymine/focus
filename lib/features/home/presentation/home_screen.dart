import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/page_body.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/stat_tile.dart';

/// Dashboard skeleton. Values are placeholders until Phases 4 to 6 provide data.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final localeName = Localizations.localeOf(context).toString();
    final today = DateFormat.yMMMMEEEEd(localeName).format(DateTime.now());

    const double progress = 0; // placeholder (0 to 1)

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
                          l10n.goalOf(l10n.durationHm(2, 0)),
                          style:
                              theme.textTheme.bodyMedium?.copyWith(color: muted),
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
                    l10n.statusIdle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/focus'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.quickStartPomodoro),
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
              value: l10n.durationHm(0, 0),
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
                    child: const LinearProgressIndicator(
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
