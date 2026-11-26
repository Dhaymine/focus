import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/generated/app_localizations.dart';
import 'core/services/app_settings.dart';
import 'core/services/preferences_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FocusApp(),
    ),
  );
}

class FocusApp extends ConsumerWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'FOCUS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PreviewScreen(),
    );
  }
}

/// Temporary screen to verify theme, localization and RTL. Replaced in Phase 3.
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final sections = [
      l10n.navHome,
      l10n.navFocus,
      l10n.navTasks,
      l10n.navCountdown,
      l10n.navStatistics,
      l10n.settings,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Text(
              l10n.welcome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.placeholderNote),
          const SizedBox(height: 24),
          Text(l10n.theme, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setThemeMode(s.first),
          ),
          const SizedBox(height: 24),
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.themeSystem),
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
          const SizedBox(height: 24),
          for (final name in sections)
            Card(
              child: ListTile(title: Text(name)),
            ),
        ],
      ),
    );
  }
}
