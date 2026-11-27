import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class CountdownScreen extends StatelessWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      icon: Icons.event_rounded,
      title: l10n.navCountdown,
      description: l10n.countdownDesc,
      phase: 6,
    );
  }
}
