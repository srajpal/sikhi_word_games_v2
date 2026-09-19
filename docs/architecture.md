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
decorative library previews, and `GameSceneColors` supplies the Word Quest garden
palette. All three game modes use the active theme; Word Quest does not maintain
a separate fixed palette. Shared actions expose button semantics and a minimum
44px height.

Shared Gurmukhi keyboard presentation includes one pronunciation function and a
two-line key label used across games. Games may own different keyboard layouts
when their input rules differ: Bujho and Dictionary compose a word from base
letters and vowel signs, while Word Quest selects whole grapheme clusters.
Those layouts must reuse the shared pronunciation and label components.

### Feature modules

Each game owns its domain rules, application/controller state, presentation widgets, and feature-specific data adapters. A game must not add states such as help dialogs or settings panels to its rule engine.

### Platform adapters

Small implementations for local storage, sharing, haptics, and other platform-specific capabilities. Domain code depends on interfaces rather than plugins.

The first persistence adapter wraps `SharedPreferences` behind a small key-value interface. App settings and active-game snapshots carry explicit schema versions and fall back safely when stored data is malformed or from an unsupported schema. Tests use an in-memory implementation of the same interface.

### Game-library launch flow

The game library owns the shared launch experience for every playable mode. A
launch request can start a fresh game with an explicit language and four-, five-,
or six-grapheme word size, or use `null` for either field to select randomly.
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
- Text processing uses Unicode grapheme clusters rather than code units.
- Accepted guesses and eligible solutions are different collections.
- Random selection can be seeded for deterministic tests.
- Mixed English/Punjabi accepts both English and romanized Punjabi guesses.
- Gurmukhi remains a separate mode.

## Khoj: Word Search rules

- Each target has a distinct selectable cell path, including reverse-word
  pairs. Saved puzzles must contain one grapheme per cell, unique nonempty
  targets, matching grid letters and distinct target paths. Invalid snapshots
  fall back to a new game through the existing session recovery behavior.

- The persisted puzzle stores displayed words and grid graphemes; definitions
  and romanized Punjabi are resolved from the loaded offline vocabulary so the
  existing session schema remains compatible.
- Each unsolved target has one first-grapheme hint control. Activating it
  highlights every matching grapheme in the grid, and activating another target
  replaces the current hint.
- Target words open their English definition in the shared five-second,
  dismissible game message. The game menu also links to the full dictionary.
- Gurmukhi grid tiles use the shared two-line pronunciation label, and Gurmukhi
  target words show their curated Latin form beneath the word.
- The play screen uses the app bar as its only header, sizes the grid from the
  available viewport height, and keeps target cards in one row when space allows.
  Each target's first-grapheme control includes an explicit visual hint symbol.
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
rewrite. The runtime package contains three sanitized release shards for four-,
five-, and six-grapheme vocabulary. Visible definitions must carry an approved
source or be original project editorial text. Definitions with unclear legacy
provenance are removed from the release shards, and affected entries cannot be
solutions. Generated source data, editorial queues, curation records, and backups
remain authoring data and must not enter the web archive.

Bujho, Khoj, and Word Quest all select answers through the curated
`solutionEligible` boundary. Source provenance, mechanical definition quality,
and editorial approval remain separate decisions. The Punjabi review pipeline
records the pinned source entry and sense for traceability, preserves explicit
answer exclusions, and marks automated results as machine checked. Release
generation revalidates those decisions and requires every answer to remain an
accepted guess. Each game de-duplicates the active mode by its displayed spelling,
so stable alias IDs can support saved games without weighting the same answer
twice. Release audits report both source-record totals and unique playable
spellings; only the unique count establishes pool coverage.

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

Word Bridges separates its pure Dart matching engine, fixed-deck content resolver,
single-key persistence repository, and Flutter presentation. Four unique pairs are
shuffled independently on each side. Either side can be selected first; a mismatch
counts an attempt without removing solved pairs. Completion, per-language statistics,
and round-ID deduplication are saved atomically. Restore checks the saved pairs
against current eligible content. Starter decks reference shipped stable vocabulary
IDs and fail closed when an entry or usable sourced definition is unavailable.

Studio attribution lives in `lib/core/studio_brand.dart`. Its website action uses
`url_launcher` to open the supplied Khalsa Game Studio HTTPS address in an external
browser. It is invoked only by a player tap; no studio network requests are needed
for app startup, puzzle play or persistence. A launch failure shows a selectable
address instead of interrupting the game library.

App-wide reset is available only from the library. Repositories remove their exact owned keys; unrelated origin data is preserved. Writes and removals are queued by store identity and key to drain pending saves before removal, including writes from multiple repository instances. Failure may leave a partial reset and is reported with retry. UI reloads persisted settings and library state after either outcome.


VictoryCelebration is a shared route-owned wrapper around GameGuide. Games notify only from accepted player-action win transitions; the wrapper owns the finite animation and audio player, stops on a new round/background/disposal, and does not persist events. Preferences remain within app.settings, so app-wide reset includes them. Audio uses audioplayers with a bundled original PCM WAV generated by app/tool/generate_victory_sound.py; no runtime network is needed. Audio errors are nonfatal. Particle colors derive from the active shared theme.


Learn Letters uses a separate validated35-entry letter table, a five-question round model, and learnLetters.state.v1 for atomic session/statistics/first-try practice counts/completion IDs. Frozen snapshots enter the shared key write queue; completed round IDs prevent duplicate scoring. Counts update only on completed rounds. App-wide reset includes this key and the guide/settings entries. Global rounds include completed letter rounds, while word totals exclude letters.

LetterPronunciationButton plays bundled WAV previews on explicit activation, stops earlier letter playback, and disposes players with their widgets. Backgrounding stops playback; failures are visible and retryable. Pronunciation playback is independent of optional victory sound settings. Local .audio-tools and .audio-venv are ignored and never packaged.
