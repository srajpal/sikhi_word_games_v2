# Sikhi Word Games V2 — TODO

This is the persistent project checklist. Keep it updated as work progresses; do not remove incomplete scope.

## Current release candidate: 1.3.0+5

The candidate targets an itch.io public playtest, not a completed child-suitability
review or mobile-store release. Bujho, Khoj, and Word Quest are implemented.
Typing Challenge remains future scope. Historical validation entries below retain
their original version and are superseded by this candidate's final checks.

- [x] Keep 46,989 accepted guesses while limiting random answers to 14,892 sourced,
  standalone records. All four language options support lengths 4, 5, and 6.
- [x] Distribute 18,279 licensed/original definitions; hide 28,716 unclear legacy
  definitions without deleting authoring history or claiming human approval.
- [x] Add original branding, all three shared themes, bundled Latin/Gurmukhi fonts,
  playtest review notice, and player feedback.
- [x] Scan all 85 hosted Pub dependencies against OSV: no known advisories returned.
  This does not cover unknown vulnerabilities or the Flutter/native SDK itself.
- [x] Complete local package/browser validation: 136 tests pass, including 12
  theme goldens; analyzer, content gates and cache behavior checks pass.
  ZIP: 16,905,406 bytes, 51 files, 60,578,513 bytes expanded.
  SHA-256: 7bb2edd756988fd289e4ee79d29d3dadd0732f9adc0eef151c6a12f0f3993e87.
  See reports/release/package_audit.json and browser_qa.json.
- [x] Pass hosted browser integration and Windows visual checks on commit 8492ec5.
- [ ] Confirm the uploaded itch.io draft, real mobile performance and accessibility.
- [ ] Expand the seven-entry four-letter Romanized Punjabi answer pool with
  sourced, reviewed definitions to reduce repetition.

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
- [ ] Confirm four-letter Punjabi entries against an authoritative licensed source and record manual decisions.
- [x] Build a native Gurmukhi expansion pipeline targeting real five- and six-grapheme headwords.
- [x] Evaluate open-license Gurmukhi sources (including Mahan Kosh data) and document provenance/attribution before bundling.
- [x] Import, normalize, deduplicate, and rank native Gurmukhi candidates separately from Romanized transliterations.
- [x] Expose native Gurmukhi candidates in the local review tool with provenance and length filters.
- [x] Add an idempotent apply step for reviewed native Gurmukhi decisions.
- [x] Review Gurmukhi candidates for standalone definitions, appropriate game usage, names, and offensive terms (project-owner bulk approval recorded; follow-up cleanup remains tracked by the content audit).
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
- [ ] Design and implement a timed typing/accuracy game.
- [ ] Reuse the shared content repository, themes, settings, and statistics.

## itch.io readiness audit (2026-09-12)

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
  in docs/content_schema.md. None is empty; adding more words is not the priority.
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

### Final automated gate results

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

The next distributed version should be **1.3.0+5** because this pass adds keyboard
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
