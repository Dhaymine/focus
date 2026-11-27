import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/page_body.dart';
import '../data/appearance_controller.dart';
import '../domain/timer_appearance.dart';
import 'timer_view.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = ref.watch(appearanceProvider);
    final ctl = ref.read(appearanceProvider.notifier);

    String themeName(String id) => switch (id) {
          'aurora' => l10n.tmAurora,
          'midnight' => l10n.tmMidnight,
          'sunset' => l10n.tmSunset,
          'forest' => l10n.tmForest,
          'mono' => l10n.tmMono,
          _ => id,
        };

    String fontName(String id) => switch (id) {
          'mono' => l10n.fontMono,
          'serif' => l10n.fontSerif,
          _ => l10n.fontDefault,
        };

    Widget title(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            text,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearanceSettings)),
      body: PageBody(
        children: [
          const LiveTimerView(height: 280),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(l10n.timerStyle),
                SegmentedButton<TimerStyle>(
                  segments: [
                    ButtonSegment(
                        value: TimerStyle.circular,
                        label: Text(l10n.styleCircular)),
                    ButtonSegment(
                        value: TimerStyle.digital,
                        label: Text(l10n.styleDigital)),
                    ButtonSegment(
                        value: TimerStyle.minimal,
                        label: Text(l10n.styleMinimal)),
                  ],
                  selected: {a.style},
                  onSelectionChanged: (s) =>
                      ctl.update(a.copyWith(style: s.first)),
                ),
                if (a.style == TimerStyle.circular)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.showRing),
                    value: a.showRing,
                    onChanged: (v) => ctl.update(a.copyWith(showRing: v)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(l10n.backgroundLabel),
                SegmentedButton<TimerBackground>(
                  segments: [
                    ButtonSegment(
                        value: TimerBackground.plain,
                        label: Text(l10n.bgPlain)),
                    ButtonSegment(
                        value: TimerBackground.gradient,
                        label: Text(l10n.bgGradient)),
                    ButtonSegment(
                        value: TimerBackground.photo,
                        label: Text(l10n.bgPhoto)),
                  ],
                  selected: {a.background},
                  onSelectionChanged: (s) {
                    final next = s.first;
                    if (next == TimerBackground.photo &&
                        (a.photoPath == null || a.photoPath!.isEmpty)) {
                      ctl.pickPhoto();
                    } else {
                      ctl.update(a.copyWith(background: next));
                    }
                  },
                ),
                if (a.background == TimerBackground.photo) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await ctl.pickPhoto();
                      if (ok == false && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.importFailed)),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.choosePhoto),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(l10n.timerThemeLabel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TimerThemes.all)
                      ChoiceChip(
                        avatar: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: t.colors),
                          ),
                        ),
                        label: Text(themeName(t.id)),
                        selected: a.themeId == t.id,
                        onSelected: (_) => ctl.update(a.copyWith(themeId: t.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                title(l10n.accentColor),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.accentAuto),
                      selected: a.accentValue == null,
                      onSelected: (_) =>
                          ctl.update(a.copyWith(clearAccent: true)),
                    ),
                    for (final c in accentChoices)
                      GestureDetector(
                        onTap: () =>
                            ctl.update(a.copyWith(accentValue: c.toARGB32())),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: a.accentValue == c.toARGB32()
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                              width: a.accentValue == c.toARGB32() ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title(l10n.fontLabel),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final id in TimerFonts.ids)
                      ChoiceChip(
                        label: Text(fontName(id)),
                        selected: a.fontId == id,
                        onSelected: (_) => ctl.update(a.copyWith(fontId: id)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                title(l10n.fontSize),
                Slider(
                  value: a.fontScale,
                  min: 0.7,
                  max: 1.5,
                  divisions: 8,
                  label: '${(a.fontScale * 100).round()}%',
                  onChanged: (v) => ctl.update(a.copyWith(fontScale: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
