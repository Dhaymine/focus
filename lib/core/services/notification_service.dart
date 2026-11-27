import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

class ScheduledAlert {
  const ScheduledAlert({
    required this.atMs,
    required this.title,
    required this.body,
  });

  final int atMs;
  final String title;
  final String body;
}

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Schedules system notifications for upcoming timer boundaries.
/// Supported on Android and iOS. On Windows it is a no-op (the plugin does
/// not support scheduled notifications there).
class NotificationService {
  late final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _baseId = 1000;
  static const int _slots = 16;

  bool get supported => Platform.isAndroid || Platform.isIOS;

  Future<void> _init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions({required bool askExact}) async {
    if (!supported) return;
    try {
      await _init();
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
        if (askExact) {
          final can = await android?.canScheduleExactNotifications() ?? true;
          if (!can) await android?.requestExactAlarmsPermission();
        }
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: false, sound: true);
      }
    } catch (_) {
      // Permission flow failed; alerts simply will not show.
    }
  }

  Future<void> _cancelPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _baseId && p.id < _baseId + _slots) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// Replaces all pending timer notifications with [alerts].
  Future<void> schedule(List<ScheduledAlert> alerts,
      {required bool vibrate}) async {
    if (!supported) return;
    try {
      await _init();
      await _cancelPending();
      if (alerts.isEmpty) return;

      var mode = AndroidScheduleMode.inexactAllowWhileIdle;
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final can = await android?.canScheduleExactNotifications() ?? false;
        if (can) mode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          vibrate ? 'focus_alerts_vibrate' : 'focus_alerts_silent',
          'Timer alerts',
          channelDescription: 'Alerts when a timer session ends',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: vibrate,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      var i = 0;
      for (final a in alerts) {
        if (a.atMs <= now + 500 || i >= _slots) continue;
        await _plugin.zonedSchedule(
          _baseId + i,
          a.title,
          a.body,
          tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, a.atMs),
          details,
          androidScheduleMode: mode,
        );
        i++;
      }
    } catch (_) {
      // Scheduling failed; in-app alerts still work.
    }
  }
}
