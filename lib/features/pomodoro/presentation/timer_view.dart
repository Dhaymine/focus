import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../data/appearance_controller.dart';
import '../data/timer_controller.dart';
import '../domain/timer_appearance.dart';
import '../domain/timer_snapshot.dart';
import 'segment_labels.dart';

/// Timer bound to the live providers. Rebuilds four times per second.
class LiveTimerView extends ConsumerWidget {
  const LiveTimerView({super.key, this.height, this.borderRadius = 28});

  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(timerControllerProvider);
    final appearance = ref.watch(appearanceProvider);
    final nowMs = ref.watch(timerClockProvider).valueOrNull ??
        DateTime.now().millisecondsSinceEpoch;
    return TimerView(
      snapshot: snap,
      nowMs: nowMs,
      appearance: appearance,
      label: segmentName(l10n, snap.segment.type),
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class TimerView extends StatelessWidget {
  const TimerView({
    super.key,
    required this.snapshot,
    required this.nowMs,
    required this.appearance,
    required this.label,
    this.height,
    this.borderRadius = 28,
  });

  final TimerSnapshot snapshot;
  final int nowMs;
  final TimerAppearance appearance;
  final String label;
  final double? height;
  final double borderRadius;

  static String format(int ms) {
    final totalSec = (ms / 1000).ceil();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timerTheme = TimerThemes.byId(appearance.themeId);

    var bg = appearance.background;
    final photo = appearance.photoPath;
    if (bg == TimerBackground.photo && (photo == null || photo.isEmpty)) {
      bg = TimerBackground.gradient;
    }
    final plain = bg == TimerBackground.plain;
    final onColor = plain ? scheme.onSurface : Colors.white;
    final accent = appearance.accentValue != null
        ? Color(appearance.accentValue!)
        : (plain ? scheme.primary : timerTheme.accent);

    final remaining = snapshot.remainingMs(nowMs);
    final progress = snapshot.progress(nowMs);
    final timeText = format(remaining);

    TextStyle digits(double size, FontWeight weight) => TextStyle(
          fontSize: size * appearance.fontScale,
          fontWeight: weight,
          color: onColor,
          fontFamily: TimerFonts.family(appearance.fontId),
          fontFamilyFallback: TimerFonts.fallback(appearance.fontId),
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.0,
        );

    final labelText = Text(
      label,
      style: TextStyle(
        color: onColor.withValues(alpha: 0.85),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: plain ? scheme.surface : null,
        gradient: bg == TimerBackground.gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: timerTheme.colors,
              )
            : null,
        image: bg == TimerBackground.photo
            ? DecorationImage(
                image: FileImage(File(photo!)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.45),
                  BlendMode.darken,
                ),
                onError: (_, __) {},
              )
            : null,
        border: plain
            ? Border.all(color: scheme.outline.withValues(alpha: 0.12))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight.isFinite ? c.maxHeight : 360.0;
          final short = math.min(c.maxWidth, h);
          final side = (short * 0.78).clamp(150.0, 360.0);

          final Widget content;
          switch (appearance.style) {
            case TimerStyle.circular:
              final inner = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelText,
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(timeText, style: digits(56, FontWeight.w700)),
                  ),
                ],
              );
              content = appearance.showRing
                  ? ProgressRing(
                      value: progress,
                      size: side,
                      strokeWidth: side * 0.06,
                      colors: [accent, accent.withValues(alpha: 0.6)],
                      trackColor: onColor.withValues(alpha: 0.15),
                      child: Padding(
                        padding: EdgeInsets.all(side * 0.14),
                        child: inner,
                      ),
                    )
                  : inner;
            case TimerStyle.digital:
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelText,
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(timeText, style: digits(88, FontWeight.w800)),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: math.min(side * 1.2, c.maxWidth * 0.7),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: accent,
                        backgroundColor: onColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ],
              );
            case TimerStyle.minimal:
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(timeText, style: digits(64, FontWeight.w300)),
                  ),
                  const SizedBox(height: 10),
                  labelText,
                ],
              );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          );
        },
      ),
    );
  }
}
