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
- Release browser checks must cover all three games and Dictionary with real
  assets, local storage, mouse/touch, physical keyboard, and Gurmukhi rendering.

## Required cases

Check exact/present/absent feedback and repeated letters; four-, five-, and
six-grapheme games in all four language modes; invalid and guess-only words;
random selection/exhaustion; winning and losing; new/continue/back navigation;
corrupt and unsupported saves; restart and settings isolation. For Khoj include
drag direction, duplicate target detection, hints, and completion. For Word Quest
include repeated guesses, adaptive tries/hints, simple/full keyboards, and clue
quality. A vocabulary coverage count is not a human definition-quality review.

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

The packaged app was served at a nested localhost path with HTTP no-store headers.
After its offline-ready signal, the online tab was closed and the server stopped.
A new tab loaded the library, restored Bujho, accepted a guess, generated a
Gurmukhi Khoj puzzle with local fonts, and completed Word Quest. This establishes
local Chromium cache behavior, not storage permission in the actual itch.io iframe.

The release Chrome integration target compiled locally but stalled before its
test handshake. CI includes a matching Chrome/ChromeDriver run; until that run
succeeds, do not label browser integration passed. Physical mobile, screen-reader,
Safari/Firefox and actual itch.io draft checks remain open in TODO.md.
