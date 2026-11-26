# FOCUS

Personal productivity app for Android and Windows, built with Flutter.

FOCUS helps you concentrate, organize study sessions, manage tasks, count down to exams and track your progress.

## Features (planned)

- Customizable Pomodoro engine with cycles, custom sounds and ambient audio
- Focus Mode (Android per-app network blocking via local VPN, Windows Firewall rules)
- Tasks with priorities, subtasks, reminders and time tracking
- Multiple countdowns with Android widgets and a Windows mini window
- Statistics with interactive charts
- Offline-first with optional Supabase sync
- English, French, Arabic (full RTL), dark and light themes

## Platforms

Android and Windows only. iOS is not supported and not planned.

## Status

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for the current stage and [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for the plan.

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [CHANGELOG.md](CHANGELOG.md)

## Building

Builds run on GitHub Actions (Actions tab). Download results from a finished run under **Artifacts**.

## Privacy

Core features work offline without an account. FOCUS never inspects or transmits your network traffic.
App blocking on Android uses a local VPN that only drops packets of the apps you select.
