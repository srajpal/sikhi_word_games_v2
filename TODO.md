# Sikhi Word Games V2 — TODO

## September 19 external audit follow-up (#3, #4, #5)

- [x] #5 W2: propagate false SharedPreferences write results as failures;
  regression verifies a later queued retry still succeeds.

- [x] #4: guard Word Search and Quest after asynchronous loads, clears and
  settings sheets; guard new-round context access, including Jodo. Bujho and
  Learn Letters already guard their post-await UI updates. Regression tests pop
  Search and Quest during vocabulary load and session clear.

- [x] PR #2 already merged at 5297874; fast-forwarded local branch. PR #1
  validate and goldens both green on that head (run 35470349206).
- [x] #3: normalize both vocabulary and saved Bujho solutions during restore.
  Widget regression preserves a played turn over two launches with a
  precomposed nukta solution. W1 will separately preserve the distinct letter ੜ.

## Current itch.io preparation: 1.9.0+17 (September 18, 2026)

- [x] Revalidate the accumulated implementation: 277 Flutter tests pass,
  analyzer clean, 144 Dart files format-clean. Build 17 changes only release
  identification from tested build 16; no game logic changes in this preparation.
- [x] Release content freshness/distribution and Node offline-worker checks pass.
  Authoring audit still has 47,093 records and 7,931 editorial flags.
- [x] Rebuild web with the itch.io packaging helper. ZIP integrity, relative base,
  root index, notices, all 35 audio clips, release-only vocabulary and current
  itch.io HTML archive limits pass. See reports/release/package_audit.json.
- [x] Update page copy and cover for all five games. Exclude generated golden
  failure diagnostics from Git while preserving them locally.
- [x] Create separate Khalsa Game Studio draft, project 5023423, at
  https://khalsagamestudio.itch.io/sikhi-word-games with free access and AI
  disclosures. Existing Seva Jump remains unchanged.
- [x] Upload build 17 ZIP, select browser playback, save 960 by 720 embed,
  click-to-play/fullscreen and five-game page copy. Owner preview confirms
  Draft visibility and processed Run game control.
- [x] Actual itch.io iframe launches build 17 with all five library cards.
  Fullscreen Learn Letters guide, correct Chhachha answer, Hear activation
  (Stop audio state), page reload and Continue restored the same answered letter
  at 20 percent. This establishes one hosted save/restore flow, not all-game QA
  or speaker audibility. Embedded automated clicks hit a fractional-coordinate
  tooling limitation; fullscreen controls worked. Page copy verified after reload.
- [x] Commit and push accumulated work to origin/codex/release-playtest-1.3.0.
- [ ] Complete actual-host all-game, audio, persistence and offline-restart checks.
- [ ] Review pronunciation/audio publication status with owner/fluent speaker,
  active vocabulary suitability, mobile browsers and real screen readers.
- [ ] Refresh gameplay screenshots and approve public visibility after review.

Web candidate: app/dist/sikhi-word-games-web-1.9.0+17.zip, 17,708,408 bytes.
SHA-256: 8b429a2d207e2a13fb7e610257de14ec1958ec0d229d6b7c8a99df6d5f487a88.
The Pixel installation remains build 16; no Android rebuild/install in this pass.
Older sections below are historical evidence, not current-build sign-off.

This is the persistent project checklist. Keep it updated as work progresses; do not remove incomplete scope.

## Word Bridges implementation candidate: 1.5.0+9

- [x] Add a fixed starter content provider with two four-pair English decks and
  two four-pair Punjabi decks, with the Punjabi words available in Romanized
  Punjabi or Gurmukhi and English meanings in every mode.
- [x] Resolve deck entries by stable ID from shipped vocabulary. Require current
  accepted-guess and solution eligibility, distributable definitions, correct
  language, usable script, and distinct words/meanings. Omit an affected deck
  when a record is missing, duplicated, held or unusable.
- [x] Check starter matches against existing release definitions as an agent;
  preserve source attribution and review status. No human-review claim and no
  generated/release asset edits. Product scope is in `docs/product_decisions.md`.
- [x] Complete and validate the integrated untimed matching game, offline saved
  progress, first-launch guide, replayable Help and per-game statistics.
- [ ] Verify phone layouts, enlarged text, keyboard and screen-reader selection,
  restore behavior, completion accounting and replay variety before release.
- [x] Record code validation: 125 Dart files formatting-clean; analyzer clean.
  Full regression run passed 210 tests; two test-harness issues were fixed and
  all eight affected UI/integration tests passed on the targeted rerun (212
  distinct tests covered). Packaging and browser evidence follows below.

- [x] Package release web and Android 1.5.0+9; release content freshness and
  distribution audits passed. Android package metadata confirms version 1.5.0,
  build 9, API 24+, ARM32/ARM64/x86_64. Pixel was absent from adb on this run.
- [x] Play the extracted web package at `/review-1.5.0-9/`: first guide, wrong
  match, meaning-first match, browser reload and Continue (1 pair/2 attempts),
  full completion (4 pairs/5 attempts), own statistics and Gurmukhi rendering.
  Real TalkBack speech and actual-host iframe/offline reload remain unverified.

Build 9 artifacts: `app/dist/sikhi-word-games-web-1.5.0+9.zip` (16,867,793 bytes)
and `app/dist/sikhi-word-games-android-1.5.0+9.apk` (55,236,798 bytes).
SHA-256: web `fe1f4d40e51f8371582a9e2d12a0a083765d2bfb6ae58e2caaa7956b34361d38`;
Android `94468631e43fc9f17ec931b2fa30ce8520564f0b47bfe9823436825e7bfbbe6f`.
Starter variety is limited to two sets per language; expand with checked content
before treating this as a long-term daily game.
## Previous feature candidate: 1.4.0+8

- [x] Add offline statistics for Khoj and Word Quest, separated by language and
  word size. Count finished attempts only, with hinted Quest wins and completed
  Khoj target counts. Keep Bujho history; finished retries count as attempts.
- [x] Add a library summary of finished rounds and words solved, with separate
  game totals, no combined win rate, and explicit repeated-word counting.
- [x] Add per-game skippable first-launch guides and Help replay. Rewrite help
  around direct rules, symbols, duplicate letters, keyboard/reader actions,
  hints, retries, language modes and the actual offline limitations.
- [x] Replace the large recurring Choose a game panel with one short subtitle.
- [x] Restore accessible Bujho keyboard actions, add focusable/accessible Quest
  keys, and enable screen-reader start/end selection and cancellation in Khoj.
  Make shared actions at least 48px and wrap labels instead of shrinking them.
  Keep accessible-navigation feedback until dismissed and respect system motion
  preferences. Keep the feedback settings dialog scrollable at large text.
- [x] Verify 193 Flutter tests, including 12 refreshed visual baselines, and
  clean static analysis. All 117 Dart files pass the formatter check.
- [x] Build and inspect build 8 web ZIP and Android APK. Both pass archive
  integrity and release-only vocabulary checks; Android signature verifies.
  Web ZIP: 16,858,449 bytes; APK: 54,892,630 bytes. Release content freshness
  and distribution audits pass in the packaging helper.
- [x] Check the extracted web build at `/review-1.4.0-8/`: compact library,
  first Bujho guide through all steps, physical typing after dismissal, Help
  replay, and the global statistics dialog. This is local browser evidence.
- [ ] Install build 8 on the Pixel: device was disconnected at handoff. The
  previous verified installation is still build 7 until updated.
- [ ] Verify real TalkBack/VoiceOver play, Gurmukhi pronunciation and focus
  through the walkthroughs on physical devices. Semantic tests alone do not
  establish a complete blind-play experience.
- [ ] Add an enlarged Bujho keyboard layout for low vision: compact phone keys
  and dense Gurmukhi rows still constrain touch target size and text enlargement.
- [ ] Improve Bujho board feedback navigation: the local browser accessibility
  tree groups the board and input in one long disabled text-field node. Reader
  key activation is fixed, but efficient row-by-row review needs follow-up.
- [ ] Consider transactional round-result persistence; statistics and session
  cleanup currently use separate writes and cannot guarantee crash atomicity.

Build 8 artifacts: `app/dist/sikhi-word-games-web-1.4.0+8.zip` and
`app/dist/sikhi-word-games-android-1.4.0+8.apk`.
Web SHA-256: `eb7e73d063b9ad41dd45326430188059497133a3280f092a847ed9b87ea8619c`.
APK SHA-256: `d41135d2986ff3d1c6efa6ebb50cdbf252eb8808d91c6a8eadd39073b0efd075`.

## Previous device and web test build: 1.3.2+7

- [x] September 12 additional QA: 180 Flutter tests pass, including 12 visual
  goldens, 200 seeded Khoj grids, and 10,752 exhaustive Bujho solution/guess
  combinations over Latin and Gurmukhi alphabets at lengths 4 through 6.
- [x] Fix Khoj reverse-word pairs sharing the same selectable path, which made
  the second target impossible to find. Reject corrupt saved grids with empty
  or multi-grapheme cells, mismatched targets, duplicate targets, or shared paths.
- [x] Static analysis clean; all 106 Dart files pass formatting. Release content
  freshness/distribution checks and Node offline-worker tests pass. Authoring
  audit remains 47,093 records with 7,931 editorial flags.
- [x] Build and verify `app/dist/sikhi-word-games-android-1.3.2+7.apk`:
  54,794,326 bytes, Android API 24+, ARM32/ARM64/x86_64, version code 7.
  Signature verifies with the existing Android debug certificate for sideload
  testing. This is a release-mode APK, not a store-signed release.
- [x] Build and extract `app/dist/sikhi-word-games-web-1.3.2+7.zip`:
  16,854,334 bytes, 51 files, relative base path. Both archives pass integrity
  checks and contain exactly three release vocabulary shards, with no authoring
  content files. Empty authoring directories in the web ZIP contain no data.
- [x] Extracted-package browser check at `/review-1.3.2-7/`: launch Khoj,
  select diagonal TIMID using the keyboard, reload, Continue, and confirm the
  same grid and found target survive in real browser storage.
- [x] Install build 7 on the attached Pixel 6, preserving data; verify package
  version 1.3.2/code 7 and successful cold activity launch through ADB.
- [ ] Play this APK on physical hardware; screen reader, touch,
  haptics, startup performance and lifecycle checks remain open.
- [ ] Repeat all-game/offline checks on this build in the actual itch.io iframe,
  Firefox and Safari. Earlier browser evidence is not new-build sign-off.

APK SHA-256: `574f3fd87b4a0f7e093e4f6972efe810fd872b9646a214f37d242c9d973a0f22`.
Web SHA-256: `4d308e6270a67f31c39c3ebed991c24a0961ff705b7b1995a840edc3c3a47acd`.
The first Android attempt overlapped Flutter testing and failed with an
integration-test plugin registration mismatch. A standalone build regenerated
the release registration and succeeded without Android configuration changes.

## Previous release candidate: 1.3.1+6

This candidate is for an itch.io public playtest. Bujho, Khoj, Word Quest, and
Dictionary are implemented. Typing Challenge remains future scope. Historical
checks below describe earlier builds; this section records the current state.

- [x] Correct Punjabi spellings and definitions through reproducible curation.
  Add 98 native entries and apply 288 source-checked editorial meanings. Exact
  source IDs and sense indexes retain the evidence for automated decisions.
- [x] Replace blanket native approval with conservative source and quality checks.
  Preserve explicit exclusions and require a per-entry decision to reopen one.
  Record machine and agent editorial decisions honestly as machineChecked.
- [x] Expand four-letter Romanized Punjabi from 7 to 990 unique answers, and
  four-grapheme Gurmukhi from 9 to 342. All 12 language/length pools exceed
  300 unique answers; all Word Quest pools exceed 250 usable clues.
- [x] Keep 45,416 accepted guess records and 14,701 answer records. Distribute
  16,756 sourced/original meanings; hide 30,337 unclear or held definitions.
  Canonical content totals 47,093 records, including retained authoring history.
- [x] Correct ADKAR to ADRAK, reject the erroneous Punjabi CASE spelling, and
  replace misleading meanings such as MARJI and DUTARA with precise definitions.
- [x] Deduplicate game rotation and Dictionary results by active spelling.
  Keep stable alias IDs for history and select a usable sourced definition.
- [x] Restrict Khoj targets to the same curated answer boundary as Bujho and
  Word Quest. Replace saved rounds containing retired answers on Continue.
- [x] Modernize the local review workflow while preserving its loopback-only,
  same-origin write guard and server-owned source provenance.
- [x] Preserve the three shared themes, original branding, bundled fonts,
  offline caching, keyboard play, and accessible responsive layouts.
- [x] Retain the dependency audit: 85 unchanged hosted Pub packages checked
  against OSV on 2026-09-12, with no known advisories returned.
- [ ] Complete final full-suite, analyzer, package, and browser checks for build 6.
- [ ] Upload and test the actual itch.io draft before public distribution.
- [ ] Complete physical mobile, screen-reader, Firefox, and Safari checks.

### Remaining content work

- [ ] Replace remaining hidden definitions only when a clear, usable source or
  checked original meaning is available. Do not approve a word to fill a quota.
- [ ] Establish familiar-word difficulty labels and complete age-suitability
  review across every active language pool. Automated structural/sensitive-text
  checks and source matching do not prove every word is familiar to children.
- [ ] Keep triaging the broader authoring archive. Its 7,931 current flags include
  5,103 deliberately empty held definitions, 1,011 long definitions, 1,726
  references, 83 duplicate spellings, and 8 missing Gurmukhi forms. These are
  separate from the sanitized release audit and must not be reported as cleared.

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
- [x] Document itch.io packaging, draft validation, and release/rollback steps in README.md.

## Application foundation

- [x] Establish initial feature-based folders and dependency boundaries.
- [x] Add routing and the initial game-library home screen.
- [x] Add offline persistence interfaces and schema versioning.
- [x] Add initial semantic theme tokens.
- [x] Add initial user-selectable Modern and Sikhi themes.
- [x] Build a distinctive Sikhi design and add a Dark theme.
- [x] Move the app-wide theme selector to the game-library home page.
- [x] Lock phones to portrait while retaining adaptive tablet and web orientation.
- [x] Complete initial responsive library and fixed-viewport gameplay layouts for phones and wide screens.
- [x] Add initial accessibility conventions for semantics, focus, contrast, and text scaling.
- [x] Align all playable game shells with the shared Word Quest visual language using theme-driven backdrops and panels.
- [x] Add a unified game-library launch flow with New game, Continue game, and random language/word-size choices for every playable mode.
- [x] Make Sikhi the default theme and persist each game's launch preferences independently, including explicit Random choices.

## Vocabulary and definitions

- [x] Import V1 four-, five-, and six-letter lists without modifying the source files.
- [x] Convert parallel text files into structured vocabulary records.
- [x] Normalize processing and use grapheme clusters for generated visible letter counts.
- [x] Detect malformed rows, duplicate IDs, mismatched keys, missing definitions, and script anomalies.
- [x] Record English, romanized Punjabi, and available Gurmukhi forms separately.
- [x] Maintain a broad accepted-guess pool.
- [ ] Expand and editorially approve the solution pool; an explicit machine-checked starter set now drives the app.
- [x] Cross-reference every four-letter English entry against Open English WordNet, SCOWL, and modern usage frequency.
- [x] Classify every ranked four-letter English candidate as an answer, accepted guess, or rejection.
- [x] Classify every five-letter English entry as an answer, accepted guess, or rejection using neutral OEWN senses.
- [x] Complete an explicit answer/guess/reject decision for every remaining bundled 4-, 5-, and 6-letter entry across English and Punjabi/Gurmukhi.
- [x] Build a local dictionary review tool with durable decisions, filters, bulk actions, and a guarded apply workflow.
- [x] Run the conservative automatic four-letter English triage and preserve uncertain entries for manual review.
- [x] Add an initial set of verified common four-letter English words missing from the V1 import.
- [x] Source-match four-letter Punjabi entries and record checked editorial decisions; broader familiarity review remains open.
- [x] Build a native Gurmukhi expansion pipeline targeting real four-, five-, and six-grapheme headwords.
- [x] Evaluate open-license Gurmukhi sources (including Mahan Kosh data) and document provenance/attribution before bundling.
- [x] Import, normalize, deduplicate, and rank native Gurmukhi candidates separately from Romanized transliterations.
- [x] Expose native Gurmukhi candidates in the local review tool with provenance and length filters.
- [x] Add an idempotent apply step for reviewed native Gurmukhi decisions.
- [x] Replace the prior native bulk approval with source-matched quality decisions and checked editorial meanings; uncertain and unsuitable senses remain held.
- [x] Add enough verified five- and six-grapheme Gurmukhi answers for balanced random rotation and regression-test pool counts.
- [x] Expand the machine-checked English four-letter starter rotation beyond BOOK, HERO, and LOVE.
- [x] Replace obsolete or misleading definitions for all active English four-letter solutions.
- [x] Enforce accepted guesses and curated solutions as separate domain collections.
- [x] Prevent Word Quest from selecting guess-only entries and reject cross-reference, circular, fragmentary, or answer-leaking clues at runtime.
- [x] Audit accepted Punjabi definitions separately (17,651 scanned; 1,005 cross-reference-only and 2,039 broader OCR/editorial candidates queued).
- [x] Track V1 source version and editorial review status.
- [x] Produce a reproducible human-readable content review report.
- [x] Add a reproducible JSON dictionary audit queue and editorial override layer.
- [x] Document the JSON-versus-SQLite runtime storage decision and review triggers.
- [ ] Reassess every bundled English definition against an authoritative, legally usable offline source and retain only neutral, standalone game definitions.
- [x] Define source provenance and an editorial policy for imported definitions, including sensitive-sense selection and review rules.
- [ ] Triage and replace the current 2,180 long and 3,240 reference-definition flags before expanding answer pools; counts refer to the complete raw/effective audit, not unique unsafe words.
- [ ] Complete a broader family-suitability review of every active solution.
- [x] Generate compact release assets separately from authoring records.
- [ ] Measure cold startup and dictionary filtering on a modest physical phone.

## Bujho: Guess the Word engine

- [x] Build the first pure Dart engine component independent of Flutter widgets.
- [x] Implement correct two-pass repeated-letter evaluation.
- [x] Support configurable word lengths, including four, five, and six graphemes, in the domain layer.
- [x] Support English filtering in the domain layer.
- [x] Support romanized Punjabi filtering in the domain layer.
- [x] Support Mixed English/Punjabi with English and romanized guesses accepted in the domain layer.
- [x] Support Gurmukhi grapheme filtering and game evaluation in the domain layer.
- [x] Add seeded, non-repeating solution selection with exhaustion reset.
- [x] Persist non-repeating solution history across launches and use secure randomness.
- [x] Preserve pool-specific rotation history and prevent cycle-boundary repeats.
- [x] Model game progress, accepted turns, rejections, and win/loss states explicitly.
- [x] Add versioned serialization and offline storage for interrupted-game restoration.

## Bujho: Guess the Word interface

- [x] Build a minimal playable screen for fast iteration using temporary content.
- [x] Replace temporary `APPLE` content with the offline vocabulary repository and explicit starter solutions.
- [x] Connect English, romanized Punjabi, Mixed English/Punjabi, and initial Gurmukhi mode/length selection.
- [x] Restore interrupted games with their mode, length, turns, and keyboard feedback.
- [x] Add the shared Latin keyboard for English, romanized Punjabi, and Mixed English/Punjabi.
- [x] Add the initial purpose-built Gurmukhi keyboard with vowel signs and extended letters.
- [x] Show shared romanized pronunciation labels on Gurmukhi keyboards in Bujho, Dictionary, and Word Quest.
- [x] Disable keyboard symbols proven absent without breaking repeated-letter cases.
- [x] Add tile feedback symbols and semantic labels that do not rely on color alone.
- [x] Reveal the answer and its definition at game completion.
- [x] Add in-app gameplay help and language-mode explanations.
- [x] Consolidate language, word size, and theme controls into compact game settings.
- [x] Add a menu action that starts a new game with the current settings.
- [x] Show validation and status notices without resizing the gameplay layout.
- [x] Add a dedicated offline dictionary page with English, Romanized Punjabi, and Gurmukhi word-only search.
- [x] Add versioned per-mode and per-length statistics stored completely offline.
- [x] Add offline, clipboard-based spoiler-safe result sharing.
- [x] Support physical keyboards and IME submission with persistent input focus.
- [x] Add animations and haptics with reduced-motion/haptics settings.
- [x] Offer Off, Light, Medium, and Strong haptic feedback levels.

## Automated verification

- [x] Test exact, present, and absent letter evaluation.
- [x] Test the initial repeated-letter cases in guesses and solutions.
- [x] Test Unicode grapheme counting plus Gurmukhi keyboard composition and visible-grapheme deletion.
- [x] Test the initial language and grapheme-length filters.
- [x] Test accepted guesses versus curated solutions.
- [x] Cover offline statistics totals, streaks, distributions, isolation, persistence, and malformed-data fallback.
- [x] Add initial content-import and validation tests.
- [x] Add responsive widget tests for narrow library and fixed-viewport gameplay layouts.
- [x] Add Modern, Sikhi, and Dark golden tests (12 Windows visual baselines).
- [x] Add representative integration flows for preferences and interrupted-game restoration.
- [x] Establish a clean `flutter analyze` and test-suite baseline; keep both clean.

## Platform and release work

- [x] Verify local nested-path offline loading with the preview server stopped.
- [ ] Verify offline reload in the actual itch.io draft iframe.
- [ ] Reduce the initial uncompressed web artifact baseline (59.6 MB total; 17.9 MB generated vocabulary).
- [ ] Verify Android debug and release builds on emulator and physical hardware.
- [ ] Verify iPhone and iPad builds on macOS and physical hardware.
- [ ] Configure app identifiers, icons, splash screens, signing, and store metadata.
- [ ] Add a Cloudflare Pages preview workflow for compiled web assets.
- [ ] Decide whether the playable web app is separate from the future marketing site.
- [x] Choose itch.io web playtest as the next distribution target; publication is blocked by the release gates below.

## Later game modules

### Next priorities, selected September 12, 2026

- [x] Record Word Bridges as the next game and Journey Through Punjab as the
  next experiment. Starting concepts and deferred ideas are saved in
  `docs/product_decisions.md`, under Next games and saved concepts.
- [x] Finish and validate the first Word Bridges candidate: untimed four-pair
  word/meaning sets, accessible selection, saved progress, Help and its own
  statistics. Fixed starter content is implemented; see the candidate above.
- [ ] Try a small Journey Through Punjab prototype: select one location, source
  its cultural text, and design three short activities with accessible stop
  navigation and offline progress. Evaluate it before expanding into a campaign.
- [ ] Review the deferred Word Garden, Find the Connection, Build the Sentence
  and accuracy-first Typing Challenge concepts when ready for another game.

### Existing modules and shared work

- [ ] Define the reusable game-module contract.
- [x] Design and implement Khoj: Word Search using the full playable vocabulary, language modes, randomized grids, and drag selection.
- [x] Add Khoj compass styling, dictionary access, definition feedback, grapheme hints, and Gurmukhi pronunciation labels.
- [x] Compact Khoj into a fixed viewport with a single-row target strip and clearly labeled hint controls.
- [x] Build Chardi Kala: Word Quest as the kid-friendly themed alternative to Hangman.
  - [x] Implement Unicode-safe letter guessing, try tokens, hints, and win/loss states.
  - [ ] Verify age-appropriate common words in every language/length pool. Current filters check clue structure, not age suitability; bulk approval is insufficient.
  - [x] Build the respectful Sikh-inspired word-garden scene and child-friendly keyboard.
  - [x] Add new-game, language/word-size difficulty, help, haptics, and reduced-motion behavior.
  - [x] Keep 4–6 answer tiles on one row and move the hint beside the adaptive heart counter.
  - [x] Add reversible simple/full keyboards and romanized pronunciation on Gurmukhi tiles.
  - [x] Move the keyboard toggle beside Hint and use floating gameplay feedback to preserve vertical space.
  - [x] Shorten long source definitions to a concise first sense and expose the offline Dictionary from Word Quest.
  - [x] Show the Romanized terminal answer and one-line definition previews with full-definition feedback.
  - [x] Replace the garden with a separator while the full keyboard is open so the expanded bank fits phone screens.
  - [x] Add domain, widget, responsive-layout, and navigation tests.
- [ ] Revisit an accuracy-first Typing Challenge after the selected priorities;
  untimed by default, with optional timed challenges. See the saved concepts.
- [ ] Reuse the shared content repository, themes, settings, and statistics.

## Earlier itch.io readiness audit (superseded by build 6 above)

**Decision: not ready for unrestricted public release.** All three games are
implemented and can be exercised in a developer playtest. Content suitability,
source review, and target-browser checks still gate public distribution.

### Confirmed and addressed

- [x] Pulled `main` with fast-forward-only: already current. Preserved pre-existing
  local edits, the V1 reference, and local editorial backups.
- [x] Baseline complete unit/widget suite: 97 passing tests. Added targeted
  regression coverage during this audit; final rerun results follow below.
- [x] Built the release web app using local CanvasKit resources.
- [x] Replaced default Flutter metadata, added startup feedback, bundled a
  licensed Gurmukhi font, and added third-party notices.
- [x] Restricted bundled content to three sanitized release JSON files; review
  queues and backups are excluded. Added a checked, versioned ZIP helper.
- [x] Fixed stale Bujho Continue visibility for invalid saves and rejected
  zero/negative saved attempt limits. Updated stale integration launch selectors.
- [x] Removed em dashes from authored player copy. Definition display uses shared
  punctuation cleanup while source definitions and serialization remain intact.
- [x] Reviewed 20 confirmed unsuitable random answers and recorded exclusions in
  editorial curation, with machine-review status rather than human approval.
- [x] Corrected stale Modern/Sketch documentation to Modern/Sikhi/Dark, replaced
  the template app README, and refreshed architecture/testing/content docs.
- [x] Browser QA at a nested HTTP path: Bujho physical-keyboard guess and
  real-browser saved-game restoration; full Khoj puzzle completion using forward,
  reverse, and vertical drag; Word Quest on-screen complete win.

### Release blockers and required follow-up

- [ ] Complete a reviewed public-playtest answer pool. Audit began with 46,995
  records, 46,989 accepted guesses, and 33,331 solution-eligible records.
  Machine flags: 3,240 reference definitions, 2,180 long definitions, 16 duplicate
  spelling flags, eight missing Gurmukhi forms, and two empty definitions.
  Removing 20 known bad answers is not a safety guarantee for the remaining pool.
- [ ] Review child suitability separately from dictionary correctness. Random
  Word Quest produced ATRIP, with a nautical clue, in browser testing. Obscure,
  insulting, adult, violent, historical-medical, and proper-name senses need
  decisions. Dictionary content remains broader than random answers. Unclear legacy
  definitions are now hidden, but sourced senses still need editorial review. Do not advertise a fully child-safe dictionary.
- [x] Exclude unclear V1-derived definitions from distribution. Release generation
  clears all their definition arrays and removes them from random answers.
  OEWN, pinned Mahan Kosh, and original project text remain visible with notices.
- [ ] Source and review replacements for the 28,716 hidden legacy definitions.
- [ ] Test the final uploaded itch.io draft iframe on Chromium, Firefox, Safari,
  Android touch, and iOS Safari: focus, fullscreen, drag, clipboard, reload,
  and storage with restrictive browser settings. Local preview is partial evidence.
- [x] Verify keyboard-only Khoj selection and completion in the local browser.
- [ ] Verify real screen-reader usability across games.
- [ ] Measure startup/download and dictionary filtering on a modest phone. Compact
  runtime JSON and a reproducible authoring workflow are implemented; physical
  mobile performance remains unmeasured.
- [x] Implement a generated, scoped offline application cache with bounded assets,
  atomic installation and version-safe activation. Behavior and generator tests pass.
- [x] Verify packaged offline reload locally: closed online tab, stopped the
  no-store HTTP server, reopened the nested URL, restored Bujho, generated Gurmukhi
  Khoj, and completed Word Quest.
- [ ] Verify offline reload in the uploaded itch.io iframe.
- [x] Add original cover art and icons, controls/known-issues page copy, and a
  feedback route with clipboard-failure handling.
- [x] Capture packaged game screenshots in reports/release/.
- [x] Pass browser integration in CI using the documented web-server target and
  explicitly matched Chrome/ChromeDriver paths. Run 34671765499 passed the
  preferences and interrupted-game flow on release web code. The in-memory
  fixture remains separate from the manual real-browser storage checks.
- [x] Add 12 deterministic theme goldens and Windows CI comparisons.
- [ ] Complete representative screen-reader and physical-device haptic checks.

### Scope and documentation notes

Architecture is suitable for the present offline static collection; no backend,
account system, or database migration is needed to ship a playtest. Large widget
files and synchronous vocabulary parsing deserve measured follow-up, not a broad
rewrite before release. The typing game is future scope and is not a release
blocker for the three-game collection. Android debug signing and macOS/iOS device
validation block mobile-store releases, not the itch.io web artifact.

The maintained Markdown documents were checked for current scope, themes,
validation, and release claims. Generated Markdown under reports/content remains
historical/reproducible audit output rather than being manually rewritten as
current editorial approval. The iOS LaunchImage README remains platform template
instructions, not the project's release documentation.

Spark supplied `reports/content/spark_definition_proposals.json`: 150 triage
records, 103 marked needs_expert_review and 47 keep; zero replacement definitions
or source citations. Parent review found false positives and generic reasons,
including an unsupported circular-definition claim for ABJECT. No proposals were
applied automatically. This is an unverified queue, not completed cleanup.

### Additional confirmed fixes and evidence

- [x] Fixed 200% text-scale overflows in shared launch options and Khoj hint
  controls; added a widget check across the three games at 390 by 844.
- [x] Added the documented Word Quest physical-letter input and same-word retry
  after a learning finish. Tested the loss/retry/keyboard path.
- [x] Protected local dictionary-editor writes against cross-site requests and
  untrusted Host-based origins. Seven focused guard tests pass, including opaque
  and malformed origins. This tool is excluded from the distributed game.
- [x] Tested all 12 language/length pools using real assets; measured counts live
  in docs/content_schema.md. Those earlier counts are superseded by the expanded build-6 pool above.
- [x] Browser package check: Gurmukhi glyph display, whole-grapheme composition
  and deletion, and Dictionary keyboard search. Mobile-sized browser override
  did not change the captured viewport, so mobile evidence remains widget-only.
- [x] ZIP layout inspected: root index.html, relative base, local Gurmukhi font
  and license notices, no review decisions/backups; archive within current itch
  file-count, path-length, per-file, and total-size limits.

Security review found no app accounts, backend calls, or embedded credentials in
the examined runtime code. This is a scoped source/configuration review and
regression testing, not a claim of a complete penetration test or an independent
vulnerability database scan. Remaining browser storage/clipboard restrictions
must be checked in the actual host. Dependency patch updates can be evaluated
separately; no dependency upgrade was forced during this audit.

### Historical automated gate results for 1.2.1+4

- Full Flutter suite: **110 tests passed** after the fixes.
- Static analysis: **no issues found**.
- Formatter check: **77 Dart files checked, zero changes required**.
- Content audit: **46,995 records, 5,446 editorial flags**; the command succeeds
  but these flags remain open and are not an editorial approval.
- Release web packaging succeeds with relative paths and local renderer resources.
  The audit artifact keeps the existing development version 1.2.1+4. README.md
  records the next-distribution version recommendation and publication gates.

Final ZIP: `app/dist/sikhi-word-games-web-1.2.1+4.zip`, 18,387,867 bytes
compressed, 76,287,618 bytes extracted, 50 files. Archive integrity, root index,
relative base, and exclusion of editorial backups verified. SHA-256:
`e17952db7deefae66cdb3c2cac6b4f4d3a138c8358181ac7a1fd0411af820ccb`.
This is a local developer-playtest artifact, not approval to publish.

The final ZIP was extracted and loaded under another nested HTTP path. Visible
home credits and version matched the package. Word Quest physical-keyboard input
was verified through a complete SUPER win in that final archive. Earlier browser
runs also covered Bujho restoration, Khoj completion, Gurmukhi composition/delete,
and Dictionary search. These are local Chromium-based checks, not uploaded
itch.io or native mobile sign-off.

## Aesthetic and content follow-up (September 2026)

- [x] Shared theme refresh: teal Modern, navy/cream Sikhi, deep-blue Dark;
  stronger action hierarchy, decorative game previews, clearer type and softer
  shadows. Word Quest uses shared surfaces and garden colors throughout.
- [x] Added full Khoj keyboard play; independently reviewed and fixed mixed
  pointer/keyboard state, selection focus contrast and clipped target labels.
- [x] Fixed Word Quest Continue staying on the loading screen after restoring a
  saved round. Added a regression with an already revealed letter.
- [x] Applied five checked OEWN definition/sense corrections. LUST and STUD are
  guess-only. The broader content audit still has 5,446 editorial flags.
- [x] Added bounded content triage. Only explicitly checked corrections may be
  written; generic suggestions remain manual-review candidates. A zero pending
  result covers changed OEWN candidates, not the entire dictionary.
- [x] Reviewed Spark's proposals as signals; no unsourced suggestions were used
  as replacement definitions or automatic answer approvals.

The useful next feature work is a familiar-word difficulty option backed by
reviewed vocabulary labels, a saved-words learning list in Dictionary, and clearer
progress/statistics across games. These need scoped product work after playtest
feedback. They are not required to make the current three core loops playable.
Typing Challenge remains clearly marked Coming later and is not a fourth
playable mode. Do not add accounts or online leaderboards for the playtest.

That pass selected **1.3.0+5** because it added keyboard
play and a visible theme refresh. Existing audit archives remain development
version 1.2.1+4; no tag or publication has been made. The earlier archive hash and
size above describe the pre-refresh build and are superseded by this pass.

Follow-up automated gates: **117 tests passed**, static analysis found no issues,
and **82 Dart files** passed formatting without changes. The content audit again
reported **46,995 records and 5,446 open flags**. Pool counts were remeasured from
the runtime assets and updated in docs/content_schema.md (33,309 eligible
records). The checked-in runtime source has no em dashes, en dashes, or Unicode
ellipsis; displayed imported definitions use the shared punctuation cleanup.

Refreshed developer-playtest ZIP: app/dist/sikhi-word-games-web-1.2.1+4.zip,
18,186,296 bytes, 50 files. SHA-256:
`db48ea9e648a9b20f9ca9d4b00556f8409d572d6a10ba802f575f4c5bcc7375a`.
Release build and archive extraction succeeded. Publishing remains blocked by
the content/licensing and actual-host validation gates described above.

Final extracted-package browser verification confirmed Word Quest Continue loads
its saved round, Khoj target words are fully visible, and keyboard selection
found FENNY. The final local preview is served at
http://127.0.0.1:8765/aesthetic-verified/ while the development server is running.

## Google Play preparation, feasibility assessed September 12, 2026

Study and sources: `docs/product_decisions.md`, Google Play feasibility assessment.
Status: Android package feasible; public Play release not ready. No publication authorized.
- [ ] Confirm Play account type/verification and any 12-tester/14-day eligibility gate.
- [ ] Configure production upload signing, Play App Signing and validated AAB.
- [ ] Finish Android launcher name/icon and store listing assets/support details.
- [ ] Add public and in-app privacy policy; complete accurate Data safety, audience,
  ads and content-rating declarations, including Families requirements if applicable.
- [ ] Verify build 9 or successor on actual devices and 16 KB native compatibility.
- [ ] Resolve intended-audience content/accessibility gaps and expand Bridges variety.
- [ ] Recruit a real closed-beta cohort; assess repeat use before a community launch.
- [ ] Consider asking Albatross Singh (Amrit Punjabi) for advice on community
  outreach and maintaining free Punjabi apps. Both reference apps and public
  support contact are recorded in `docs/product_decisions.md`, under Potential
  advice contact. No outreach sent.

## Fresh visual review: build 9 (September 12, 2026)

Evidence and proposed audience/design direction: `docs/product_decisions.md`,
Visual review and audience hypothesis. The approved first pass is implemented in 1.6.0+10.
- [x] Fix Bridges/shared backdrop stopping at short content height.
- [x] Make Bridges selected/matched states keep stable target positions; apply
  shared shapes and stronger success surfaces with non-color cues.
- [x] Let Quest clues and language labels remain readable at narrow widths;
  enlarge essential status text and show the full definition directly.
- [ ] Review the Quest clue 'someone deranged and possibly dangerous' through
  the content curation workflow; do not edit release shards by hand.
- [x] Implement compact library cards and distinct game illustrations; de-emphasize
  unavailable Typing Challenge and repeated New game/options controls.
- [ ] Unify game toolbar, progress and completion treatments across three themes.
- [ ] Test the proposed teen/adult learner focus with younger guided and older
  low-vision users before locking audience or a full art refresh.

## Approved visual redesign: 1.6.0+10

- [x] Apply shared illustration family, quieter full-height backdrop and consistent
  standard Material button shapes/minimum heights across Modern, Sikhi and Dark.
- [x] Compact home gallery with one primary action and an accessible options icon;
  two columns on wide screens, one column at narrow widths or large text.
- [x] Name Word Bridges **Jodo: Word Bridges (ਜੋੜੋ)** in library, help and statistics;
  retain saved progress identifiers. Name rationale/source in product decisions.
- [x] Stable readable Jodo word/meaning cards with Selected/Matched text and checkmarks.
- [x] Wrapping Quest clues/status and inline live feedback that cannot cover keys.
- [x] Full functional suite: 202 passed; new gallery semantics regression also passes.
  Eighteen visual fixtures cover library, Jodo and the existing game/theme screens.
- [x] Final packaged browser review and refreshed web ZIP/Android APK artifacts.

The broad content queue, native screen-reader/device checks, dense keyboard/grid
accessibility work and production-store gates above remain open. This redesign
has no vocabulary edits or change to the proposed audience hypothesis.

Packaged browser evidence: reviewed the redesigned library in Sikhi/Modern at
1280x800 and Dark at 360x800, Jodo English/Gurmukhi and a selected/matched pair at
360x800, and Quest wrapping clue plus unobstructed inline feedback. The final
archive was extracted to `app/dist/review-1.6.0-10-final/`; its wide AX tree now
groups each game's title, description and actions before the next card. Final
Jodo restored the saved Gurmukhi match, rendered the language icon and singular
attempt label. Original Sikhi theme and default viewport restored. Local review:
http://127.0.0.1:8877/review-1.6.0-10-final/ . No actual-host iframe or fresh offline
restart test in this visual pass. Pixel was absent from adb; APK built but not
installed. Public publication and production Play signing remain separate gates.

Final validation on the packaged source: **221 tests passed**, including all
18 golden comparisons; static analysis found no issues. Release content check and
distribution audit passed. Web ZIP: 16,869,226 bytes, SHA-256
`ca26257adf6487a65c9261f848821e2ef3756b9960743181904918f7466b3fbb`.
Android APK: 55,252,794 bytes, SHA-256
`8b688548745cff4cf72ed3c25ab50d85def151c2d66b7080095de4a65fa8050e`.
Files: `app/dist/sikhi-word-games-web-1.6.0+10.zip` and
`app/dist/sikhi-word-games-android-1.6.0+10.apk`.

## Phone layout follow-up: 1.6.1+11

- [x] Compact saved/unsaved home actions, with 48-pixel targets and large-text fallback.
- [x] Jodo phone word bank and full-width meanings; aligned wider-screen rows.
- [x] Source-backed Romanized text below Gurmukhi words, including restored sets.
- [x] Complete regression checks, visual checks and refreshed review packages.

Validation: **229 tests passed**, including **20 golden comparisons**; analyzer
clean. Shipped-font tests confirm saved/unsaved action rows at320px; Gurmukhi
Romanized labels also pass at320px/200% text. Inspected English long-definition
and Gurmukhi phone goldens. Final packaged browser at360x800 confirmed compact
saved/unsaved home controls, restored Gurmukhi spellings and a stable completed
match. Default viewport restored and current Dark theme retained. Local review:
http://127.0.0.1:8877/review-1.6.1-11/ . Web ZIP and Android APK built successfully;
no new emulator/device, hosted iframe or offline-restart evidence in this pass.

Artifact: app/dist/sikhi-word-games-web-1.6.1+11.zip, 16870130 bytes, SHA-256 f9ee85f21affcb31cd02d8e9fa98d907be9dcb6ff4393ce5c88d3a08aee6f38c.

Artifact: app/dist/sikhi-word-games-android-1.6.1+11.apk, 55269074 bytes, SHA-256 4c361df0b6ef68839dd490550aa34fbedf2a22fb5b4ff2f2242f5b77c5914f60.

## Khalsa Game Studio branding: 1.6.2+12

- [x] Studio byline and optional website action in the library, with selectable
  address fallback when a browser cannot be opened.
- [x] Branded browser title, loading copy, web metadata and four-game release cover.
- [x] Correct Android/iOS display names; keep application IDs and saves unchanged.
- [x] Validate and rebuild branded web/Android review artifacts.
- [ ] Verify supplied studio website availability before public launch.

Branding validation: analyzer clean,211 functional tests and20 golden comparisons
passed. Inspected all three library themes, the630x500 studio-attributed cover
and192px Android launcher artwork. Packaged browser confirmed branded loading,
title, byline, studio button and version1.6.2/build12. Website-button activation
left the game intact; the external destination was not visible in the controlled
browser and site availability is still unverified. Review page:
http://127.0.0.1:8877/review-1.6.2-12/ . Existing theme/viewport retained.
Android APK badging confirms version1.6.2/code12, label'Sikhi Word Games', and all
five launcher icon densities. Production signing and store-publication gates
remain open; no device install or iOS build in this pass.

Artifact: app/dist/sikhi-word-games-web-1.6.2+12.zip, 16872836 bytes, SHA-256 3369967ec89262f4b4143a6f900950bc5749d0a7043b2cdfda092d838f1e01a7.

Artifact: app/dist/sikhi-word-games-android-1.6.2+12.apk, 55304836 bytes, SHA-256 282844287c50e75b0e2ad25d62853c4b457c31c20a29a834661d6e84789c3413.

## App settings and fresh-start testing: 1.7.0+13

- [x] Move Your statistics from the home footer into App settings, covering all four games.
- [x] Add Reset all app data with explicit confirmation, busy-state protection and retry on partial storage failure. Restore guides/settings and remove only owned player data; preserve content and unrelated storage.
- [x] Serialize repository writes and resets by store/key so pending writes from another repository instance drain before removal.
- [x] Analyzer clean; full suite passed 240 checks. Separate reset/visual verification passed 25 checks against updated intentional home baselines, including 320px/200% text and blocked Back during reset.
- [x] Installed and launched branded 1.6.2+12 on attached Pixel 6 using an in-place update; player data retained.
- [x] Package web 1.7.0+13 and inspect its App settings at /review-1.7.0-13/: both statistics and reset are visible and readable on the narrow Dark-theme preview. Browser interaction stopped when the user resumed Jodo; reset/cancel behavior is covered by widget tests. No real data cleared.
- [x] Built Android 1.7.0+13 and installed in-place on Pixel 6 (adb Success), preserving user data. APK: app/dist/sikhi-word-games-android-1.7.0+13.apk; web ZIP: app/dist/sikhi-word-games-web-1.7.0+13.zip.




## Victory celebrations: 1.8.0+14

- [x] Add shared short particle bursts, trophy banner and original offline victory chime for newly earned wins in all four games.
- [x] Add persisted global and per-game sound/particle controls from App settings and each game menu; honor reduced motion and stop effects on new rounds/background/disposal.
- [x] Remove Typing Challenge teaser and record Akhar Pachhaan letter-recognition proposal with reviewed offline pronunciation clips; no new game implementation in this round.
- [x] Analyzer clean and full suite passes 258 checks, including all four win hooks, loss/reopen silence, saved opt-outs, reduced motion and four victory visual baselines.
- [x] Packaged web/Android 1.8.0+14; web distribution audit passed and the 42-file offline cache manifest includes the original victory.wav asset. Played Jodo to 4/4 in the packaged localhost review and captured the trophy/particle burst; inspected both in-game switches on a narrow screen. Physical speaker audibility/volume remains a human playtest check.
- [x] Installed Android 1.8.0 (versionCode 14) in-place on connected Pixel 6; adb Success and package version verified, launch intent delivered. User data preserved.
- [x] Release artifacts: app/dist/sikhi-word-games-web-1.8.0+14.zip and app/dist/sikhi-word-games-android-1.8.0+14.apk. Web review at /review-1.8.0-14/.




## Akhar Pachhaan: Learn Letters: 1.9.0+16

- [x] Build 35-letter name-recognition game, five-question rounds, gentle retries, saved progress, practice collection and own statistics.
- [x] Integrate home card, first-launch/replayable help, global statistics, victory preferences and all-data reset.
- [x] Generate 35 native-Punjabi robotic WAV previews for owner review; files validated non-silent/unclipped (1.72MB total). Bundle locally and expose explicit Hear controls.
- [x] Static analysis clean; full suite passes 277 checks, including Learn Letters launch/guide/Continue/completion/global statistics, owned-key reset, deterministic engine tests and four phone/theme visual baselines.
- [x] Packaged web and Android 1.9.0+16. Actual packaged browser caught and verified the fix for a web-only random-bound startup error; 40 follow-up engine, integration and visual checks pass. Correct-answer and Letter progress Hear controls enter playback without new console errors. All 35 clips are included in the offline cache; physical audibility and pronunciation remain owner checks.
- [x] Artifacts: app/dist/sikhi-word-games-web-1.9.0+16.zip and app/dist/sikhi-word-games-android-1.9.0+16.apk. Review at /review-1.9.0-16/.
- [x] Installed 1.9.0+16 in-place on Pixel 6 on 2026-09-13: adb Success, versionName 1.9.0 / versionCode 16 verified, launch intent delivered. Existing game data preserved.
- [ ] Owner/fluent-speaker review of letter-name spellings and generated pronunciations before treating audio as approved teaching content.
