# Sikhi Word Games V2 TODO

This is the current checklist, reconciled on October 10, 2026. Open boxes describe
remaining work. Completed milestones are evidence, not sign-off for a newer
package. Keep one task per outcome; update counts from fresh reports instead of
copying old audits. The current dictionaries are an explicitly owner-approved
source snapshot; integrity checks do not reopen editorial approval.

## October 10 itch.io publication: public playtest 1.18.4+36

- [x] Publish the updated itch.io page after the owner's explicit request.
  Verified PUBLISHED on the reloaded page; build 36, six-game copy and seven
  screenshot links remain present. Free access and In development are preserved.
  Earlier draft-refresh checks below describe the pre-publication validation.

- [x] Upload the validated current ZIP to existing itch.io project 5023423 and
  make it browser-playable. Retain build 17 hidden/non-playable for rollback.
- [x] Replace the cover and capture/upload seven real screenshots: library and
  all six games, including Gurmukhi and Simple Romanized Punjabi.
- [x] Update the tagline, game descriptions, build number, Dictionary count,
  credits, controls, badges, developer email and truthful audio/offline limits.
- [x] Enable the visible screenshot sidebar and cream/teal page colors.
- [x] Smoke-test all six games and Dictionary in the actual Chromium iframe,
  including fullscreen, Bujho keyboard input/reload restoration, Quest default
  alphabet/correct input, Jodo matching, Scramble placement/recall, old letter
  practice restoration/audio controls and Gurmukhi fonts/query results.

Draft visibility and Mobile Friendly-off are preserved. The current archive is
21,697,904 bytes, SHA-256
`805a672b972b5f3bc6ffd29223d1d80ba29b2ec0c0555e9adf28414f8ca0f58b`.
It contains 106 files, including the three unchanged approved masters and
attribution/licenses; 96 files are in the offline-cache manifest. The same
application source/package had already passed 490 tests including 52 goldens,
formatting, analysis and the release packager. This refresh changes distribution
artwork/page copy and release documentation, not application source.
`reports/release/browser_qa.json` separates current hosted evidence from older
local/offline evidence. Actual host offline restart, physical mobile browsers,
Firefox/Safari, screen readers, audible output and fluent pronunciation approval
remain open. itch.io's desktop orientation-lock request emitted NotSupportedError;
fullscreen and gameplay remained usable. No fresh hosted offline claim is made.

## October 10 developer-email feedback: candidate 1.18.4+36

- [x] Replace the player-facing GitHub feedback URL with
  khalsagamestudio.apps@gmail.com and an Email feedback action.
- [x] Include the current app version and game/language/device prompts in the
  draft; retain a copy-address/manual fallback without sending automatically.

All five targeted feedback tests pass: successful launch, unavailable/throwing
mail handlers, plain-address copying and blocked clipboard fallback. Formatting
and analysis pass; all 490 tests pass, including the 52 Windows golden tests.
The release web package and normal arm64 profile/AOT APK build successfully.
The web cache includes 96 files; integrity checks preserve all 20,601 records
and their source attribution/licenses. aapt confirms version 1.18.4/code 36 and
the SikhiGames launcher label. This candidate is not installed on devices;
the tablet has 1.18.3+35 and Pixel 6 has 1.18.2+34.
Activated 1.18.4+36 in the local web preview without clearing storage. The
feedback dialog visibly shows the developer email, version, Copy email address
and Email feedback actions, with no GitHub-account copy or console errors.
No actual feedback email was sent during verification.

## October 10 approved bilingual branding: candidate 1.18.3+35

- [x] Use English S + Gurmukhi ਗ (Sikhi + Games) in the shared wordmark and
  regenerate all Android, iOS and web launcher icons from font-derived paths.
- [x] Use SikhiGames for Android/iOS launcher labels, web name/short_name and
  Apple web shortcut titles; retain the full in-app title and application IDs.
- [x] Refresh the release cover to the approved cream/teal/tile identity and
  correctly list all six games. Keep the exporter as the source of future assets.
- [x] Review the updated phone/tablet library goldens across all three themes.

Formatting and analysis pass; all 486 tests pass, including the 52 golden tests.
All 19 iOS catalog entries and five Android density exports have the expected
dimensions; iOS PNGs are opaque. The complete maskable mark fits inside the
central safe circle (measured radius 196.0px versus 204.8px at 512px).
The 1.18.3+35 release web package builds with 96 offline-cache files and unchanged
integrity/attribution checks for all 20,601 vocabulary records. The normal arm64
profile/AOT APK builds successfully; aapt confirms version 1.18.3/code 35,
launcher label SikhiGames and the existing application ID. iOS assets/labels
are checked at source/export level; native iOS compilation is unavailable here.
The K70 PRO tablet was updated on October 10 from 1.18.2+34 to the normal arm64
profile/AOT 1.18.3+35 APK built from a54bbb3. Used `adb install -r` to preserve
app data. Android confirms version 1.18.3/code 35 and a successful cold
MainActivity launch; running PID 4664 was verified. The APK launcher label is
SikhiGames. Hands-on launcher/icon checks remain a player check. Pixel 6 still
has the previously installed 1.18.2+34 candidate.
Activated the updated local web preview on port 8921 without clearing storage;
the new Gurmukhi ਗ wordmark renders, existing Continue actions remain, Settings
opens and returns, and the browser reports no console errors.
Real-gameplay promotional screenshots still need the refresh tracked in the
release checklist below; the updated golden images are test evidence.

## October 10 direct-grid Bujho input: candidate 1.18.2+34

- [x] Put typed letters directly in the active grid row and remove the separate
  guess display, retaining Enter submission and editable rejected guesses.
- [x] Enlarge Bujho keyboard labels with keys at least 44px high; retain
  Gurmukhi composition, whole-unit backspace and scrollable long keyboards.
- [x] Announce the current row/value for assistive technology and restore
  hardware focus when that row is tapped. Keep draft letters unevaluated.
- [x] Use the app's configured fonts for shared Gurmukhi keyboard labels.
- [x] Update help, documentation and the reviewed phone/tablet visual baselines.

Formatting and analysis pass. All 486 tests pass, including 52 Windows golden
tests; reviewed the changed/new Bujho captures in every theme and the separate
English/Gurmukhi phone layouts. Input cases cover draft typing, length limits,
rejection without advancing, deletion, next-row submission, completion and
accessible current values. Existing native conjunct/attached-mark tests now
check the visible grid. English has no scroll at 320x568, 390x844 and 1024x768;
Punjabi keyboards remain reachable at 200% text. Submitted-round persistence,
word rules and approved dictionaries are unchanged.

The final 1.18.2+34 web package builds successfully with 96 offline-cache files
and verified integrity/attributions for the unchanged 20,601 records. Activated
the preview update on port 8921 without clearing storage. Real-browser checks
verify on-screen/hardware typing, hardware deletion, current-row announcements,
Gurmukhi sign attachment into one tile and whole-unit deletion, readable larger
key labels and no console errors.

Pixel 6 was updated on October 10 from 1.18.0+32 to the normal arm64 profile/AOT
APK built from commit a557fad, using `adb install -r` to preserve existing app
data. Android confirms 1.18.2/code 34; MainActivity was brought to the foreground
successfully and running PID 22762 was verified. Hands-on direct-grid testing
remains a player check.

The K70 PRO tablet was then updated from 1.18.1+33 to the same normal arm64
profile/AOT APK using `adb install -r`, preserving app data. Android confirms
1.18.2/code 34; a cold MainActivity launch succeeded and running PID 27234 was
verified. Both devices now have the direct-grid build; hands-on tablet checks
remain separate from these installation and launch confirmations.

## October 10 tablet launch delay: candidate 1.18.1+33

- [x] Show an opaque destination/loading frame before vocabulary preparation;
  remove the game-route fade that initially concealed that acknowledgement.
- [x] Skip unnecessary normalization, reuse eligibility decisions and Bujho
  solution pools, and retain the pool when its spelling setting is unchanged.
- [x] Add warm-content loading regressions and a real-dictionary Android launch
  benchmark using in-memory saves, without reading or resetting player data.
- [x] Validate and install the normal optimized app on the K70 PRO tablet.

Formatting and analysis pass; all 480 tests pass, including the unchanged 50
Windows goldens. The release web package for 1.18.1+33 builds successfully with
96 offline-cache files. Vocabulary/attribution integrity passes for all 20,601
unchanged records. No vocabulary or answer eligibility rules were changed.

The K70 PRO debug benchmark reduced English Bujho pool preparation from 3,565
to 171 ms and Gurmukhi from 12,542 to 378 ms for the same multi-length workload.
The final profile integration run passed all six game launches after the tablet
was unlocked. Tap plus first pump / settled timings, in milliseconds, were
Bujho 112/611, Search 471/909, Quest 82/451, Bridges 95/842, Learn Letters
103/333 and Scramble 98/535. These include test-harness/rendering work and are
not guaranteed touch-to-display latency; hands-on feedback remains necessary.

The temporary benchmark was replaced with the normal `lib/main.dart` arm64
profile APK using `adb install -r`, preserving existing app data. Android
reports version 1.18.1/code 33; MainActivity launch succeeded and running PID
24758 was verified. Profile/AOT is used because local release-signing keys are
not configured. The Pixel remains on 1.18.0+32. The rebuilt web package has not
had a fresh browser playthrough; the earlier 1.18.0 checks below are historical.

## October 10 mobile quality of life: candidate 1.18.0+32

- [x] Equal phone/tablet/web library card heights, including Continue and wrapped text.
- [x] Learn Letters Game type on Play, listening default and larger choice glyphs.
- [x] Selected-language loading headers instead of an English placeholder.
- [x] Scramble recall and dragging both ways, swaps and preserved legacy locks.
- [x] Shared menu labels, icons and order for all six games.
- [x] Wide Quest lantern beside the alphabet, retained when toggling input modes.
- [x] Named, colorful achievement banners after successful persistence, with queue.
- [x] Short route fades and dictionary preloading from Play.
- [x] Complete full checks, visual review and release web preview validation.

Formatting and analysis pass. The full suite passes 474 tests, including all
50 Windows goldens; reviewed the changed/new images across all three themes,
phone/tablet layouts and large text. The release web package passes vocabulary
and attribution integrity for the unchanged 20,601 records and contains 96
offline-cache files. The cache-worker behavior check also passes.
Verified version 1.18.0+32 in the browser at 1024x768 and 390x844: Learn Letters
mode selection/listening layout, shared menu, Quest lantern with both input
banks, Scramble placement/recall and mouse dragging both ways at the normal web
size, and Settings navigation. Browser console reported no errors. The updated
preview is open on port 8921 after allowing its offline update to activate;
port 8920 retains the previous preview's separate saved data. Real-device
navigation latency and native touch dragging still need device testing.

Pixel 6 was updated on October 10 with the arm64 debug testing APK from commit
1803f94 using `adb install -r`, preserving existing app data. Android reports
version 1.18.0/code 32; launching MainActivity succeeded and running PID 15571
was verified. This supersedes its previous 1.16.2+31 installation. Hands-on
touch dragging and navigation-speed checks remain pending.

The K70 PRO tablet was also updated on October 10 using `adb install -r`,
preserving existing app data. Android reports version 1.18.0/code 32;
MainActivity launch succeeded and running PID 21298 was verified. This
supersedes its previous 1.16.1+30 installation. Tablet layout and touch
interaction playtesting remain hands-on checks.

## October 9 review fixes and follow-ups: released 1.17.0+31

- [x] Follow-up 3.1: ignore lone Gurmukhi vowel signs in Quest hardware input and
  the engine without consuming misses; cover unchanged counts and marked tiles.
- [x] Follow-up 3.2: require supplied WordNet tag counts of at least 3 for every
  English game answer; retain all Dictionary entries and accepted guesses.
- [x] Follow-up 3.3: retain every Gurmukhi Romanization and exclude whole-word
  clue references, including plain/accented equivalents such as granthī/granthi.
- [x] Follow-up 3.4: pluralize Progress rounds, puzzles, words, sets, pairs and
  first-try answers through shared count text; verify zero, one and two.
- [x] Follow-up 3.5: replace six selection/restore candidate conditions with
  `AnswerEligibility.isCandidate`, preserving game-specific requirements.
- [x] Follow-up 3.6: set both version sources and README to 1.17.0+31 as the
  final follow-up commit; retain build number 31 as requested.

Follow-ups 3.1 through 3.5 each passed formatting, analysis and the full suite
before their separate commits: 426, 427, 428, 431 and 432 tests respectively,
including all 42 Windows goldens each time. Reviewed the changed English Jodo
phone capture. Source/content and release checks verify all 20,601 unchanged
records, original attribution/licenses and zero source/runtime differences.
The Romanization rule finds 13 exact leaks, or 87 including plain equivalents
needed for granthī/granthi; two overlap existing exclusions, so 85 more native
answers are excluded. English has 766/928/1,122 answers at 4/5/6 tiles. Native
4/5/6 pools have 772/218/33; broader pools and small-pool notes are in the schema.
Follow-up 3.6 validation: all 432 tests including 42 goldens pass; analysis is
clean and all 163 Dart files are formatted. No new physical-device or hosted-web
validation is claimed for this candidate.

- [x] Follow-up 1: make Shabad Banao anagram-first, with the meaning revealed
  only through Hint or completion; persist clue visibility and preserve old saves.
- [x] Follow-up 2: start Quest with the full alphabet, retain its miss limit and
  lantern, and keep the small bank available as an easier option.

Follow-up 1 validation: all 421 tests, including 41 goldens, pass; analysis and
formatting are clean. Reviewed hidden-clue captures in all themes, native/large
Gurmukhi and the revealed meaning. Tests cover silent initial semantics, hint
immutability/persistence, unhinted completion and legacy locked-tile saves.
Follow-up 2 validation: all 426 tests, including 42 goldens, pass; analysis and
formatting are clean. Reviewed the full-alphabet phone and three-theme completion
captures. All three modes retain their miss budgets across bank toggles and save
recreation. The 1.16.2+31 web ZIP was rebuilt with both updates; its packaged
vocabulary audit passes with 20,601 unchanged records and original notices.

- [x] 1. Apply one mechanical answer rule across all five word games, retaining
  the complete Dictionary and accepted guesses; document actual pool coverage.
- [x] 2. Fail release audits on boundary-matched crude/vandalized definitions.
- [x] 3. Correct statistics/help/plurals, Scramble settings, Quest hardware input
  and the Simple Punjabi default description.
- [x] 4. Share hardware-input validation, use theme tokens, remove confirmed
  dead code and add corrupt/unsupported save/native-decoder regressions.
- [x] 5. Reconcile architecture, current Jodo pools, guides and retired-tool docs.
- [x] Bump both version sources, finish validation and prepare the branch for
  an unmerged PR. Owner review is required before merging.

Dictionary/source counts remain 13,182 English, 2,991 Romanized and 4,428
Gurmukhi. Answer coverage is in `docs/content_schema.md`; original answers total
2,816 / 2,975 / 4,337, Simple Romanized 2,791, and Gurmukhi Scramble 4,323.
Gurmukhi lengths 7 and 8 have only 7 and 1 answers in the mixed-length games;
the supported six-tile Bujho/Quest pool retains 33. No approved files were edited.
The larger descriptor map, board split and RoundSetup refactors are deferred
to keep these fixes focused.

Item 1 validation: 401 Flutter tests, including all 40 goldens, passed;
analysis is clean and 161 Dart files are formatted. Reviewed the changed Jodo
English phone baseline using eligible, unambiguous preview pairs. Content audit
and release `--check`/audit pass with 20,601 records and zero byte differences.
Item 2 validation: 405 tests including all goldens passed; analysis/formatting,
content audit and release checks pass. The regression guard checks definitions
in all three datasets, including correctly hashed vandalized fixtures, without
editing the approved snapshot.
Item 3 validation: 409 tests including all 40 goldens passed; analysis is clean
and 162 Dart files are formatted. Reviewed the Settings phone baseline. Tests
cover one statistics detail, singular word counts, same-language/cancel/apply
round preservation, forbidden Gurmukhi hardware input and vowel-sign saves.
Item 4 validation: 417 tests including all 40 goldens passed; analysis is clean
and 162 Dart files are formatted. Reviewed the three themed badge captures.
Corrupt Jodo rotation, unsupported Scramble schemas and native approved-record
decoding fail safely; settings storage-failure coverage remains passing.
Item 5 validation: 417 tests including all 40 unchanged goldens passed;
analysis is clean and 162 Dart files are formatted. Updated Scramble help fits
the existing phone and enlarged-text guide tests. Current docs describe the
six-game boundaries, mechanical exclusions and retired Jodo/tool behavior.
Initial 1.16.2+31 review validation: all 417 tests, including 40 goldens, pass; analysis is clean
and 162 Dart files are formatted. Source/release checks and the packaged web
audit verify 20,601 unchanged records and original notices/licenses. The release
ZIP is `app/dist/sikhi-word-games-web-1.16.2+31.zip`. No physical-device install,
actual-host iframe/offline reload or publication was claimed at that validation
point. The later Pixel update installed and launched commit 947b047 (1.16.2+31), before these
follow-ups; physical testing of the current 1.17.0+31 candidate remains separate.

## October 9 Gurmukhi scramble labels: candidate 1.16.1+30

- [x] Show shared Romanized pronunciation labels beneath Gurmukhi units in
  shuffled, placed, hinted and completed tiles, including spoken labels.
- [x] Reserve space for enlarged labels without splitting native written groups.
- [x] Validate phone/theme/large-text captures, rebuild and refresh the preview,
  and update connected testing devices.
- [x] Install build 30 on Pixel 6 with saved app data retained.

Build 30 evidence: 394 tests, including 40 visual baselines, passed; analysis is
clean and 159 Dart files are formatted. Reviewed actual-font normal/200% Gurmukhi
captures and checked labels through placement, hint locks and completion in all
themes. The packaged browser at 390x780 resumed the existing two-tile ਬੁੱਧੀ round
with Bu/Dhee captions and spoken labels, without changing the round or progress.
The 1.16.1+30 web ZIP and debug APK are built, and source integrity still verifies
20,601 unchanged approved records. K70 PRO installed with data retained; version
1.16.1/code 30 and launch PID 5425 were verified. Pixel 6 subsequently reconnected
and was updated with `adb install -r`; version 1.16.1/code 30 and launch PID 21859
were verified on October 9, retaining app data.

The install-record CI exposed a Khoj celebration test that dragged beneath a
still-visible success snack bar. The test now verifies each intermediate find
and expires feedback before the next drag; app code and the installed APK are
unchanged. The isolated reproduction and all six game celebration tests pass.

## October 9 Shabad Banao: candidate 1.16.0+29

- [x] Add Word Scramble / Shabad Banao as the sixth equal library card with
  shared Paper & Play tiles, buttons, titles and all three themes.
- [x] Support three approved language pools, mixed lengths, Simple/original
  Punjabi, intact Gurmukhi units, one optional hint and quiet unlimited retries.
- [x] Save unfinished words, rotate before repeating, record once-only completed
  statistics, add ten badges and include the new owned key in app-wide reset.
- [x] Complete full analysis/tests, reviewed visual baselines and release builds.
- [x] Verify the actual packaged web preview and install on the connected tablet.
- [x] Supersede the pending Pixel build 29 install with build 30 above.

Build 29 evidence: 391 Flutter tests, including 40 visual baselines, passed.
Analysis is clean and 159 Dart files are formatted. Reviewed phone captures
cover all three themes, intact Gurmukhi groups and 200% text; the actual browser
shows six equal cards at 800x1100. At 390x780, reload/Continue restored the exact
partial SAFARI word, an incorrect check produced inline feedback, and English
and Gurmukhi completions counted once in Progress (2 words, 1 without a hint).
Gurmukhi hint tiles retain vowel marks; Simple Punjabi uses plain Roman tiles.
These checks used an isolated localhost origin to retain existing preview data.
Both 1.16.0+29 packages include the new artwork and exact seven runtime content
files, with no authoring banks; all 20,601 source records and licenses match.
K70 PRO was updated with `adb install -r`; version 1.16.0/code 29 and launch PID
4108 were verified, retaining app data. Native hands-on/audio and hosted
offline/iframe checks remain separate open work. Pixel was not connected.

## October 9 phone playtest fixes: candidate 1.15.1+28

- [x] Keep unsuccessful Khoj selections silent; clear the selection and retain
  success/completion feedback and accessible selection instructions.
- [x] Remove the Dictionary's redundant introductory banner and use the compact
  Latin layout for Simple Romanized Punjabi.
- [x] Make Simple Romanized Punjabi Bujho fit the same phone screen as English;
  retain extended layouts for Gurmukhi, original accented keyboards and large text.
- [x] Complete phone regression/full checks, rebuild the web preview and Android
  test APK, and update the connected tablet with app data retained.
- [x] Supersede the pending Pixel build 28 install with build 29 above; only the
  tablet was connected during this validation pass.

Build 28 evidence: the targeted checks failed before the fixes for all three
reports, then passed afterward. All 364 Flutter tests, including 35 unchanged
visual baselines, passed; analysis is clean and 148 Dart files are formatted.
The packaged release browser at 390x780 shows the full Simple Punjabi Bujho
board and Enter key without scrolling, Dictionary results without the banner,
and quiet repeated missed Khoj selections. Browser checks used an isolated
localhost origin for new games; the existing preview's saved rounds were kept.
Web/package content integrity checks pass. The 1.15.1+28 web ZIP and debug APK
are built. K70 PRO was updated with `adb install -r`; version 1.15.1/code 28,
successful launch and PID 31646 were verified. Pixel remains on build 27 until
reconnected. Native hands-on checks remain separate from browser/widget evidence.

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
- [x] Historical dictionary-v2 imports, policies, holds and attribution were
  reproducible offline. That pipeline is retired; current releases use the
  owner-approved snapshot with `dart run tool/build_release_content.dart --check`
  and release audits. Historical machine decisions were not human approval.
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

- Current application/source candidate and public itch.io playtest: **1.18.4+36**.
  PR #23 (`codex/mobile-qol-updates`) remains open and unmerged for owner review.
- itch.io project 5023423 is Public, published October 10 at the owner's request:
  <https://khalsagamestudio.itch.io/sikhi-word-games>. Current build 36, cover,
  seven screenshots and six-game page copy replaced the September build 17
  presentation. The older ZIP is retained hidden for rollback.
- K70 PRO tablet last verified installation: **1.18.3+35**; Pixel 6:
  **1.18.2+34**. Build 36 has not been installed on either device.
- Current automated application validation: 490 tests including 52 Windows
  goldens, clean format/analyze, release web packaging and arm64 profile/AOT APK.
- All six games, shared themes/content/settings/statistics, offline save handling,
  responsive shells, achievements and Unicode-safe matching exist. Current
  vocabulary is the October 9 owner-approved 20,601-entry release snapshot.
- Earlier issue reviews and milestones below remain historical evidence. They
  do not establish newer physical/browser/accessibility or pronunciation QA.

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

- [x] Package validated 1.18.4+36 with the approved three masters, relative root
  index, local renderer, attribution/licenses, fonts and offline sounds.
  Inspect actual archive bytes and record `reports/release/package_audit.json`.
- [x] Upload build 36 to the existing draft and preserve build 17 for rollback.
- [x] Refresh cover, seven gameplay screenshots, page copy, support email,
  vocabulary/font credits and AI disclosure. Keep visibility Draft.
- [x] Smoke-test all six games and Dictionary in the actual uploaded Chromium
  iframe, including fullscreen and one real saved-round reload/restore flow.
- [ ] Complete the full uploaded-iframe matrix on Firefox/Safari and physical
  Android/iOS browsers: touch/drag, keyboard/focus, narrow layouts and clipboard.
- [ ] Verify hosted storage and offline reload/restart more broadly: completed
  rounds, reset, update/reopen, cache completion and restrictive iframe storage.
  One online Bujho restore is verified; localhost/widget checks are separate.
- [ ] Verify speaker output/volume, opt-outs, victory sound and physical haptics.
  Obtain fluent-speaker/owner approval of generated letter-name pronunciations
  before treating them as approved teaching audio.
- [ ] Complete representative TalkBack/VoiceOver and keyboard-only play, 200%
  text, Gurmukhi focus/activation, restore and completion accounting.
- [x] Publish the existing page after the owner's explicit publication request.
  Verify the reloaded page shows PUBLISHED and retains current release assets.
- [ ] Verify studio website availability before broader promotion.

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
