# Sikhi Word Games V2: Testing Strategy

## Coverage and limits

October 10 quality-of-life regressions cover equal phone/tablet card heights with a
Continue save at 1x/1.5x/2x text, both Learn Letters launch types and continuation,
selected-language loading frames in all five vocabulary games, shared menu order
and icons in all six games, visible wide Quest alphabet/lantern, badge queue and
no-replay behavior, and Scramble dragging/swapping/recall of whole Gurmukhi units.
Domain tests retain legacy locked hints and tile permutation/persistence invariants.
Navigation timing checks verify the configured transition; actual device latency
and pronunciation quality remain separate manual checks.

- Pure Dart unit tests cover game rules, content transformations, pool selection,
  source written units, scoring, and persistence serialization.
- Flutter widget tests cover launch preferences, navigation, input, completed
  games, semantics, and selected responsive sizes.
- Forty-two Windows golden image tests cover Modern, Sikhi, and Dark. They run
  separately from Linux unit/widget checks to keep rendering baselines consistent.
- The integration fixture covers preferences and interrupted Bujho restoration
  with an in-memory store. It does not establish browser restart persistence.
- Release browser checks must cover all six games and Dictionary with real
  assets, local storage, mouse/touch, physical keyboard, and Gurmukhi rendering.

## Required cases

Hardware input validation is shared under `core/language/`, separate from game
widgets. Bujho/Dictionary preserve complete composable input; Quest accepts one
Gurmukhi letter while ignoring lone vowel signs without consuming a miss, and
rejecting digits, sacred marks and batches. Whole marked on-screen units remain
valid guesses.
Direct native-decoder tests cover all three scripts, unchanged definitions,
counterpart-only metadata, exact written units and invalid conjunct/count data.
Jodo rotation tests round-trip `usedWords`/`previousWords` by language, retain
history after clearing a round, fail closed on malformed rows and accept older
saves without the fields. Unsupported Scramble schemas restore neither a round
nor statistics/history; a subsequent valid save recovers cleanly.
Quest regressions cover full-alphabet startup in all three modes, unchanged
miss limits when toggling banks, continued lantern feedback and persisted easier
choices after guesses/recreation. Older saves default to full; malformed keyboard
flags fail closed. Phone full-alphabet and completion captures are reviewed.

Check exact/present/absent feedback and repeated letters; four-, five-, and
six-tile games in all three language modes; valid and unavailable mode words;
random selection/exhaustion; winning and losing; new/continue/back navigation;
corrupt and unsupported saves; restart and settings isolation. For Khoj include
drag direction, duplicate target detection, hints, and completion. In sequential
drag tests, assert each target was found and let success feedback expire before
the next gesture so an overlapping snack bar cannot intercept its pointer.
For Word Quest
include repeated guesses, adaptive tries/hints, simple/full keyboards, preserved
definitions and readable clues. A vocabulary coverage count is not a human definition-quality review.
For approved-release changes, test the three separate mode memberships,
source manifest hashes, exact master/notice/license bytes, unique spellings,
one selected definition per word, source unit reconstruction and tile counts.
Cover Gurmukhi marks and virama-linked conjuncts where `.characters` differs,
Roman letters with scholarly diacritics, and absence of counterpart-only words
from another mode. Verify imported rows remain present without old frequency,
clue-quality or everyday-answer filters. Tampered/missing source or release
files must fail integrity checks; repeat an unchanged rebuild/check to establish
reproduction. These checks do not reopen the owner's content approval.
English answer-only usage tests cover missing counts, 0/1/2, the inclusive
threshold 3 and larger counts across the five game pools. Lookup and accepted
guesses retain excluded words; Punjabi does not require WordNet metadata.
Native decoding, entry copying and JSON round-trips preserve supplied counts.
Gurmukhi clue-leak tests cover alternate Romanizations, canonical/accent-folded
forms such as granthī/granthi, whole-word boundaries and unchanged lookup/guesses.
The aliases survive decoding and copies without adding counterpart-mode words.

Test narrow and short screens, large text, all themes, visible keyboard focus,
screen-reader labels, contrast, motion settings, and long definitions. Real
screen-reader and physical mobile-browser checks remain release gates where
widget tests cannot establish behavior.

## Quality gates

Run from `app/`:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test test_driver tool
flutter analyze --suppress-analytics
flutter test --suppress-analytics
dart run tool/build_release_content.dart --check
dart run tool/audit_release_content.dart
dart run tool\audit_content.dart
flutter build web --release --no-web-resources-cdn --suppress-analytics
```

Run the integration target on a configured supported device separately. It is
not included in `flutter test` by default. Keep formatter changes scoped when
preserving another contributor's work. The current content audit checks the
owner-approved runtime snapshot. Retired authoring audits are not current
release gates.

Release integrity checks reproduce three unchanged native masters from
`app/content/approved_release/`, using the source manifest and supplied notices.
No network, original source project or legacy review files are needed. Importer
coverage should include a validated `--import-from` package, locally reproducible
`--write`, exact `--check`, file tampering and mode-isolation regressions. Runtime
checks exercise each mode's actual written units, available sizes, input,
keyboards, restored targets and Jodo sets. Jodo tests distinguish avoiding
conflicting clues within one board from excluding approved dictionary words;
long selected definitions alone must not disqualify a word. The shared mechanical
answer rule is checked separately from Dictionary membership. Current source counts are in
`docs/content_schema.md`; historical quotas and quality filters are not approval
criteria. Existing older filter tests and source reports are historical evidence
rather than gates for this owner-approved import.

For itch.io, also verify the packaged relative base path, root `index.html`,
archive size/file limits, local renderer assets, nested-path loading, iframe
focus/fullscreen, clipboard failure behavior, persistence, offline behavior,
and cold startup with Gurmukhi. Test the uploaded draft before publishing.
Do not equate compilation or a passing unit suite with release approval.

The itch package generates a versioned app-cache manifest from the completed
web build. Automated tests cover its required files, exclusions, version input,
size metadata, and service-worker scope guards. Run the worker behavior harness
after changes to the offline cache:

```powershell
node tool/test_web_app_cache_service_worker.mjs
```

It exercises successful and failed installation, nested-path offline navigation,
request filtering, bounded writes, and cache cleanup isolation. Browser release checks must
still load the app once online, close it, block the network, and reload from the
same nested path. Service workers require a secure hosted context, except for
loopback development. An itch.io iframe may deny or clear browser storage, so
offline reload remains a tested host capability rather than a guarantee. The
`data-offline-ready="true"` attribute on the document root is set only after an
active worker is ready. Release updates intentionally wait for older controlled
pages to close before replacing their cache, which avoids mixing build assets.

## Audit evidence

Statistics/guidance coverage includes actual Khoj completion through semantic
endpoint actions, duplicate-completion prevention, Word Quest loss/retry/win
counting, corrupt statistics fallback and language/length isolation. App-route
tests verify independent first-launch guides and persisted dismissal. Guidance
and statistics dialogs are exercised at 200% text on narrow screens. Shared
tests invoke semantic keyboard actions and check persistent reader feedback;
goldens reflect the new 48px minimum shared buttons. Device TalkBack/VoiceOver,
dense phone keyboards and Gurmukhi voice pronunciation remain separate checks.

Build 1.3.2+7 adds exhaustive duplicate-letter accounting across 10,752 Latin
and Gurmukhi solution/guess combinations, and 200 seeded Khoj generation/save
round trips covering all eight placement directions. Verify every target spells
the actual grid cells and can be selected independently even when two target
words are reversals. Restore tests reject empty/multi-grapheme cells, missing
target letters, empty targets and duplicate targets. The full suite passes 180
tests. Extracted-package browser evidence covers diagonal keyboard selection
and real-storage restoration of the found Khoj target after reload; physical
Android and actual-host offline behavior remain separate open checks.

The September 2026 release audit and remaining gates are recorded in `TODO.md`.
Use that dated evidence when reporting readiness; do not silently carry forward
past successes after relevant code or content changes.

## Theme and input follow-up

The October 7 regression pass covers rejected stale-save cleanup in Bujho,
Khoj and Word Quest, including empty-save startup in Khoj/Quest. Word Quest
tests reject unsupported saved size preferences, changed adaptive try budgets
and guesses after completion. Focused letter keys activate with hardware Space
in both Latin and Gurmukhi rounds. These widget checks establish Flutter input
behavior; actual browser/iframe and screen-reader checks remain separate.

The visual refresh keeps all three themes and game rules intact. Contrast tests
cover primary/secondary action labels, normal surface text, and correct/present/
absent tile labels. Khoj input tests cover forward and reverse words, arrow-key
bounds, Space/Enter, Escape, and switching between pointer and keyboard. Word
Quest has a regression for restoring an unfinished game after asynchronous
vocabulary loading. Short-screen layouts must remain scrollable when readable
controls no longer fit; do not shrink the grid to zero.

Browser inspection covered the library and all three modes in Modern, Sikhi and
Dark. Phone-size and 200% text evidence is from Flutter widget tests. Actual
mobile browsers, screen-reader announcements, and hosted iframe interaction still
need separate checks. Twelve visual baselines now cover the shared components
and a representative state in each mode across all three themes.

## Release candidate 1.3.0+5 evidence

The complete local unit/widget suite passes 136 tests, including 12 Windows
visual goldens. The analyzer, release-content freshness and distribution audits,
Node service-worker behavior suite, and release packaging pass. The authoring
audit retains 5,446 editorial flags; those are review work, not cleared findings.

The later Punjabi policy pass has separate focused evidence: 17 parsing,
quality, release-builder, and unique-pool audit tests pass; two consecutive dry
runs reported zero changed overrides and zero new entries; and the applied
release distribution audit passed all 12 language and length pools using unique
playable spellings. These targeted results do not replace a full suite and
package rebuild after the content assets change.

The packaged app was served at a nested localhost path with HTTP no-store headers.
After its offline-ready signal, the online tab was closed and the server stopped.
A new tab loaded the library, restored Bujho, accepted a guess, generated a
Gurmukhi Khoj puzzle with local fonts, and completed Word Quest. This establishes
local Chromium cache behavior, not storage permission in the actual itch.io iframe.

Hosted release browser integration passed in [run 34671765499](https://github.com/srajpal/sikhi_word_games_v2/actions/runs/34671765499)
on commit 8492ec5, alongside analysis, content audits, unit/widget tests, web build,
and Windows visual tests. The harness uses `-d web-server` and the exact browser
and driver paths from setup-chrome. Selecting `-d chrome` stalled this toolchain;
letting ChromeDriver pick the runner's preinstalled browser caused a version
mismatch. The integration step has a five-minute timeout.

Physical mobile, screen-reader, Safari/Firefox and actual itch.io draft checks
remain open in TODO.md.

### Word Bridges candidate verification

The engine and repository checks cover either-side selection, mismatch/clear,
immutable snapshots, invalid saves, idempotent completion, per-language totals,
and late/stale writes. Content checks resolve the three mode pools and their
compatible preview decks from actual approved assets; fixed starter decks are
retired. Restore rejects missing/ineligible words, changed definitions and
malformed or unsupported saves. Widget checks cover semantic activation, physical
keyboard Space, a 320-pixel viewport with 200% text, restore after navigation,
obsolete definitions, unavailable content, failed storage and rapid input during
slow saves. An app integration test covers library launch, first guide, Continue,
completion, aggregate statistics and a fresh relaunch. Real TalkBack speech and
actual-host iframe/offline behavior remain separate manual checks.

### Redesign regression checks

The 1.6.0+10 checks cover full-height shared backdrops in all three themes,
unchanged Jodo card rectangles after selection and matching, and full wrapping
Quest clues. Guide-route tests center actual buttons and assert hit-testability
in the two-column library. Quest retry completion verifies unobstructed letter
key taps; inline feedback replaces the keyboard-obscuring snackbar. Shared and
three-game golden references are intentionally refreshed for this design.
The gallery and Jodo now have three-theme visual fixtures too (18 in total).
The gallery semantics regression checks that each game's title, description and
actions remain in its own subtree. The packaged browser AX tree is checked
separately, since screenshot comparisons cannot prove reading order.

Phone layout regression coverage adds saved/unsaved home action positions at
320 pixels, a long-English-definition Jodo board with full-width meanings and
stable state geometry, and Gurmukhi Romanized text below each word after restore.
The content lookup checks the existing spelling source without altering the save
schema. Two 360-pixel golden fixtures cover English and Gurmukhi phone layouts.

Studio branding checks verify that the website action uses the supplied HTTPS
address and offers a selectable fallback when browser launch is unavailable.
Library golden references include the byline and studio link in all three themes.
Android launcher artwork is regenerated from the existing SWG vector source;
Android packaging is separate from physical-device or store-listing validation.

Reset coverage includes cancel preservation, exact owned-key deletion, defaults and first-launch guide restoration, pending-write ordering across repository instances, storage failure recovery, and retry. Real user-device data must not be cleared merely to exercise this feature.


Victory checks cover global/per-game opt-outs, migration and reset, reduced-motion suppression, silent audio failure, nonblocking/finite particles, immediate settings changes and dismissal, Jodo final-match-only accounting and reopen behavior, and Quest guess/hint wins. Victory visual baselines include all three themes and a narrow 200% text case. Automated audio spies establish playback requests, not audibility on a physical speaker; real web/Android playback remains separate evidence.


Learn Letters coverage includes35uniquecontentitems, nonduplicatechoices, wrongretrylimits, manualadvance, priorityselection, roundJSONvalidation, partialrestore, completiondeduplication, savequeue/reset/errorbehavior,21-round practice progression, homeguide/Continue/global totals, and narrow/large-text layouts. Visual baselines cover all3themes and postanswer pronunciation controls. All35 generatedWAVs must be non-silent/unclipped and present in the packaged offline cache. Listening approval remains a separate human check.

### Paper & Play reference verification (October 8)

The 1.10.1+20 UI correction uses decoded, bundled WebP backgrounds and shared
paper surfaces. Golden setup explicitly awaits image IO; settling animation
frames alone can capture a missing illustration. All 31 visual cases cover
Modern/Sikhi/Dark library phone/tablet layouts, game boards and shared
components. Inspect the rendered captures, not only the generated asset files.

The final full suite passes 329 tests. Keyboard checks cover readable colored
clues and spoken status values in every theme, strongest clues across repeated
letters and later guesses, and retained input activation. Existing checks cover
320/800-pixel headings at 100/200% text, phone game layouts, offline persistence,
Dictionary navigation and saved Progress totals. The browser integration flow
uses the stable new-game key rather than the previous visible button caption.
Physical gameplay and real browser/offline/audio evidence remain separate.


### Play consistency and achievements: 1.11.0+22

Regression checks include the three-language boundary, shared language headings,
3/4/5 Quest misses and 0/1/2 hints, repeated legacy-budget saves, 20 seeded Jodo
sets per language with over 60 distinct IDs and mixed word lengths, current
eligibility/provenance and conflicting-clue rejection. Listening tests check that
answer glyph/name stays hidden before a correct choice, target audio remains
below the target, and practice mode survives restore. Existing sound clips are
unchanged; playback requests do not prove speaker audibility or pronunciation.

Achievement tests cover exactly ten stable goals per game, threshold boundaries,
old-stat projections, no fabricated historical facts, atomic once-only new
completion facts, reset and all-theme 320px/200% text. New page goldens include
three achievement galleries and a Settings phone. Review rendered captures before
accepting changed baselines. Page navigation/reset tests exercise the real routes.
Settings applies and persists each change without leaving its route. Regression
coverage checks immediate theme changes, independent sound switches, app
recreation, queued rapid edits finishing after Back, and storage failure/recovery.
Back must return to a playable library; the browser fixture also verifies
interrupted game restore. Celebration switches apply before sheet dismissal.

### Mobile navigation, feedback and dictionary v2: 1.12.0+23 (historical content checks)

Navigation regressions exercise all four persistent destinations at phone/tablet
sizes and 100/200% text, asserting the selected destination and visible bar.
Game feedback is shown, followed by Back to Play and Dictionary, to ensure a
toast cannot survive its game route. Mixed-length Khoj ignores older launch-size
preferences and includes longer targets; valid older saved boards remain usable.
All three lines of the paper header fit across the existing theme/size/text matrix.

Click audio tests spy on actual callbacks, independent persisted switches,
disabled/background/scroll silence, playback failures and lifecycle handling.
Generated WAVs are checked for duration and clipping. Speaker audibility remains
a device/browser check. The narrower Settings layout has a 200% text regression.

Dictionary validation reproduces both locked source snapshots, exact sense-linked
decisions and filtered runtime banks with one offline `--check`. Import-policy
tests cover inappropriate senses, reference/junk/context-dependent clues, unsafe
cross-part-of-speech fallbacks and transliteration integrity. The source/semantic
review adds regressions for observed failures; neither source matching nor a
passing sample certifies all content as human reviewed or child suitable.

### Approved dictionary import: candidate 1.13.0+24

The import changes dictionary sources, schemas and written-unit behavior.
Re-run applicable content/repository/game tests, analysis, full widget/golden
checks and a release web build. Package inspection must establish byte-identical
English, Romanized Punjabi and Gurmukhi masters and required attribution/licenses,
with retired banks and authoring files absent. Actual browser checks cover all
three modes, scholarly Roman diacritic input, Gurmukhi conjunct tiles, dictionary
mode filtering and restored-game behavior. Audio approval remains separate.

Record actual completed evidence in `TODO.md`. This section specifies required
checks and does not claim that candidate build 24 has passed them.

Simple Punjabi checks cover every approved Roman spelling mapping to A-Z while
retaining its tile count, source ID, definition and membership, deduplicated
spelling collisions, plain Bujho input, legacy accented resume then new simple
round, and round-style isolation across all four word games. Updated English
checks require the exact 13,182/2,991/4,428 master totals and accept MICE as a
four-letter guess. Phone/tablet gallery checks assert equal Bujho/Khoj widths
and aligned action rows; updated visual baselines require rendered review.

Phone regressions verify that English and Simple Punjabi Bujho expose the board
and Enter key without scrolling at 4/5/6 letters. Retain the separate accented
and Gurmukhi keyboard and large-text reachability checks. Repeated unsuccessful
Khoj drags must leave progress intact without a SnackBar, followed by a valid
find with normal feedback. Dictionary must omit its introductory banner while
retaining search results and both Punjabi keyboard views.

### Shabad Banao: 1.16.0+29

Engine checks exercise duplicate tile IDs, incomplete/incorrect/correct checks,
meaning-hint immutability, 150 seeded move sequences, restore corruption and
intact Gurmukhi conjuncts. Repository checks cover frozen queued snapshots,
once-only scoring across instances, a late completion preserving a newer round,
malformed-history recovery and reset. Vocabulary checks use the actual three
approved masters, including MICE, native ਅਪ੍ਰੈਲ and Simple/full ĀSĀN; pools
remain isolated and rotate before repeating. Route tests verify the sixth card,
help, Back/Continue, completion totals and app-wide reset ownership.

Widget checks cover all themes at phone size, tap/undo/shuffle/hint, quiet inline
retry feedback, original accented resume after changing Simple, and 320px/200%
Gurmukhi layout. Five new font-loaded visual baselines cover three themes,
Gurmukhi groups and enlarged text; review the updated library and badge gallery
captures too. Actual packaged-browser persistence, font rendering and device
installation are separate evidence recorded in TODO.md.

Gurmukhi tile-label regressions verify visible and spoken Romanization in the
tray, after placement, after revealing the meaning and after completion across all three
themes. Empty spaces and English tiles reveal no pronunciation labels. Enlarged
Gurmukhi text remains scrollable without splitting a written unit; actual-font
phone and 200% captures must be reviewed after changes to label sizing.
Anagram-first regressions require the definition to be absent from the visual
and semantics trees until Hint or completion. Hint must preserve slots/tray,
survive navigation/recreation, count as hinted, and reset for the next word.
Unhinted completion reveals the meaning without changing unhinted statistics.
Restore covers optional clue visibility and legacy already-locked hint tiles.
