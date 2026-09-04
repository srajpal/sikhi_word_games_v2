# Sikhi Word Games V2

An offline collection of English, romanized Punjabi, and Gurmukhi word games built with Flutter.

## Repository layout

- `app/` — the new Flutter V2 application for Android, iOS/iPadOS, and web.
- `docs/` — product decisions, architecture, content schema, and testing strategy.
- `reports/` — reproducible vocabulary-import review reports.
- `sikhi_word_games-main/` — optional local V1 reference source; deliberately excluded from Git.
- `TODO.md` — the persistent implementation checklist.

## Current development baseline

- Flutter 3.47.2 stable
- Dart 3.13.2
- Android SDK 36

## Validate V2

From the `app` directory:

```powershell
dart run tool\import_v1_content.dart
flutter analyze
flutter test
flutter build web --release
```

The content importer reads a local V1 folder without modifying it and regenerates the structured offline vocabulary assets and review report. The generated V2 assets are tracked, but the V1 source folder itself is not published with this repository.
