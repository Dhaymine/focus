enum SoundEvent { studyStart, studyEnd, breakStart, breakEnd }

class SoundIds {
  SoundIds._();

  static const none = 'none';
  static const customPrefix = 'custom:';
}

class CustomSound {
  const CustomSound({required this.id, required this.name, required this.path});

  final String id;
  final String name;
  final String path;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'path': path};

  static CustomSound? tryFromJson(dynamic j) {
    try {
      final m = j as Map;
      return CustomSound(
        id: m['id'] as String,
        name: m['name'] as String,
        path: m['path'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

class SoundSettings {
  const SoundSettings({
    this.studyStart = 'beep',
    this.studyEnd = 'bell',
    this.breakStart = 'soft',
    this.breakEnd = 'chime',
    this.volume = 0.8,
    this.vibrate = true,
    this.repeatCount = 1,
    this.loop = false,
    this.customSounds = const [],
  });

  final String studyStart;
  final String studyEnd;
  final String breakStart;
  final String breakEnd;
  final double volume;
  final bool vibrate;
  final int repeatCount;
  final bool loop;
  final List<CustomSound> customSounds;

  static const defaults = SoundSettings();

  String idFor(SoundEvent e) => switch (e) {
        SoundEvent.studyStart => studyStart,
        SoundEvent.studyEnd => studyEnd,
        SoundEvent.breakStart => breakStart,
        SoundEvent.breakEnd => breakEnd,
      };

  SoundSettings withEvent(SoundEvent e, String id) => switch (e) {
        SoundEvent.studyStart => copyWith(studyStart: id),
        SoundEvent.studyEnd => copyWith(studyEnd: id),
        SoundEvent.breakStart => copyWith(breakStart: id),
        SoundEvent.breakEnd => copyWith(breakEnd: id),
      };

  SoundSettings copyWith({
    String? studyStart,
    String? studyEnd,
    String? breakStart,
    String? breakEnd,
    double? volume,
    bool? vibrate,
    int? repeatCount,
    bool? loop,
    List<CustomSound>? customSounds,
  }) {
    return SoundSettings(
      studyStart: studyStart ?? this.studyStart,
      studyEnd: studyEnd ?? this.studyEnd,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
      volume: volume ?? this.volume,
      vibrate: vibrate ?? this.vibrate,
      repeatCount: repeatCount ?? this.repeatCount,
      loop: loop ?? this.loop,
      customSounds: customSounds ?? this.customSounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'studyStart': studyStart,
        'studyEnd': studyEnd,
        'breakStart': breakStart,
        'breakEnd': breakEnd,
        'volume': volume,
        'vibrate': vibrate,
        'repeatCount': repeatCount,
        'loop': loop,
        'custom': customSounds.map((c) => c.toJson()).toList(),
      };

  factory SoundSettings.fromJson(Map<String, dynamic> j) {
    const d = SoundSettings();
    final custom = <CustomSound>[];
    final raw = j['custom'];
    if (raw is List) {
      for (final item in raw) {
        final c = CustomSound.tryFromJson(item);
        if (c != null) custom.add(c);
      }
    }
    return SoundSettings(
      studyStart: (j['studyStart'] as String?) ?? d.studyStart,
      studyEnd: (j['studyEnd'] as String?) ?? d.studyEnd,
      breakStart: (j['breakStart'] as String?) ?? d.breakStart,
      breakEnd: (j['breakEnd'] as String?) ?? d.breakEnd,
      volume: ((j['volume'] as num?)?.toDouble() ?? d.volume).clamp(0.0, 1.0),
      vibrate: j['vibrate'] is bool ? j['vibrate'] as bool : d.vibrate,
      repeatCount: ((j['repeatCount'] as num?)?.toInt() ?? d.repeatCount)
          .clamp(1, 10),
      loop: j['loop'] is bool ? j['loop'] as bool : d.loop,
      customSounds: custom,
    );
  }
}
