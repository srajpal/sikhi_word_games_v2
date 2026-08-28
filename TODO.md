# Sikhi Word Games V2 — TODO

This is the persistent project checklist. Keep it updated as work progresses; do not remove incomplete scope.

## Toolchain and repository

- [x] Audit the V1 repository and identify reusable behavior and content.
- [x] Update Flutter to stable 3.47.2 and Dart to 3.13.2.
- [x] Install Android SDK 36 requirements and verify accepted licenses.
- [x] Verify Android and web tooling with `flutter doctor -v`.
- [ ] Verify iOS and iPadOS builds on macOS with current Xcode before release.
- [x] Preserve V1 as an unchanged reference while building V2 separately.
- [x] Scaffold V2 for Android, iOS, and web.

## Product documentation

- [x] Record agreed product decisions.
- [x] Create the initial V2 architecture document; revise it as implementation evolves.
- [x] Create the initial vocabulary/content schema; revise it after import findings.
- [x] Create and maintain the automated testing strategy.
- [ ] Document release and deployment procedures.

## Application foundation

- [x] Establish initial feature-based folders and dependency boundaries.
- [x] Add routing and the initial game-library home screen.
- [x] Add offline persistence interfaces and schema versioning.
- [x] Add initial semantic theme tokens.
- [x] Add initial user-selectable Modern and Sketch themes.
- [ ] Complete responsive game layouts; the game library now adapts to narrow phones and wide screens.
- [ ] Add accessibility conventions for semantics, focus, contrast, and text scaling.

## Vocabulary and definitions

- [x] Import V1 four-, five-, and six-letter lists without modifying the source files.
- [x] Convert parallel text files into structured vocabulary records.
- [x] Normalize processing and use grapheme clusters for generated visible letter counts.
- [x] Detect malformed rows, duplicate IDs, mismatched keys, missing definitions, and script anomalies.
- [x] Record English, romanized Panjabi, and available Gurmukhi forms separately.
- [x] Maintain a broad accepted-guess pool.
- [ ] Expand and editorially approve the solution pool; an explicit machine-checked starter set now drives the app.
- [x] Enforce accepted guesses and curated solutions as separate domain collections.
- [x] Track V1 source version and editorial review status.
- [x] Produce a reproducible human-readable content review report.
- [ ] Replace pretty-printed review assets with compact/indexed release assets and measure startup/download performance.

## Guess the Word engine

- [x] Build the first pure Dart engine component independent of Flutter widgets.
- [x] Implement correct two-pass repeated-letter evaluation.
- [x] Support configurable word lengths, including four, five, and six graphemes, in the domain layer.
- [x] Support English filtering in the domain layer.
- [x] Support romanized Panjabi filtering in the domain layer.
- [x] Support Mixed Latin with English and romanized guesses accepted in the domain layer.
- [x] Support Gurmukhi grapheme filtering and game evaluation in the domain layer.
- [x] Add seeded, non-repeating solution selection with exhaustion reset.
- [x] Model game progress, accepted turns, rejections, and win/loss states explicitly.
- [x] Add versioned serialization and offline storage for interrupted-game restoration.

## Guess the Word interface

- [x] Build a minimal playable screen for fast iteration using temporary content.
- [x] Replace temporary `APPLE` content with the offline vocabulary repository and explicit starter solutions.
- [x] Connect English, romanized Panjabi, Mixed Latin, and initial Gurmukhi mode/length selection.
- [x] Add the shared Latin keyboard for English, romanized Panjabi, and Mixed Latin.
- [x] Add the initial purpose-built Gurmukhi keyboard with vowel signs and extended letters.
- [x] Add tile feedback symbols and semantic labels that do not rely on color alone.
- [x] Show definitions after accepted guesses and reveal the solution definition at completion.
- [x] Add in-app gameplay help and language-mode explanations.
- [ ] Add statistics stored completely offline.
- [ ] Add spoiler-safe sharing.
- [ ] Add physical-keyboard support where appropriate.
- [ ] Add animations and haptics with reduced-motion/haptics settings.

## Automated verification

- [x] Test exact, present, and absent letter evaluation.
- [x] Test the initial repeated-letter cases in guesses and solutions.
- [x] Test Unicode grapheme counting plus Gurmukhi keyboard composition and visible-grapheme deletion.
- [x] Test the initial language and grapheme-length filters.
- [x] Test accepted guesses versus curated solutions.
- [ ] Complete statistics coverage; seeded selection, core boundaries, and restoration now pass.
- [x] Add initial content-import and validation tests.
- [ ] Add responsive widget tests.
- [ ] Add Modern and Sketch golden tests.
- [ ] Add representative integration flows.
- [x] Establish a clean `flutter analyze` and test-suite baseline; keep both clean.

## Platform and release work

- [ ] Verify offline loading; the initial release web build compiles successfully.
- [ ] Reduce the initial uncompressed web artifact baseline (59.6 MB total; 17.9 MB generated vocabulary).
- [ ] Verify Android debug and release builds on emulator and physical hardware.
- [ ] Verify iPhone and iPad builds on macOS and physical hardware.
- [ ] Configure app identifiers, icons, splash screens, signing, and store metadata.
- [ ] Add a Cloudflare Pages preview workflow for compiled web assets.
- [ ] Decide whether the playable web app is separate from the future marketing site.
- [ ] Consider itch.io distribution after the web build is stable.

## Later game modules

- [ ] Define the reusable game-module contract.
- [ ] Design and implement Word Search.
- [ ] Design and implement Hangman or a themed equivalent.
- [ ] Design and implement a timed typing/accuracy game.
- [ ] Reuse the shared content repository, themes, settings, and statistics.
