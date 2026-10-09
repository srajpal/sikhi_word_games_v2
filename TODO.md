# Sikhi Word Games V2 TODO

This is the current checklist, reconciled on October 9, 2026. Open boxes describe
remaining work. Completed milestones are evidence, not sign-off for a newer
package. Keep one task per outcome; update counts from fresh reports instead of
copying old audits. The current dictionaries are an explicitly owner-approved
source snapshot; integrity checks do not reopen editorial approval.

## October 9 simple Punjabi and equal cards: candidate 1.15.0+27

- [x] Add an immediately saved Simple Romanized Punjabi setting, retaining the
  original accented keyboard/view and exactly three language choices.
- [x] Derive simple spelling in memory for the four word games and Dictionary;
  preserve native Gurmukhi and approved source bytes. Keep each saved round's
  spelling view independent of later preference changes.
- [x] Import the 21:07 UTC English release, including MICE, updated notices and
  exact 13,182/2,991/4,428 master totals. Punjabi source files are unchanged.
- [x] Give all games equal phone cards and equal larger tablet/wide-web cards;
  remove Bujho's featured treatment and keep phone illustrations separate.
- [x] Complete focused/full checks, review updated phone/tablet visual captures,
  verify the release browser and build/install the Android test update.

Build 27 evidence: 363 Flutter tests (including 35 visual baselines) passed;
analysis is clean and 148 Dart files are formatted. Source/runtime checks verify
20,601 records and unchanged Punjabi masters. The packaged browser shows equal
cards at 390x844 and 800x1100, ASAN with an A-Z keyboard, and the original accented
keyboard after switching Simple off. That choice survives reload; Simple was
restored on afterward. Existing saved rounds were retained. Updated credits and
licenses match the package, and the 1.15.0+27 web ZIP and debug APK are built.
K70 PRO was updated with `adb install -r`; version 1.15.0/code 27 and PID 28321
were verified. Pixel 6 was subsequently updated with `adb install -r`; version
1.15.0/code 27, successful foreground launch and PID 29614 were verified, with
app data retained. Hands-on device checks and the existing offline/iframe release
checks remain separate open work below.

## October 9 automatic settings: candidate 1.14.0+26

- [x] Apply and persist App settings on every control change; keep the page open
  and remove Save/Cancel. Use the same behavior for per-game celebrations.
- [x] Preserve ordered background writes, Back navigation, storage error notices,
  and separately confirmed data reset.
- [x] Verify focused/full Flutter checks and actual release-browser persistence;
  rebuild the web preview and install/launch the new tablet test build.

Build 26 evidence: 354 Flutter tests (including 35 visual baselines) passed;
analysis is clean and 146 Dart files are formatted. The actual packaged release
browser retains Dark theme and Reduce motion after reload without Save. Both
original preferences were restored and Settings remains open without Save/Cancel.
Web package integrity passes and the 1.14.0+26 ZIP is built. Android installed
with `adb install -r` on K70 PRO; version 1.14.0/code 26 and running PID 26791
were verified. Hands-on tablet behavior remains a separate manual check.

## English accepted-guess coverage

- [x] Import the updated approved English release with 655 additional inflections
  and WordNet exception forms, including MICE. English now has 13,182 words.
  The approved source resolves this gap without hand-editing runtime assets.

## October 9 owner-approved dictionary import: candidate 1.13.0+25

- [x] Record the owner's approval of every word and selected definition in
  `C:/dev/Projects/ChatGPT/sikhi_word_games_word_lists/release`. Preserve source
  notes as provenance without applying another app editorial/frequency gate.
- [x] Update current source/schema/architecture/testing guidance for three native
  JSON masters and source-defined written units; retire previous review queues
  as release inputs while preserving their dated milestones.
- [x] Import the approved snapshot to `app/content/approved_release/` and ship
  unchanged `english/words.json`, `punjabi/romanized/words.json` and
  `punjabi/gurmukhi/words.json` with attribution and licenses. Source totals are
  12,527 English, 2,991 Romanized Punjabi and 4,428 Gurmukhi; native six-tile
  Gurmukhi has 33 words. Counterparts must not expand another mode's membership.
- [x] Adapt game/dictionary input, keyboards, selection and saved-target checks
  to preserved scholarly Roman diacritics and source `letter_units`/`tile_count`,
  including Gurmukhi conjuncts where generic grapheme segmentation differs.
- [x] Validate exact source/release bytes, counts, units, mode isolation and
  locally reproducible import/build/check; run applicable tests, full Flutter
  checks, reviewed goldens, cache checks and release web/debug Android builds.
- [x] Inspect the actual build 25 package and browser across all three modes,
  including scholarly input, native conjuncts and mode-filtered Dictionary.
  WordNet APPLE, Romanized ĀSĀN and Gurmukhi ਅਪ੍ਰੈਲ lookups work. Updated
  credits display WordNet, Wiktionary/Kaikki and Shutterstock. Real browser
  progress remains 6 rounds/16 solved words/11 badges across the update.
  Install/launch build 25 on K70 PRO with existing app data preserved.
- [ ] Repeat actual offline reload for build 25 and the eventual itch.io iframe.
  Worker/cache unit checks pass. Automatic approval review rejected stopping
  the local preview server because it would disrupt the user's open preview;
  the server remains running and actual offline reload is not claimed.

Build 25 evidence: full Flutter suite passed (351 tests, including 35 visual
baselines and legacy conjunct-save/control-label regressions).
Full analysis is clean, 145 Dart files are formatted, both cache/update Node
checks pass, and source/runtime audits verify all 19,946 records without
editorial filtering. Git-index bytes also match every supplied manifest hash.
The release ZIP has 7 exact runtime files, all licenses and three font notices;
no authoring inputs or retired banks are bundled. Build 25 debug APK installed
with `adb install -r` on K70 PRO; version 1.13.0/code 25 and running PID verified.
Browser lookups, updated sources and unchanged saved totals are verified;
hands-on tablet gameplay,
screen-reader and speaker verification remain separate manual checks.
Build 23 results below are historical evidence.

## October 8 mobile navigation and dictionary v2: 1.12.0+23 (historical dictionary policy)

- [x] Persist the same native bottom navigation on Play, Dictionary, Progress
  and Badges, with the current destination selected.
- [x] Put language and applicable word length inside each compact paper title.
  Scope feedback to its game; remove duplicate Learn Letters and Jodo introductions.
- [x] Move Jodo New set into its menu. Khoj uses mixed 2–12-grapheme words,
  a language-only picker and an adaptive grid; valid older saves still restore.
- [x] Replace runtime vocabulary with two source-backed banks: 2,443 English
  dictionary records (809 answers), and 4,026 Punjabi records (279 answers).
  English uses Simple English Wiktionary and pinned wordfreq scores; Punjabi
  uses source-checked English Wiktionary senses. No Punjabi frequency is claimed.
- [x] Hold 326 otherwise-neutral English entries from random answers for adult
  domains, advanced abstractions, misleading homographs or weak clues. Retain
  those for lookup/guesses; exclude a vandalized source entry entirely. The
  English 4/5/6-letter answer pools are 221/191/109; frequency alone is insufficient.
- [x] Reproduce imports, policies, holds, attribution and release assets with
  `dart run tool/dictionary_v2.dart --check`, offline. Routine changes use preview,
  exact source-backed exceptions, then `--write`; retired authoring queues are
  historical. All current decisions are machine checked, not human approval.
- [x] Add distinct original letter/button click sounds and independent saved
  Settings switches. Preserve pronunciation audio and victory controls.
- [x] Review refreshed phone/tablet and theme screenshots. All 367 Flutter tests
  pass against the reviewed baselines; analysis is clean, 174 Dart files are
  formatted, content reproduction/audits, nine Python policy tests and both
  offline-cache/update JavaScript checks pass.
- [x] Verify the actual release browser: all four destinations keep their
  navigation with the correct selection; Dictionary finds the new APPLE sense;
  Jodo starts a new set from its menu with exactly three languages; Khoj has
  language-only options and mixed lengths; Learn Letters keeps target audio
  below the letter. Quest feedback disappears immediately when returning to Play.
- [x] Verify both click-sound opt-outs persist through an actual browser reload;
  restore the original on settings after the check.
- [x] Compile release web and debug Android, and install/launch build 23 on
  K70 PRO using `adb install -r`. Package version 1.12.0/code 23 and running
  process verified; visible gameplay and speaker audibility remain manual checks.
The outstanding dictionary-v2 sampling, frequency-refresh and six-word-pool
expansion proposals are superseded by the October 9 owner-approved source
release. They are retired follow-ups, not unfinished approval gates for build 25.

## October 8 play consistency update: 1.11.0+22

- [x] Three supported game languages, shared language header and menu-only language
  changes. Preserve historical statistics and valid older Quest budgets.
- [x] Quest lantern countdown, 3/4/5 missed letters, 0/1/2 hints and shared toasts.
- [x] Jodo draws repeat-aware, unambiguous sets from eligible words across lengths.
- [x] Always-visible target audio and persisted reverse listening practice.
- [x] Distinct Modern/Sikhi/Dark surfaces and responsive bilingual tile wordmark.
- [x] Dedicated Settings/Dictionary/Progress/Achievements and per-game progress pages.
- [x] Fifty achievement badges, ten per game, derived from durable statistics;
  new facts are atomic with game completion, deduplicated and resettable.
- [x] Final validation: 343 Flutter tests pass against reviewed visual baselines,
  166 Dart files formatted, clean analysis and successful release web/debug APK
  builds. Browser at `http://127.0.0.1:8920/` verifies the new logo, dedicated
  Settings/Achievements, historical badge credit and exactly three language
  choices. A fresh five-letter Quest shows four misses, one hint and the lantern;
  no browser console errors were observed during these checks.
- [x] Fix the Settings save/route-refresh race. The widget regression and local
  save/restore fixture pass; the actual release browser returns to the library
  after Save and retains progress across reload.
- [x] Rebuild the vocabulary report through the pipeline after Jodo selection
  code changed. Only its code fingerprint changed; release content and holds
  remain unchanged, with no pool coverage failures or unsourced solutions.
- [x] Install and launch build 22 on K70 PRO with `adb install -r`, preserving
  data. Installation Success, launch Status ok, version 1.11.0/code 22 and
  running PID verified. Visible device gameplay still needs a hands-on check.
- APK: `app/dist/sikhi-word-games-android-1.11.0+22-debug.apk`, 178,128,168 bytes.
  SHA-256: `271e9cc539d880d8175420cba407ce6dad911ebd8c16c85ef50bd5881d2d06f4`.
- Sound replacement/review stays a separate task; this update reuses existing
  letter recordings and does not represent pronunciation approval.

## Current state

- GitHub issue-review baseline: PR #1 merged into `main` at
  `8056a0525ba9ffe0224bee6cffb1989002c87d93`.
  GitHub issues #3, #4, #5, #6 and #8 are closed as completed; no PR remains open
  from that review. The focused save/restore and keyboard fixes are in
  `eab3f11bc1adc83a0959d962bf1b94bff6104d5f`.
- Current Android testing version: 1.15.0+27, Paper & Play. The September 18 ZIP and uploaded
  itch.io draft remain 1.9.0+17 and
  predate the subsequent audit fixes and October vocabulary recheck. They are
  historical artifacts, not packages of current source. Increment both version
  sources and the build number when producing the next distributed package.
- The itch.io project is still a draft: project 5023423,
  <https://khalsagamestudio.itch.io/sikhi-word-games>. No public release is recorded.
- Pixel 6 last verified installation: 1.9.0+16 on September 13, preserving data.
  The old request to install build 8 is superseded by verified installs of newer
  builds; current-source device validation remains open below.
- Latest completed baseline before dictionary v2: 343 Flutter tests and
  successful analysis, web and Android builds (PR #12). Current dictionary v2
  validation is recorded in the milestone above.
- All five games, shared content/settings/statistics, offline save handling,
  Modern/Sikhi/Dark themes, responsive shells and Unicode-safe matching exist.
  Reusing these foundations is completed work, not an outstanding new module.

## October 8 Paper & Play reference correction: 1.10.1+20

- [x] Replace the rejected flat preview icons with five bundled dimensional
  scene backgrounds and a real paper texture matching the approved reference.
- [x] Add shared torn labels, teal/navy/blue gradient pill actions, ivory rims,
  raised tiles, and consistent native English-above-Punjabi naming. Keep all
  three themes and native Gurmukhi letters on the illustrated alphabet blocks.
- [x] Use scenic tablet cards and illustrated phone rows, retaining Continue,
  New game and options/help controls and flexible enlarged-text layouts.
- [x] Match amber/gray/green Bujho feedback and keyboard colors with readable
  ink and spoken clue values; repeated letters retain the strongest result.
- [x] Final validation: 329 Flutter tests pass against reviewed goldens without
  updating them, clean analysis, 156 Dart files formatted, successful release
  web and debug Android builds.
- [x] Install build 20 on K70 PRO with `adb install -r`, preserving data.
  Installation returned Success; launch Status ok, version 1.10.1/code 20 and
  running PID verified. The tablet was locked; visible device gameplay remains
  a separate check.
- APK: `app/dist/sikhi-word-games-android-1.10.1+20-debug.apk`, 178,085,300 bytes.
  SHA-256: `f85490c49b7c5b78ea550004f144337709409d0e4df68566ea1f18498425e09d`.
  Six artwork assets and three release vocabulary shards are byte-identical to
  source; all 35 letter WAV clips and bundled Noto Serif are present. The APK
  has the main.dart kernel and all three Android ABI runtimes. This remains a
  debug testing build; no web upload or publication occurred.

## October 8 Paper & Play redesign: 1.10.0+19 (superseded visual draft)

- [x] Replace the shared visual treatment across all five games and the library
  with paper surfaces, offset tile shadows, flat drawn illustrations and bundled
  serif headings. Preserve exactly Modern, Sikhi and Dark, game rules and saves.
- [x] Standardize smaller English titles above larger Romanized Punjabi game
  names using shared identities, including game headers and progress summaries.
- [x] Add direct offline Dictionary and existing Progress shortcuts. Feature
  Bujho above four responsive game cards; enlarged text can use one column.
- [x] Validate all game headings at 320/800 logical pixels and 100/200% text
  size across all themes. Review updated game/component/completion goldens.
- [x] Final validation: 327 Flutter tests pass against reviewed goldens without
  updating them, clean analysis, 154 Dart files formatted, and successful release
  web / debug Android builds. Shortcut tests cover Dictionary navigation and
  persisted Progress totals; tablet gallery actions align within each row.
- [x] Install 1.10.0+19 on K70 PRO with `adb install -r`, preserving existing
  data. Installation returned Success, launch Status ok, package version and
  running PID verified. The tablet still shows its lock/notification surface,
  so no visible device screenshot or hands-on gameplay verification is claimed.
- APK: `app/dist/sikhi-word-games-android-1.10.0+19-debug.apk`, 205,910,434 bytes.
  SHA-256: `3a127e6dba32af5c2534f45d642173d8f9bc42b0b54e01e7c4fdd2923e45b529`.
  The APK contains exactly three byte-identical current release vocabulary
  shards, 35 letter WAV clips, bundled Noto Serif and all three font licenses;
  no authoring content assets. This is a debug testing build, not production
  signing or release-performance evidence. No web upload/publication occurred.
- Physical phone/tablet playtesting and browser/offline/audio checks remain
  separate release gates. Updated widget screens do not establish these checks.

## October 8 tablet testing build: 1.9.1+18 (superseded candidate)

- [x] Build current source as an Android debug APK, without changing production
  signing. Verify package/version, all three current release vocabulary shards,
  all 35 letter clips and absence of authoring-only assets.
- [x] Install on the connected K70 PRO (M70_A), Android 16, arm64, 800 by 1280.
  ADB installation returned Success; installed versionName 1.9.1/versionCode 18
  and the running app process were verified. No previous current-ID package was
  present and no application data was cleared. Launch intent returned Status ok.
- The tablet lock/notification surface still covers the app. A visible gameplay
  screenshot was not captured; the owner must unlock it for hands-on testing.
  This establishes build/install evidence, not completed tablet gameplay,
  accessibility, persistence, pronunciation or release-performance QA.
- APK: `app/dist/sikhi-word-games-android-1.9.1+18-debug.apk`, 174,610,843 bytes.
  SHA-256: `7a335f23e432f1711ca64adddc05a4839e768cf7fe155e7ade340018fdf5ab45`.
  The vocabulary pipeline check passes; Android compilation succeeds. The
  unchanged gameplay baseline previously passed 311 tests. No new web upload.

## Retired vocabulary recheck: historical evidence

Use `docs/definition_sources.md` for the single-command workflow and its limits.
`reports/content/vocabulary_recheck.json` is the archived effective-content report;
`reports/content/dictionary_audit.*` concerns the broader authoring archive.
Source-correct, familiar, culturally suitable and suitable for children are
separate judgments. Existing `editorApproved` labels are not fresh independent
human review evidence.

- [x] Recheck all 47,093 effective authoring records against pinned source bytes,
  including editorial overrides. Verify exact English lemma/sense membership,
  Punjabi headword/sense links, structural risks and projected gameplay coverage.
- [x] Replace the routine multi-script sequence with one preview/write/check
  command. Keep legacy import and review utilities for deliberate source changes,
  rather than running bulk baseline approval during normal maintenance.
- [x] Add reversible, fingerprint-bound curation holds and a grouped exception
  queue. Hide flagged definitions and remove their answer eligibility without
  deleting IDs, changing accepted guesses or claiming human review.
  The final recheck holds 17 records: 12 sensitive/stigmatizing definitions and
  five insufficient Punjabi source links. All 45,416 accepted guesses remain;
  14,689 answers and 16,739 visible definitions remain. Ordinary adjective and
  verb meanings are preserved after correcting an overbroad reference rule.
- [x] Quarantine both instances of the stigmatizing Quest clue
  'someone deranged and possibly dangerous', along with the other fresh risks.
- [x] Require the pinned-source recheck in CI, in addition to release freshness,
  distribution checks, unique-answer/clue floors and valid Jodo starter decks.
- [x] Retire this inherited authoring chain from runtime in dictionary v2. Its
  unresolved links and archive holds remain historical evidence. Restoring
  archive words is not a release prerequisite. The later October 9 approved
  snapshot also supersedes v2 source/sense policies as release inputs.

## Next itch.io playtest gates

- [x] Build a new candidate from validated current source with a new build number
  using `app/tool/build_itch_io.ps1`. Inspect the actual ZIP, relative paths,
  two release banks, attribution, fonts, all 35 offline letter clips and two
  click sounds. Record the build 23 ZIP/APK in `reports/release/package_audit.json`.
- [ ] Upload the validated new draft candidate to itch.io; the existing uploaded
  build 17 remains historical.
- [ ] Test all five games in the final uploaded iframe on Chromium, Firefox and
  Safari, plus Android/iOS mobile browsers. Cover first launch, focus, keyboard,
  touch/drag, fullscreen, clipboard/feedback, narrow layouts and Gurmukhi fonts.
- [ ] Verify real storage and offline reload/restart on that uploaded candidate:
  interrupted and completed rounds, Continue, reset, update/reopen, cache
  completion and restrictive browser/iframe storage behavior. Localhost and
  widget tests are separate evidence.
- [ ] Verify audible output/volume, victory sound, opt-outs and physical haptics.
  Obtain owner/fluent-speaker review of all 35 letter names and generated
  pronunciations before treating them as approved teaching content.
- [ ] Complete representative TalkBack/VoiceOver and keyboard-only play across
  games, walkthroughs and dialogs. Include 200% text, Gurmukhi focus/activation,
  Jodo selection, restore, completion accounting and repeat-play variety.
- [ ] Refresh screenshots from the final candidate; verify studio website
  availability, support details, page copy and disclosure accuracy. Public
  visibility requires the owner's approval after the release gates are met.

Historical hosted evidence: September build 17 launched all five library cards.
Fullscreen Learn Letters accepted Chhachha, entered the Stop audio UI state and
restored the answered letter at 20% after reload. This proves one hosted restore
flow; it does not establish speaker audibility, all-game or offline-restart QA.
The historical ZIP was 17,708,408 bytes, SHA-256
`8b429a2d207e2a13fb7e610257de14ec1958ec0d229d6b7c8a99df6d5f487a88`.

## Accessibility, consistency and performance follow-ups

- [ ] Add an enlarged Bujho keyboard layout for low vision; dense phone/Gurmukhi
  rows still need physical touch-target and text-enlargement evaluation.
- [ ] Improve Bujho board feedback navigation for efficient row-by-row reader
  review; the old browser tree grouped the board/input in a long disabled field.
- [x] Apply consistent compact game titles, shared feedback and themed progress
  and completion treatments. Continue evaluating physical-device accessibility
  through the separate reader/text/touch gates above.
- [ ] Measure cold startup, first download, parsing and dictionary filtering on
  a modest phone and mobile browser. Establish a fresh size/time baseline before
  further optimization. Compact release assets and cooperative decoding already
  replace the old 59.6 MB/17.9 MB authoring-asset baseline.
- [ ] Assess transactional round-result persistence. Ordered writes and retry
  notices exist, but separate statistics/session writes do not guarantee crash
  atomicity. Decide scope from failure evidence and preserve round-ID deduplication.
- [ ] Validate the proposed teen/adult learner audience with younger guided and
  older low-vision users. Address intended-audience content/accessibility gaps
  before claiming family or child suitability. Jodo variety is implemented in 1.11.

## Native and store releases, separate from the web playtest

- [ ] Verify current-source Android debug/emulator behavior and a genuinely
  release-signed build on physical hardware, preserving existing player data.
  Display names/icons and the fail-closed signing configuration exist; production
  credentials and signed-release evidence are still needed.
- [ ] Verify iPhone/iPad builds on macOS with current Xcode and physical devices,
  including offline saves, Gurmukhi rendering, VoiceOver and audio.
- [ ] Confirm Play account type, verification and current testing eligibility
  requirements. The September feasibility assessment is historical policy evidence.
- [ ] Configure production upload signing and Play App Signing; validate an AAB,
  identifiers, splash/platform metadata and 16 KB native compatibility.
- [ ] Finish store listing screenshots/artwork/support details; add public and
  in-app privacy policy and accurate Data safety, audience, ads, content-rating
  and applicable Families declarations.
- [ ] Recruit a real closed-beta cohort and assess repeat use before community
  launch. Optional advice from Albatross Singh remains a possible future action;
  no outreach has been sent or is authorized by this checklist.

## Deferred product work

These are planned options, not blockers for the itch.io draft.

- [ ] Prototype Journey Through Punjab with one sourced location, three short
  activities, accessible stop navigation and offline progress; evaluate before
  expanding into a campaign.
- [ ] Review Word Garden, Find the Connection, Build the Sentence and an
  accuracy-first Typing Challenge when selecting another game. Typing should be
  untimed by default, with optional timed challenges.
- [ ] Document a reusable game-module contract around the already shared content,
  themes, settings, saves and statistics; do not duplicate these foundations.
- [ ] Revisit a Cloudflare Pages preview and the split between playable app and
  future marketing site if that hosting direction is selected. itch.io is the
  current agreed playtest target; a Pages workflow is not required for it.

## Completed milestones and evidence

- [x] V2 scaffold/toolchain, offline storage boundaries, content import/curation,
  dictionary review interface and source attribution. V1 remains excluded from Git.
- [x] Bujho, Khoj and Quest engines/UI, Unicode graphemes, normalized Gurmukhi,
  repeat-safe rotation, keyboard play, dictionary, saved rounds and statistics.
- [x] Jodo's two English and two Punjabi four-pair decks, restored progress,
  matching semantics and source-backed Romanized labels.
- [x] Shared visual redesign, three themes, phone library/actions, help walkthroughs,
  app settings/reset, branded display names/icons, reduced-motion victory effects.
- [x] Akhar Pachhaan's 35-letter practice game, saved rounds/statistics and bundled
  robotic pronunciation previews. Linguistic/audibility approval remains open.
- [x] External audit fixes: async disposal guards, normalized restore, truthful
  storage failures/retries/reset, exact grid generation, drag/scroll handling,
  dictionary grapheme queries/debounce, cooperative loading, update notices,
  offline worker packaging and dependency-audit CI gates.
- [x] October GitHub fixes: recover from rejected obsolete/empty save cleanup,
  reject impossible Quest snapshots and preserve Space activation on focused
  Gurmukhi keys. Source changes committed and PR #1 merged; resolved issues closed.
- [x] Earlier local packaged-browser/visual checks and Pixel in-place installs
  through build 16. These do not replace current-candidate validation above.

Historical pre-v2 vocabulary validation: 311 full-suite tests passed, including
visual baselines; 20 targeted checks passed after correcting the reference rule.
All 152 Dart files are format-clean, analysis is clean, and the release web build
passes. Built vocabulary bytes matched the three historical release shards. The
pipeline's repeated write/check passes with zero stale shards, all pools/decks
pass, and the authoring audit still reports 7,931 flags across 47,093 records.
No new ZIP upload, physical-device or hosted/browser/audio verification occurred.
