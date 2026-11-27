import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/number_stepper.dart';
import '../../../shared/widgets/page_body.dart';
import '../data/audio_service.dart';
import '../data/builtin_sounds.dart';
import '../data/sound_settings_controller.dart';
import '../domain/sound_settings.dart';

class SoundSettingsScreen extends ConsumerWidget {
  const SoundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final s = ref.watch(soundSettingsProvider);
    final ctl = ref.read(soundSettingsProvider.notifier);
    final audio = ref.read(audioServiceProvider);

    final options = <String>[
      SoundIds.none,
      ...BuiltInSounds.ids,
      ...s.customSounds.map((c) => '${SoundIds.customPrefix}${c.id}'),
    ];

    String label(String id) {
      switch (id) {
        case SoundIds.none:
          return l10n.soundNone;
        case 'bell':
          return l10n.soundBell;
        case 'chime':
          return l10n.soundChime;
        case 'beep':
          return l10n.soundBeep;
        case 'soft':
          return l10n.soundSoft;
        case 'digital':
          return l10n.soundDigital;
      }
      if (id.startsWith(SoundIds.customPrefix)) {
        final cid = id.substring(SoundIds.customPrefix.length);
        for (final c in s.customSounds) {
          if (c.id == cid) return c.name;
        }
      }
      return id;
    }

    Widget eventRow(String title, SoundEvent e) {
      final id = s.idFor(e);
      final value = options.contains(id) ? id : SoundIds.none;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyLarge),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: value,
                    items: [
                      for (final o in options)
                        DropdownMenuItem(
                          value: o,
                          child: Text(label(o), overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) ctl.setEvent(e, v);
                    },
                  ),
                ),
                IconButton(
                  tooltip: l10n.previewSound,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => audio.playOnce(value, s),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.soundSettings)),
      body: PageBody(
        children: [
          AppCard(
            child: Column(
              children: [
                eventRow(l10n.soundStudyStart, SoundEvent.studyStart),
                eventRow(l10n.soundStudyEnd, SoundEvent.studyEnd),
                eventRow(l10n.soundBreakStart, SoundEvent.breakStart),
                eventRow(l10n.soundBreakEnd, SoundEvent.breakEnd),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.volume, style: theme.textTheme.bodyLarge),
                Slider(
                  value: s.volume,
                  onChanged: (v) => ctl.setVolume(v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.vibration),
                  value: s.vibrate,
                  onChanged: ctl.setVibrate,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.loopAlarm),
                  subtitle: Text(l10n.loopAlarmDesc),
                  value: s.loop,
                  onChanged: ctl.setLoop,
                ),
                if (!s.loop)
                  NumberStepper(
                    label: l10n.repeatCount,
                    value: s.repeatCount,
                    min: 1,
                    max: 10,
                    onChanged: ctl.setRepeatCount,
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
                  l10n.customSounds,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (s.customSounds.isEmpty)
                  Text(
                    l10n.noCustomSounds,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                for (final c in s.customSounds)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.music_note_rounded),
                    title: Text(c.name, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.previewSound,
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () => audio.playOnce(
                              '${SoundIds.customPrefix}${c.id}', s),
                        ),
                        IconButton(
                          tooltip: l10n.removeSound,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ctl.removeCustom(c.id),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await ctl.importSound();
                    if (ok == false && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.importFailed)),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.importSound),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.soundsNote,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
