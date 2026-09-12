# Sikhi Word Games V2: Architecture

## Goals

- Keep game rules testable without rendering Flutter widgets.
- Reuse vocabulary, themes, settings, and statistics across future games.
- Remain offline-first and avoid unnecessary permissions or network dependencies.
- Support phones, tablets, and browsers without separate application implementations.

## Layers

### Core

Shared vocabulary models, content loading, persistence contracts, themes, accessibility conventions, and reusable widgets.

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
needed for the present scope. Bujho owns statistics and durable answer rotation;
these are not yet a shared cross-game statistics service. Riverpod currently
wraps the app at startup while most state is owned by widgets and repositories.
Do not add another state layer just to prepare the web release.

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

The itch.io package generates a content-identified service worker after the final
web build. It caches only a bounded allowlist of same-origin files within the
worker's exact registration scope. Cache names include the full encoded scope,
and activation removes only older caches for that same scope. A failed install
removes its partial cache. Updates wait until older controlled pages close, which
keeps one page from loading a mixture of two builds. These controls support nested
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
