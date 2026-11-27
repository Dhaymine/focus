import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/app_settings.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/page_body.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.theme,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.themeSystem),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.systemDefault),
                      selected: locale == null,
                      onSelected: (_) =>
                          ref.read(localeProvider.notifier).setLocale(null),
                    ),
                    for (final entry in const {
                      'en': 'English',
                      'fr': 'Français',
                      'ar': 'العربية',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: locale?.languageCode == entry.key,
                        onSelected: (_) => ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(entry.key)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
