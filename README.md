# Cognitive Fitness

Flutter app that assesses driving readiness with reaction, dual-task and biofeedback tests, and tracks progress over time.

Requires Flutter 3.35+ (Dart 3.9+).

```sh
flutter pub get
flutter run
flutter test
```

## Features

- **Tests**: Reaction (single task), Dual-task (reaction + mental math), Auditory biofeedback (high/low beeps), Visual go/no-go, Tapping pattern. Timings use `Stopwatch` (millisecond precision).
- **Home**: daily goal progress, quick actions, daily summary (avg reaction, accuracy, readiness, streak, training time), recent activity.
- **Progress**: Daily / Weekly / Monthly reports with a data-driven insight card, accuracy and sessions gauge, reaction and score mini charts, a reaction trend chart with a target line, change vs. the previous period, per-test breakdown and session history.
- **Coach**: asks canned questions ("How is my week going?", "Which test am I best at?") and answers from local history.
- **Profile**: daily goal and reaction target settings, and clearing history.

## Architecture (MVC)

```
lib/
  core/          theme (colors, decorations, ThemeData) and utils (stats, formatters)
  models/        plain data: TestResult, TestType, summaries, settings, coach messages
  services/      data and domain logic: SQLite, shared_preferences, audio, AnalyticsService, CoachService
  controllers/   ChangeNotifier controllers (app-level and per test session) exposed via provider
  views/         widgets only; read controllers, never touch storage directly
```

`ResultsController` is the single source of truth for session history. `DashboardController` and `ReportsController` listen to it and recompute through the pure `AnalyticsService`, which is covered by unit tests in `test/`.

The database schema is at version 2. Upgrading from v1 keeps sessions, answers and error counts, but drops the v1 timings: they were measured with 1-second resolution and are invalid.
