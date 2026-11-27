import 'package:flutter/material.dart';

enum TimerStyle { circular, digital, minimal }

enum TimerBackground { plain, gradient, photo }

class TimerTheme {
  const TimerTheme(this.id, this.colors, this.accent);

  final String id;
  final List<Color> colors;
  final Color accent;
}

class TimerThemes {
  TimerThemes._();

  static const all = [
    TimerTheme('aurora', [Color(0xFF7C5CFF), Color(0xFF3D8BFF)],
        Color(0xFFFFFFFF)),
    TimerTheme('midnight', [Color(0xFF141A38), Color(0xFF3A4BA0)],
        Color(0xFF8AA4FF)),
    TimerTheme('sunset', [Color(0xFFFF7E5F), Color(0xFFB4457A)],
        Color(0xFFFFFFFF)),
    TimerTheme('forest', [Color(0xFF0B6E4F), Color(0xFF1FA67A)],
        Color(0xFFD9FFE9)),
    TimerTheme('mono', [Color(0xFF1E1E22), Color(0xFF4A4A55)],
        Color(0xFFF2F2F7)),
  ];

  static TimerTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

const accentChoices = <Color>[
  Color(0xFF7C5CFF),
  Color(0xFF3D8BFF),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFFFFFFF),
];

class TimerFonts {
  TimerFonts._();

  static const ids = ['default', 'mono', 'serif'];

  static String? family(String id) => switch (id) {
        'mono' => 'monospace',
        'serif' => 'serif',
        _ => null,
      };

  static List<String> fallback(String id) => switch (id) {
        'mono' => const ['Consolas', 'Menlo', 'Courier New'],
        'serif' => const ['Georgia', 'Times New Roman'],
        _ => const [],
      };
}

class TimerAppearance {
  const TimerAppearance({
    this.style = TimerStyle.circular,
    this.themeId = 'aurora',
    this.accentValue,
    this.fontId = 'default',
    this.fontScale = 1.0,
    this.showRing = true,
    this.background = TimerBackground.gradient,
    this.photoPath,
  });

  final TimerStyle style;
  final String themeId;
  final int? accentValue;
  final String fontId;
  final double fontScale;
  final bool showRing;
  final TimerBackground background;
  final String? photoPath;

  TimerAppearance copyWith({
    TimerStyle? style,
    String? themeId,
    int? accentValue,
    bool clearAccent = false,
    String? fontId,
    double? fontScale,
    bool? showRing,
    TimerBackground? background,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return TimerAppearance(
      style: style ?? this.style,
      themeId: themeId ?? this.themeId,
      accentValue: clearAccent ? null : (accentValue ?? this.accentValue),
      fontId: fontId ?? this.fontId,
      fontScale: fontScale ?? this.fontScale,
      showRing: showRing ?? this.showRing,
      background: background ?? this.background,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'style': style.name,
        'themeId': themeId,
        'accent': accentValue,
        'fontId': fontId,
        'fontScale': fontScale,
        'showRing': showRing,
        'background': background.name,
        'photo': photoPath,
      };

  factory TimerAppearance.fromJson(Map<String, dynamic> j) {
    return TimerAppearance(
      style: TimerStyle.values.firstWhere(
        (e) => e.name == j['style'],
        orElse: () => TimerStyle.circular,
      ),
      themeId: (j['themeId'] as String?) ?? 'aurora',
      accentValue: (j['accent'] as num?)?.toInt(),
      fontId: (j['fontId'] as String?) ?? 'default',
      fontScale: ((j['fontScale'] as num?)?.toDouble() ?? 1.0).clamp(0.7, 1.5),
      showRing: j['showRing'] != false,
      background: TimerBackground.values.firstWhere(
        (e) => e.name == j['background'],
        orElse: () => TimerBackground.gradient,
      ),
      photoPath: j['photo'] as String?,
    );
  }
}
