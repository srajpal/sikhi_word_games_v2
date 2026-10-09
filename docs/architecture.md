# Sikhi Word Games V2: Architecture

## Goals

- Keep game rules testable without rendering Flutter widgets.
- Reuse vocabulary, themes, settings, and statistics across future games.
- Remain offline-first and avoid unnecessary permissions or network dependencies.
- Support phones, tablets, and browsers without separate application implementations.

## Layers

### Core

Shared vocabulary models, content loading, persistence contracts, themes, accessibility conventions, and reusable widgets.

Vocabulary loading coalesces concurrent requests and caches immutable entries.
Native platforms decode and construct entries in a `compute` isolate. Web yields
before each JSON shard and every 250 constructed records; individual shard JSON
parsing still runs on the browser thread. Malformed records report their IDs.

`GameThemeTokens` owns panel, control and tile treatment. `GameArtwork` provides
decorative library previews, and `QuestLantern` draws a secular countdown from
the active color scheme. All three game modes use the active theme; Word Quest does not maintain
a separate fixed palette. Shared actions expose button semantics and a minimum
44px height.

Shared Gurmukhi keyboard presentation includes one pronunciation function and a
two-line key label used across games. Games may own different keyboard layouts
when their input rules differ: Bujho and Dictionary compose a word from base
letters and vowel signs, while Word Quest selects whole written units.
Those layouts must reuse the shared pronunciation and label components.

### Feature modules

Each game owns its domain rules, application/controller state, presentation widgets, and feature-specific data adapters. A game must not add states such as help dialogs or settings panels to its rule engine.

### Platform adapters

Small implementations for local storage, sharing, haptics, and other platform-specific capabilities. Domain code depends on interfaces rather than plugins.

The first persistence adapter wraps `SharedPreferences` behind a small key-value interface. App settings and active-game snapshots carry explicit schema versions and fall back safely when stored data is malformed or from an unsupported schema. Tests use an in-memory implementation of the same interface.

Removing an obsolete active save is best-effort during game recovery: Bujho,
Khoj and Word Quest report rejected cleanup through the shared save notice and
still start a replacement round. Cleanup and replacement saves retain their
ordering in the shared key queue. Word Quest validates the saved 4/5/6 size
preference and adaptive try budget, and replays guesses to reject moves after
completion. Explicit custom budgets remain a domain capability, separate from
the app's saved-session contract.

### Game-library launch flow

The game library owns the shared launch experience for every playable mode. A
launch request can start a fresh Bujho or Quest game with an explicit language
and four-, five-, or six-tile word size, or use `null` to select randomly.
Khoj chooses only a language and mixes word lengths; Jodo also mixes lengths.
Each mode keeps its own versioned active-game snapshot so the library can offer
Continue game only for an unfinished session. Starting a new game replaces that
mode's snapshot; completing a game clears it.

The library also stores the last launch preference for each game mode separately
in a versioned snapshot.
An explicit random language or word-size choice is persisted as `null`, so the
mode continues to randomize that setting on later new games until the player
chooses a concrete value.

## Current feature boundaries

```text
lib/
  app/
  core/
    content/
    persistence/
    themes/
    accessibility/
    widgets/
  features/
    game_library/
    guess_the_word/
      domain/
      application/
      data/
      presentation/
    settings/
    word_search/
    word_quest/
    dictionary/
```

## Bujho: Guess the Word rules

- Evaluation uses a two-pass algorithm: mark exact matches first, then consume remaining solution-letter counts for present matches.
- Text processing uses source-validated written units rather than code units; generic graphemes are not substituted when Gurmukhi conjuncts differ.
- Accepted guesses and eligible solutions are different collections.
- Random selection can be seeded for deterministic tests.
- The selectable language modes are English, Romanized Punjabi and Gurmukhi; retired mixed saves recover to a supported fresh round while historical statistics remain.
- Gurmukhi remains a separate mode.

## Khoj: Word Search rules

- New puzzles have no word-size preference. Select six distinct eligible words
  of the available mode-specific written-unit lengths, then use a 10-cell grid that grows to fit longer targets.
  Valid older saved boards can finish with their historical statistics bucket;
  subsequent puzzles use the language-wide bucket. The title shows language only.

- Each target has a distinct selectable cell path, including reverse-word
  pairs. Saved puzzles must contain one written unit per cell, unique nonempty
  targets, matching grid letters and distinct target paths. Invalid snapshots
  fall back to a new game through the existing session recovery behavior.

- The persisted puzzle stores displayed words and grid written units; definitions
  and romanized Punjabi are resolved from the loaded offline vocabulary so the
  existing session schema remains compatible.
- Each unsolved target has one first-unit hint control. Activating it
  highlights every matching written unit in the grid, and activating another target
  replaces the current hint.
- Target words open their English definition in the shared five-second,
  dismissible game message. The game menu also links to the full dictionary.
- Gurmukhi grid tiles use the shared two-line pronunciation label, and native
  target words show their source Roman counterpart beneath the word. This aid
  does not introduce the counterpart into another mode's target pool.
- The play screen uses the app bar as its only header, sizes the grid from the
  available viewport height, and keeps target cards in one row when space allows.
  Each target's first-unit control includes an explicit visual hint symbol.
- The grid supports both pointer dragging and keyboard selection. Arrow keys
  move the visible grid focus, Enter or Space chooses the start and end cells,
  and Escape cancels an unfinished keyboard selection.
- Pointer input resets keyboard selection state. Selected cells retain a
  contrasting focus outline. Short or heavily scaled layouts scroll the board
  and targets together while preserving a usable grid.

## Security and privacy

- Do not embed credentials, secrets, or private keys.
- Do not store passwords because V2 has no accounts.
- Bundle only content that may safely be distributed publicly.
- Treat compiled mobile code and web assets as inspectable by a determined user.
- Introduce networking only through a reviewed HTTPS adapter if future scope requires it.

## Release architecture assessment

The current separation is suitable for a small static playtest: game engines are
pure Dart, persistence is behind a key-value interface, and the three games share
vocabulary, launch preferences, themes, and language utilities. No backend is
needed for the present scope. Bujho preserves its existing statistics and durable
answer rotation. Khoj and Word Quest use a shared statistics repository with
separate per-game storage keys and language/length buckets. The library reads
all three repositories for its summary; it does not store a second aggregate or
combine their win rates. Riverpod currently
wraps the app at startup while most state is owned by widgets and repositories.
Do not add another state layer just to prepare the web release.

Statistics count finished attempts only. Leaving a round does not create a
loss. A Word Quest retry is another attempt; hinted wins are shown separately.
Khoj records a puzzle and its target count only on completion. Existing Bujho
history is retained, while the other games begin counting with this feature.
The shared summary includes repeated words, rather than claiming unique words
learned. Statistics writes and active-session cleanup are separate operations;
they are not a crash-atomic transaction.

Each game route has a skippable three-step first-launch guide. Independent
versioned markers live in the shared local store. Skip, Done and Back dismissal
prevent future automatic display; Help can replay the guide without resetting
the game. Help and walkthroughs use shared rule text. Tests may omit the guide
repository to exercise gameplay directly; production injects the persisted one.

Shared controls expose semantic activation and wrap larger action text. Khoj
supports screen-reader activation of start/end cells, including cancellation
by activating the start again. Word Quest letter keys support focus and
activation as well as direct typing. Accessible-navigation feedback remains
until dismissed. Device reduce-motion settings supplement the app preference.
These mechanisms still require physical TalkBack/VoiceOver playtesting.

The main scale risks are the large JSON vocabulary, synchronous parsing/filtering
on the UI isolate, and large presentation files. Measure cold loading and input
latency on a modest phone before choosing an indexed format or moving parsing
work. Keep future extraction focused on tested behavior rather than a release-time
rewrite. The runtime package contains three owner-approved native JSON masters:
English, Romanized Punjabi and Gurmukhi. They are copied byte-for-byte from
`app/content/approved_release/` and accompanied by attribution and licenses.
Runtime adapters construct the internal game model without rewriting selected
definitions, spellings or source metadata. Raw imports, TXT exports, review notes,
editorial queues and backups remain outside runtime assets.

`tool/build_release_content.dart --import-from <path> --write` validates and
imports an explicitly approved release. Later `--write` rebuilds from the local
snapshot and `--check` audits exact hashes, counts and written units. It does
not run the retired frequency/suitability selection policies. The owner's
October 9 approval covers every word and definition in that snapshot.

Each language mode draws exclusively from its own master. Counterpart spellings
are presentation/lookup metadata and cannot expand another mode's pool. Source
`letter_units` and `tile_count` govern keyboard, board, input and fixed-size
selection through the shared written-unit helper, including conjuncts where
`.characters` differs. Romanized Punjabi preserves scholarly diacritics;
Gurmukhi preserves its native written units. Bujho and Quest use available
4/5/6-tile words; Khoj and Jodo use their broader mode bank.

Games deduplicate the active mode's displayed spelling, and validate restored
targets against current mode membership and units. Removed historical content
recovers through a fresh round while cumulative statistics remain. Integrity
and compatibility checks do not create a new editorial answer subset. Release
audits compare the exact three masters with the approved manifest and verify
required licenses, without treating old queues or pool quotas as approval gates.

The itch.io package generates a content-identified service worker after the final
web build. It caches only a bounded allowlist of same-origin files within the
worker's exact registration scope. Cache names include the full encoded scope,
and activation removes only older caches for that same scope. A failed install
removes its partial cache. Updates wait until older controlled pages close, which
keeps one page from loading a mixture of two builds. The bootstrap detects waiting
updates and shows a dismissible notice to finish the round, close all game tabs
and reopen. It also checks for updates on focus; it never forces activation or a
mid-round reload. These controls support nested
itch.io paths, but actual offline reload still requires verification in the hosted
draft because iframe and browser storage policies can restrict service workers.

Web storage is local to the browser and origin. It is not an account or backup,
and browser clearing/private modes or hosting-origin changes can lose progress.
The existing in-memory integration fixture does not prove real browser storage
or iframe behavior. Corrupt save handling and disabled/unavailable storage are
separate scenarios. An offline game engine also does not establish that a fresh
browser can download or reload the hosted application without a connection.

The local dictionary authoring server is excluded from the web package. Its
write endpoints require JSON and a loopback Origin matching the actual bound
port, so unrelated web pages cannot submit simple cross-site writes. This guard
is independent of the Host header. It is a local authoring tool, not a hosted API.

## Word Bridges

Word Bridges separates its pure Dart matching engine, eligible-pool content resolver,
single-key persistence repository, and Flutter presentation. Four unique pairs are
shuffled independently on each side. Either side can be selected first; a mismatch
counts an attempt without removing solved pairs. Completion, per-language statistics,
and round-ID deduplication are saved atomically. Restore checks the saved pairs
against current mode membership. New sets use every eligible owner-approved
mode word without a global definition-length/quality filter; identical or
conflicting clues are avoided only within the current four-pair board.
Historical starter decks are regression fixtures rather than current release
inputs. Restore fails closed when
a saved target or its definition is unavailable in that mode.

Studio attribution lives in `lib/core/studio_brand.dart`. Its website action uses
`url_launcher` to open the supplied Khalsa Game Studio HTTPS address in an external
browser. It is invoked only by a player tap; no studio network requests are needed
for app startup, puzzle play or persistence. A launch failure shows a selectable
address instead of interrupting the game library.

App-wide reset is available only from the library. Repositories remove their exact owned keys; unrelated origin data is preserved. Writes and removals are queued by store identity and key to drain pending saves before removal, including writes from multiple repository instances. Failure may leave a partial reset and is reported with retry. UI reloads persisted settings and library state after either outcome.


VictoryCelebration is a shared route-owned wrapper around GameGuide. Games notify only from accepted player-action win transitions; the wrapper owns the finite animation and audio player, stops on a new round/background/disposal, and does not persist events. Preferences remain within app.settings, so app-wide reset includes them. Audio uses audioplayers with a bundled original PCM WAV generated by app/tool/generate_victory_sound.py; no runtime network is needed. Audio errors are nonfatal. Particle colors derive from the active shared theme.


Learn Letters uses a separate validated35-entry letter table, a five-question round model, and learnLetters.state.v1 for atomic session/statistics/first-try practice counts/completion IDs. Frozen snapshots enter the shared key write queue; completed round IDs prevent duplicate scoring. Counts update only on completed rounds. App-wide reset includes this key and the guide/settings entries. Global rounds include completed letter rounds, while word totals exclude letters.

LetterPronunciationButton plays bundled WAV previews on explicit activation, stops earlier letter playback, and disposes players with their widgets. Backgrounding stops playback; failures are visible and retryable. Pronunciation playback is independent of optional victory sound settings. Local .audio-tools and .audio-venv are ignored and never packaged.


### 1.11 play consistency and progress projection

`GameLanguageHeader` centralizes compact language/optional word-size text inside
`GameHeading`'s paper label. Shared game toasts float below the toolbar without
changing board geometry. Each game route owns a `ScaffoldMessenger`; disposal
removes its feedback rather than carrying it to other routes.
`PaperPage` owns full-page Settings/Progress/Achievements and per-game details;
Dictionary retains its dedicated searchable route. The router exposes `/settings`,
`/progress` and `/achievements` beside the existing game/Dictionary routes.

`PlayerProgress` projects achievement facts from existing repositories without a
second aggregate store. Jodo saves rotation IDs and completion facts in its atomic
state; Learn Letters saves the practice mode and listening/perfect-round counts
in its existing state. Repeated completion IDs remain inert. Missing new fields
in older states mean zero; malformed new fields fall back safely. App-wide reset
already owns these keys. Achievement IDs/goals live in a pure Dart catalog.

Quest session schema 2 enforces 3/4/5 misses. Schema 1 still enforces the previous
5/6/7 budget for valid unfinished legacy rounds and is retained on their next save.
New rounds always use schema 2. This preserves played moves without accepting
arbitrary custom budgets as app sessions.

### Primary navigation and click feedback

`StudioNavigation` uses one native Material navigation bar on all four primary
pages. Its explicit destination drives selected state, and `context.go` replaces
the primary selection; game routes remain focused. `PaperPage` accepts an optional
primary destination so Settings/game-details do not acquire the library bar.

`InteractionSounds` encloses the Navigator in the app builder. Accepted letter
and button callbacks request independent short, low-volume bundled WAVs. Disabled
controls, scrolling and background gestures do not play sounds. Separate lazy
players avoid stopping pronunciation or victory audio; lifecycle disposal and
backgrounding stop clicks and playback errors remain nonfatal. Independent
`letterClicks`/`buttonClicks` preferences migrate older settings with enabled
defaults and are included in reset. Original WAV generation is reproducible.

App-wide preference changes update shared theme, sound and feedback state before
awaiting persistence. The Settings route stays open and refreshes from that state,
including after reset. Immutable snapshots enter the existing per-key write queue,
so rapid edits persist in order even when Settings is closed before writes finish.
Write failure leaves preferences active for the session and reports unavailable
storage; later changes can persist the current full snapshot.

`RomanizedVocabularyViews` derives and caches original/simple in-memory banks.
Both preserve source identity and mode membership; game indexes deduplicate
accent-free collisions. `simpleRomanizedPunjabi` is an app preference;
`simpleRomanized` is per-round persisted metadata. An absent round marker means
the original bank, so changing the app preference never invalidates a valid
unfinished round. New game/set/puzzle selects the current preference; Quest Retry
retains the current round view. Statistics/history remain shared. Dictionary
uses the current preference and a matching keyboard/input normalization.

### Word Scramble

`features/word_scramble/` separates a pure tile engine, cached mode pools,
single-key repository and presentation. Stable tile IDs distinguish repeated
letters; visible units come from shared `wordUnits`, preserving Gurmukhi
conjuncts. Placement, undo, shuffle, one locked hint and checks maintain a
complete tile permutation. Restore validates that permutation and current
source ID, spelling and definition in the recorded original/simple view.

`wordScramble.state.v1` stores a frozen session snapshot, per-mode rotation,
completion IDs and statistics atomically through the shared ordered write queue.
Completion scoring is idempotent across repository instances; a late old
completion cannot remove a newer session. Only completed words count in Progress
and achievements. The exact owned key participates in app-wide reset. Save
failures remain visible and retryable without blocking offline play. The new
route uses the shared game shell for guides, route-scoped feedback and victory
effects. Enlarged written units and headings grow/wrap rather than splitting
Gurmukhi groups or shrinking accessibility text.
