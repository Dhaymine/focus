import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      icon: Icons.bar_chart_rounded,
      title: l10n.navStatistics,
      description: l10n.statisticsDesc,
      phase: 8,
    );
  }
}
