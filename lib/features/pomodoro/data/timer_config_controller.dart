import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_provider.dart';
import '../domain/timer_config.dart';

const _key = 'timer_config';

class TimerConfigController extends Notifier<TimerConfig> {
  @override
  TimerConfig build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const TimerConfig();
    try {
      return TimerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TimerConfig();
    }
  }

  Future<void> update(TimerConfig config) async {
    state = config;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(config.toJson()));
  }
}

final timerConfigProvider =
    NotifierProvider<TimerConfigController, TimerConfig>(
        TimerConfigController.new);
