# Sikhi Word Games V2

An offline collection of English, romanized Punjabi, and Gurmukhi word games from **Khalsa Game Studio** ([khalsagamestudio.com](https://khalsagamestudio.com/)), built with Flutter.

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

The current public-playtest candidate is `1.9.0` (build `17`). The version follows
`major.minor.patch+build` format: increment the minor version for a compatible
user-facing feature release, the patch version for a compatible fix-only
release, and the major version for breaking product or data changes. Increment
the build number for every distributed build, including rebuilds that do not
change the user-facing version.

When making an update, change both the `version` field in `app/pubspec.yaml` and
the constants in `app/lib/core/app_version.dart`. The home page displays the
same value so it can be verified in the running app.

## Validate V2

Run from `app/`:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
flutter analyze --suppress-analytics
flutter test --suppress-analytics
dart run tool\audit_content.dart
flutter build web --release --no-web-resources-cdn --suppress-analytics
```

The content audit reports editorial flags even when it exits successfully. Review
its results. See [testing strategy](docs/testing_strategy.md) for device,
accessibility, browser, and integration checks beyond the unit/widget suite.

Run `dart run tool\import_v1_content.dart` only when intentionally rebuilding
content from the local V1 source. It is not a normal validation step. Generated
assets are tracked; the V1 source folder is excluded from publication. Editorial
changes belong in the curation layer described in the content documentation.

## Android release signing

Android release variants require a private `app/android/key.properties` containing
`storeFile`, `storePassword`, `keyAlias` and `keyPassword`. The keystore path may be
absolute or relative to `app/android/`. Both properties and keystores are ignored
by Git. Release builds fail when signing configuration is missing; they never
fall back to the debug key. A signed APK still requires separate device/release
validation. Web builds do not require these credentials.

## itch.io release workflow

The first itch.io distribution is **Public playtest 1.9.0+17**. This candidate includes keyboard play, shared themes, corrected Punjabi
spellings, clearer definitions, and a broader curated answer rotation. It is prepared locally; a commit or
successful CI run does not publish the itch.io game. Do not reset the version
history because itch.io is a new host. Change both version sources together and
increment the build number for the next distributed rebuild.

1. Resolve the release blockers in [TODO.md](TODO.md), including definition
   suitability and content provenance. Passing tests alone is insufficient.
2. Run the validation gates, then run `./tool/build_itch_io.ps1` from `app/`.
   This checks the compact release vocabulary before compiling; authoring imports
   and editorial queues are not distributed.
   The helper builds with local renderer resources, changes the compiled base
   path to `./`, and packages the web files with `index.html` at the archive root.
   Flutter 3.47.2 rejects `--base-href ./`, so the helper patches build output.
3. Serve the package through HTTP under a nested directory and verify all five
   games, Dictionary, Gurmukhi rendering, refresh, and real browser persistence.
   Do not test by opening `index.html` through a file URL.
4. Create an unpublished itch.io HTML project and upload the ZIP as playable in
   the browser. Start with a 960 by 720 desktop viewport, fullscreen enabled,
   and click-to-play. Enable mobile support only after touch/browser checks.
5. Test the actual draft iframe: focus, keyboard, touch selection, fullscreen,
   clipboard sharing, saved games, reload, and narrow screens. Browser storage
   settings can affect saves. Keep a previous ZIP to roll back by replacing the
   uploaded build; local saved progress is not a cloud backup.
6. Use the cover and screenshots in `reports/release/` and the prepared page copy
   in [app/README.md](app/README.md). The in-game Share feedback action points to
   this repository's issue form. Publish only after the gates are satisfied.

The official [itch.io HTML5 upload guide](https://itch.io/docs/creators/html5)
requires relative asset paths and a root `index.html` in the ZIP. Check its
current archive limits when distributing. Public availability does not require
Android/iOS signing, but those platforms need separate release validation.

The games use local vocabulary and no account/backend. The packaged build has an
explicit offline app cache. The first visit needs a connection and enough storage;
reload is available only after caching completes. Browser or iframe policy can
prevent it, and cleared browser data removes both the cache and local progress.
Test the actual host before advertising offline reload there.

## Release checks and artifacts

- `dart run tool/build_release_content.dart --check` verifies compact release
  files match authoring inputs and current distribution policy.
- `dart run tool/audit_release_content.dart` checks the distributed vocabulary.
- `node tool/test_web_app_cache_service_worker.mjs` exercises offline worker
  behavior without a browser. The full test suite also checks the manifest.
- `python tool/audit_dependencies.py` queries OSV for locked hosted Pub packages;
  this requires network access and records the limited coverage in
  `reports/security/dependency_audit.json` at the repository root.
- `.github/workflows/flutter_web.yml` runs the automated release checks. Visual
  baselines and a browser integration target supplement unit/widget tests.

Use `app/dist/sikhi-word-games-web-1.9.0+17.zip` for the draft upload. The directory
is ignored by Git; the ZIP is built from the committed sources. Artwork sources
live in `branding/`; cover and real gameplay screenshots live in `reports/release/`.
Keep `THIRD_PARTY_NOTICES.txt` and both bundled-font license files in the package.
