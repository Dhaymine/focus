class TimerConfig {
  const TimerConfig({
    this.studyMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.cycles = 1,
    this.autoTransition = true,
    this.autoRepeat = false,
    this.dailyGoalMinutes = 120,
  });

  final int studyMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final int cycles;
  final bool autoTransition;
  final bool autoRepeat;
  final int dailyGoalMinutes;

  /// Derived: total study time of one full plan.
  int get totalStudyMinutes => studyMinutes * sessionsBeforeLongBreak * cycles;

  TimerConfig copyWith({
    int? studyMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    int? cycles,
    bool? autoTransition,
    bool? autoRepeat,
    int? dailyGoalMinutes,
  }) {
    return TimerConfig(
      studyMinutes: studyMinutes ?? this.studyMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      cycles: cycles ?? this.cycles,
      autoTransition: autoTransition ?? this.autoTransition,
      autoRepeat: autoRepeat ?? this.autoRepeat,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'studyMinutes': studyMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
        'cycles': cycles,
        'autoTransition': autoTransition,
        'autoRepeat': autoRepeat,
        'dailyGoalMinutes': dailyGoalMinutes,
      };

  factory TimerConfig.fromJson(Map<String, dynamic> j) {
    const d = TimerConfig();
    int geti(String k, int def) => j[k] is num ? (j[k] as num).toInt() : def;
    bool getb(String k, bool def) => j[k] is bool ? j[k] as bool : def;
    return TimerConfig(
      studyMinutes: geti('studyMinutes', d.studyMinutes).clamp(1, 180),
      shortBreakMinutes:
          geti('shortBreakMinutes', d.shortBreakMinutes).clamp(1, 60),
      longBreakMinutes:
          geti('longBreakMinutes', d.longBreakMinutes).clamp(1, 120),
      sessionsBeforeLongBreak:
          geti('sessionsBeforeLongBreak', d.sessionsBeforeLongBreak)
              .clamp(1, 12),
      cycles: geti('cycles', d.cycles).clamp(1, 20),
      autoTransition: getb('autoTransition', d.autoTransition),
      autoRepeat: getb('autoRepeat', d.autoRepeat),
      dailyGoalMinutes:
          geti('dailyGoalMinutes', d.dailyGoalMinutes).clamp(10, 1440),
    );
  }
}
