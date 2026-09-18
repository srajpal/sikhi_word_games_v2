# Sikhi Word Games V2: Testing Strategy

## Coverage and limits

- Pure Dart unit tests cover game rules, content transformations, pool selection,
  Unicode graphemes, scoring, and persistence serialization.
- Flutter widget tests cover launch preferences, navigation, input, completed
  games, semantics, and selected responsive sizes.
- Twelve Windows golden image tests cover Modern, Sikhi, and Dark. They run
  separately from Linux unit/widget checks to keep rendering baselines consistent.
- The integration fixture covers preferences and interrupted Bujho restoration
  with an in-memory store. It does not establish browser restart persistence.
- Release browser checks must cover all five games and Dictionary with real
  assets, local storage, mouse/touch, physical keyboard, and Gurmukhi rendering.

## Required cases

Check exact/present/absent feedback and repeated letters; four-, five-, and
six-grapheme games in all four language modes; invalid and guess-only words;
random selection/exhaustion; winning and losing; new/continue/back navigation;
corrupt and unsupported saves; restart and settings isolation. For Khoj include
drag direction, duplicate target detection, hints, and completion. For Word Quest
include repeated guesses, adaptive tries/hints, simple/full keyboards, and clue
quality. A vocabulary coverage count is not a human definition-quality review.
For Punjabi policy changes, test normalized Gurmukhi sequences, conjuncts,
pronunciation consonant order, exact source/headword/sense matching, protected
exclusions, conflicting proposal targets, definition fragments, answer leakage,
and sensitive or damaged dictionary text. Re-run the review twice after writing;
the second pass must report no changed overrides or new entries.

Test narrow and short screens, large text, all themes, visible keyboard focus,
screen-reader labels, contrast, motion settings, and long definitions. Real
screen-reader and physical mobile-browser checks remain release gates where
widget tests cannot establish behavior.

## Quality gates

Run from `app/`:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --suppress-analytics
flutter test --suppress-analytics
dart run tool\audit_content.dart
flutter build web --release --no-web-resources-cdn --suppress-analytics
```

Run the integration target on a configured supported device separately. It is
not included in `flutter test` by default. Keep formatter changes scoped when
preserving another contributor's work. The content audit may finish successfully
while reporting editorial defects; its issue counts must be reviewed.

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
and late/stale writes. Content checks resolve all four fixed starter decks from
actual shipped assets and fail closed for held, missing, duplicated, unsourced,
or script-incomplete entries. Widget checks cover semantic activation, physical
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


Victory checks cover global/per-game opt-outs, migration and reset, reduced-motion suppression, silent audio failure, nonblocking/finite particles, settings cancel/save, Jodo final-match-only accounting and reopen behavior, and Quest guess/hint wins. Victory visual baselines include all three themes and a narrow 200% text case. Automated audio spies establish playback requests, not audibility on a physical speaker; real web/Android playback remains separate evidence.


Learn Letters coverage includes35uniquecontentitems, nonduplicatechoices, wrongretrylimits, manualadvance, priorityselection, roundJSONvalidation, partialrestore, completiondeduplication, savequeue/reset/errorbehavior,21-round practice progression, homeguide/Continue/global totals, and narrow/large-text layouts. Visual baselines cover all3themes and postanswer pronunciation controls. All35 generatedWAVs must be non-silent/unclipped and present in the packaged offline cache. Listening approval remains a separate human check.
