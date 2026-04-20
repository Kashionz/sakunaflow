# SakunaFlow — Phase 1 Setup

## Prerequisites

- Flutter SDK (stable 3.22+): https://flutter.dev/docs/get-started/install/windows
- Flutter in PATH (verify with `flutter --version`)

## First-time setup

```bash
cd C:\Users\User\Desktop\Project\sakunaflow

# 1. Initialize Windows platform files (only needed once; won't overwrite existing lib/ files)
flutter create . --org com.sakunaflow --platforms=windows

# 2. Install dependencies
flutter pub get

# 3. Generate Drift DB code + Freezed models
dart run build_runner build --delete-conflicting-outputs

# 4. Launch on Windows
flutter run -d windows
```

## Development

```bash
# Hot reload development
flutter run -d windows

# After modifying any table/DAO file, re-run codegen
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerates on save)
dart run build_runner watch --delete-conflicting-outputs

# Code quality
flutter analyze
dart format lib/
```

## Phase 1 feature checklist

- [x] Notion warm theme (Inter + Noto Sans TC + JetBrains Mono)
- [x] Sidebar navigation (Today / Calendar / Pomodoro / Stats + Projects)
- [x] Projects — CRUD with color picker, tech tags, Git URL
- [x] Tasks — Today view, project view, detail sheet, quick-add
- [x] Pomodoro — 25/5/15 timer, ring progress, task binding, completion note
- [x] Calendar — TableCalendar month/week/2-week, event CRUD
- [x] Stats — Today counts + weekly bar chart (fl_chart) + project ranking
- [x] Settings — Pomodoro durations, theme mode, week start day

## Architecture notes

- **Data layer**: Drift (SQLite) — all reads/writes go through DAOs in `lib/data/local/`
- **State**: Riverpod `StreamProvider` + `StateNotifierProvider` — UI reactively rebuilds from DB streams
- **Routing**: go_router with `ShellRoute` wrapping the sidebar layout
- **Timer accuracy**: Pomodoro uses `DateTime.now()` diff, not tick-counting — survives device sleep
- **Phase 2** will add: Supabase sync, Google/Apple login, iOS platform

## File overview

```
lib/
├── main.dart                       Entry point + Windows window setup
├── app/
│   ├── app.dart                    MaterialApp.router
│   ├── router.dart                 go_router routes
│   └── theme.dart                  AppColors + AppTheme (light/dark)
├── core/
│   ├── constants.dart              kProjectColors, kTechTags
│   └── utils/{time,uuid7}.dart
├── data/local/
│   ├── database.dart               @DriftDatabase entry point
│   ├── tables/                     5 Drift table definitions
│   └── daos/                       5 DAOs (projects/tasks/pomodoro/calendar/prefs)
├── shared/
│   ├── providers/database_provider.dart
│   └── widgets/
│       ├── app_shell.dart          Sidebar + TopBar layout
│       ├── task_item.dart          Reusable task row with checkbox
│       ├── priority_badge.dart     P0–P3 colored pill
│       ├── section_header.dart     Uppercase section label
│       ├── primary_button.dart     Primary + Secondary buttons
│       └── color_swatch_picker.dart  12-color project picker
└── features/
    ├── auth/login_screen.dart      Local mode entry (Phase 2: real auth)
    ├── projects/                   ProjectsScreen + DetailScreen + FormSheet
    ├── tasks/                      TodayScreen + DetailSheet + providers
    ├── pomodoro/                   PomodoroNotifier (state machine) + Screen
    ├── calendar/                   CalendarScreen + EventFormSheet + providers
    ├── stats/                      StatsScreen with fl_chart
    └── settings/                   SettingsScreen + preferences providers
```
