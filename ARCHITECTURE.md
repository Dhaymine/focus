# ARCHITECTURE

## Platforms
Android and Windows only.

## Principles
- Offline-first: every core feature works without account or internet
- Feature-first modules, each with `data/`, `domain/`, `presentation/`
- Riverpod (handwritten providers) for state; GoRouter for navigation
- Platform differences isolated behind Dart interfaces + MethodChannel
- Minimal data collection; network traffic is never inspected or transmitted

## Folder layout

~~~text
lib/
  core/{database,theme,localization,routing,services,utils}
  shared/widgets/
  features/{home,pomodoro,focus,tasks,countdown,statistics,sounds,settings,sync}/
  main.dart
~~~

## Layers
1. **Presentation:** widgets, screens, Riverpod notifiers
2. **Domain:** pure Dart models and logic (timer plan generator, stats calculators)
3. **Data:** Drift DAOs, SharedPreferences, platform channels, Supabase

## Pomodoro engine
- `TimerConfig` -> `TimerPlan` (ordered list of segments: study, shortBreak, longBreak, each with duration)
- Persisted `TimerSnapshot`: planId, segmentIndex, status (idle/running/paused), `segmentEndsAtEpochMs`, `remainingMsAtPause`
- Remaining time = `segmentEndsAt - now`. A UI ticker only repaints; it is never the source of truth
- Pause stores remaining ms; resume recomputes `segmentEndsAt`
- App restart: load snapshot, fast-forward through segments that elapsed, record completed ones to history
- Local notifications are scheduled for upcoming segment boundaries so alerts fire when the app is not running (OS limits apply)
- Android: foreground service + exact alarms. Windows: runs while the process is alive (tray/minimized is fine)

## Focus Mode abstraction
`BlockingService` interface with implementations:
- `AndroidVpnBlockingService`: Kotlin `VpnService`, `addAllowedApplication` for chosen packages, tunnel packets dropped, nothing logged or forwarded
- `WindowsFirewallBlockingService`: outbound block rules per executable, tagged `FOCUS_*`, removed on stop and on startup cleanup; requires elevation

## Database (Drift/SQLite), preliminary tables
tasks, subtasks, categories, task_time_entries, countdowns, timer_sessions, timer_profiles, sound_profiles, focus_profiles, focus_schedules, daily_goals. Sync columns on syncable tables: `updatedAt`, `deletedAt` (tombstone), `deviceId`.

## Sync (optional, Phase 9)
Supabase auth + per-table sync. Conflict rule: last-write-wins by `updatedAt`, tombstones for deletes, user-triggered backup/restore.

## Localization and theming
ARB files for en/fr/ar, `Directionality` follows locale (RTL for Arabic). Dark default (charcoal + purple/electric blue), light theme supported. Design tokens centralised in `core/theme`.

## Code generation policy
Only Drift generates code. CI runs `dart run build_runner build --delete-conflicting-outputs`; generated files are not committed.
