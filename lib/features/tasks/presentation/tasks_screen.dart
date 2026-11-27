import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      icon: Icons.check_circle_rounded,
      title: l10n.navTasks,
      description: l10n.tasksDesc,
      phase: 5,
    );
  }
}
