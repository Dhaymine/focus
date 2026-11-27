import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_provider.dart';

const _key = 'active_task_id';

/// The task the running timer is linked to (null = free session).
class ActiveTaskController extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  Future<void> set(String? id) async {
    state = id;
    final prefs = ref.read(sharedPreferencesProvider);
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, id);
    }
  }
}

final activeTaskIdProvider =
    NotifierProvider<ActiveTaskController, String?>(ActiveTaskController.new);
