# Sikhi Word Games V2 TODO

This is the current checklist, reconciled on October 8, 2026. Open boxes describe
remaining work. Completed milestones are evidence, not sign-off for a newer
package. Keep one task per outcome; update counts from fresh reports instead of
copying old audits. Do not approve vocabulary merely to fill a pool quota.

## October 8 play consistency update: 1.11.0+21

- [x] Three supported game languages, shared language header and menu-only language
  changes. Preserve historical statistics and valid older Quest budgets.
- [x] Quest lantern countdown, 3/4/5 missed letters, 0/1/2 hints and shared toasts.
- [x] Jodo draws repeat-aware, unambiguous sets from eligible words across lengths.
- [x] Always-visible target audio and persisted reverse listening practice.
- [x] Distinct Modern/Sikhi/Dark surfaces and responsive bilingual tile wordmark.
- [x] Dedicated Settings/Dictionary/Progress/Achievements and per-game progress pages.
- [x] Fifty achievement badges, ten per game, derived from durable statistics;
  new facts are atomic with game completion, deduplicated and resettable.
- [x] Final validation: 342 Flutter tests pass against reviewed visual baselines,
  166 Dart files formatted, clean analysis and successful release web/debug APK
  builds. Browser at `http://127.0.0.1:8920/` verifies the new logo, dedicated
  Settings/Achievements, historical badge credit and exactly three language
  choices. A fresh five-letter Quest shows four misses, one hint and the lantern;
  no browser console errors were observed during these checks.
- [x] Install and launch build 21 on K70 PRO with `adb install -r`, preserving
  data. Installation Success, launch Status ok, version 1.11.0/code 21 and
  running PID verified. Visible device gameplay still needs a hands-on check.
- APK: `app/dist/sikhi-word-games-android-1.11.0+21-debug.apk`.
  SHA-256: `88ddb92ff28b7ad3b613e0be86943b49a265ead84841ceafbfe7c4e862885c27`.
- Sound replacement/review stays a separate task; this update reuses existing
  letter recordings and does not represent pronunciation approval.

## Current state

- GitHub issue-review baseline: PR #1 merged into `main` at
  `8056a0525ba9ffe0224bee6cffb1989002c87d93`.
  GitHub issues #3, #4, #5, #6 and #8 are closed as completed; no PR remains open
  from that review. The focused save/restore and keyboard fixes are in
  `eab3f11bc1adc83a0959d962bf1b94bff6104d5f`.
- Current Android testing version: 1.11.0+21, Paper & Play. The September 18 ZIP and uploaded
  itch.io draft remain 1.9.0+17 and
  predate the subsequent audit fixes and October vocabulary recheck. They are
  historical artifacts, not packages of current source. Increment both version
  sources and the build number when producing the next distributed package.
- The itch.io project is still a draft: project 5023423,
  <https://khalsagamestudio.itch.io/sikhi-word-games>. No public release is recorded.
- Pixel 6 last verified installation: 1.9.0+16 on September 13, preserving data.
  The old request to install build 8 is superseded by verified installs of newer
  builds; current-source device validation remains open below.
- Latest completed baseline before this content change: 304 Flutter tests,
  clean analysis/formatting, successful release web build. PR CI validate and
  goldens passed (run 37712159163). Current-change validation is recorded below.
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

## Vocabulary recheck and improvement plan

Use `docs/definition_sources.md` for the single-command workflow and its limits.
`reports/content/vocabulary_recheck.json` is the current effective-content report;
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
- [ ] Resolve the five Punjabi editorial meanings without sufficient source links:
  AHSAS, AMRIT, ARPNA, ISPAT and UTPAD. Preserve their holds until exact supporting
  evidence or an explicit checked editorial decision is recorded. A missing link
  does not prove the meaning is wrong. Preview Punjabi changes with
  `review_punjabi_content.dart`, then apply checked decisions with `--write`.
- [ ] Review the deterministic semantic sample from the fresh report: 20 unique
  senses per source stratum, including editorial paraphrases. Check meaning,
  everyday usage, cultural context and Punjabi spelling/pronunciation; record
  actual reviewer/method. If a failure occurs, add a regression/rule and recheck
  the affected class before widening the sample. Do not treat a passing sample
  as proof that every word is suitable for children.
- [ ] Establish familiar-word difficulty and intended-audience criteria. Rank
  ambiguous, archaic, technical and regional senses automatically; improve a
  bounded common-word pool using explicit source-backed sense decisions. Confirm
  coverage in every language/length and preserve exclusions. Prefer clear short
  clues over expanding random-answer counts.
- [ ] Improve held definitions only when worthwhile. Review the current exception
  queue with active-answer cases first, choose a supported ordinary sense or
  write a sourced original meaning, and rerun the pipeline. Leaving uncertain
  records held is an acceptable outcome; restoring every archive word is not a
  release prerequisite.
- [ ] Triage broader authoring flags when importing or expanding content. Empty
  held definitions, legacy references and spelling aliases are not automatically
  release defects. Never report a successful archive-audit exit as editorial
  approval or copy superseded flag counts into the active checklist.

## Next itch.io playtest gates

- [ ] Build a new candidate from validated current source with a new build number
  using `app/tool/build_itch_io.ps1`. Inspect the actual ZIP, relative paths,
  release-only assets, attribution, fonts and all 35 offline letter clips;
  update `reports/release/package_audit.json` and upload the new draft candidate.
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
- [ ] Finish consistent toolbar, progress and completion treatments through
  shared theme/components across all three themes. Existing backdrops and
  button/selection treatments are implemented; this is the remaining polish.
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

Current vocabulary change validation: 311 full-suite tests passed, including
visual baselines; 20 targeted checks passed after correcting the reference rule.
All 152 Dart files are format-clean, analysis is clean, and the release web build
passes. Built vocabulary bytes match all three current release shards. The
pipeline's repeated write/check passes with zero stale shards, all pools/decks
pass, and the authoring audit still reports 7,931 flags across 47,093 records.
No new ZIP upload, physical-device or hosted/browser/audio verification occurred.
