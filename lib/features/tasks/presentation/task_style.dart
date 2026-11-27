import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/generated/app_localizations.dart';

Color priorityColor(int priority) => switch (priority) {
      2 => const Color(0xFFEF4444),
      0 => const Color(0xFF3D8BFF),
      _ => const Color(0xFFF59E0B),
    };

String priorityText(AppLocalizations l10n, int priority) => switch (priority) {
      2 => l10n.priorityHigh,
      0 => l10n.priorityLow,
      _ => l10n.priorityMedium,
    };

const categoryColors = <Color>[
  Color(0xFF7C5CFF),
  Color(0xFF3D8BFF),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFF8E8E9A),
];

String formatMinutes(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.minutesShort(minutes);
  return l10n.durationHm(minutes ~/ 60, minutes % 60);
}

String formatDateTime(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMd(locale).add_Hm().format(d);
}
