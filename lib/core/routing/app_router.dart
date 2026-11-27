import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/countdown/presentation/countdown_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pomodoro/presentation/appearance_screen.dart';
import '../../features/pomodoro/presentation/fullscreen_timer_screen.dart';
import '../../features/pomodoro/presentation/timer_settings_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sounds/presentation/sound_settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/focus',
              builder: (context, state) => const FocusScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/countdown',
              builder: (context, state) => const CountdownScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/timer-settings',
        builder: (context, state) => const TimerSettingsScreen(),
      ),
      GoRoute(
        path: '/sound-settings',
        builder: (context, state) => const SoundSettingsScreen(),
      ),
      GoRoute(
        path: '/appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/timer-fullscreen',
        builder: (context, state) => const FullscreenTimerScreen(),
      ),
    ],
  );
});
