import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      icon: Icons.timer_rounded,
      title: l10n.navFocus,
      description: l10n.focusDesc,
      phase: 4,
    );
  }
}
