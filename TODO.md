# Sikhi Word Games V2 TODO

This is the current checklist, reconciled on October 7, 2026. Open boxes describe
remaining work. Completed milestones are evidence, not sign-off for a newer
package. Keep one task per outcome; update counts from fresh reports instead of
copying old audits. Do not approve vocabulary merely to fill a pool quota.

## Current state

- GitHub issue-review baseline: PR #1 merged into `main` at
  `8056a0525ba9ffe0224bee6cffb1989002c87d93`.
  GitHub issues #3, #4, #5, #6 and #8 are closed as completed; no PR remains open
  from that review. The focused save/restore and keyboard fixes are in
  `eab3f11bc1adc83a0959d962bf1b94bff6104d5f`.
- App version remains 1.9.0+17. The September 18 ZIP and uploaded itch.io draft
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
  before claiming family or child suitability; expand Jodo's fixed-set variety.

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
