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

## App versioning

The current app version is `1.1.0` (build `2`). The version follows
`major.minor.patch+build` format: increment the minor version for a compatible
user-facing feature release, the patch version for a compatible fix-only
release, and the major version for breaking product or data changes. Increment
the build number for every distributed build, including rebuilds that do not
change the user-facing version.

When making an update, change both the `version` field in `app/pubspec.yaml` and
the constants in `app/lib/core/app_version.dart`. The home page displays the
same value so it can be verified in the running app.

## Validate V2

From the `app` directory:

```powershell
dart run tool\import_v1_content.dart
flutter analyze
flutter test
flutter build web --release
```

The content importer reads a local V1 folder without modifying it and regenerates the structured offline vocabulary assets and review report. The generated V2 assets are tracked, but the V1 source folder itself is not published with this repository.
