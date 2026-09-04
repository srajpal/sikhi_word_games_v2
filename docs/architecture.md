# Sikhi Word Games V2 — Architecture

## Goals

- Keep game rules testable without rendering Flutter widgets.
- Reuse vocabulary, themes, settings, and statistics across future games.
- Remain offline-first and avoid unnecessary permissions or network dependencies.
- Support phones, tablets, and browsers without separate application implementations.

## Layers

### Core

Shared vocabulary models, content loading, persistence contracts, themes, accessibility conventions, and reusable widgets.

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

## Initial feature boundaries

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
    statistics/
```

## Bujho: Guess the Word rules

- Evaluation uses a two-pass algorithm: mark exact matches first, then consume remaining solution-letter counts for present matches.
- Text processing uses Unicode grapheme clusters rather than code units.
- Accepted guesses and eligible solutions are different collections.
- Random selection can be seeded for deterministic tests.
- Mixed English/Punjabi accepts both English and romanized Punjabi guesses.
- Gurmukhi remains a separate mode.

## Security and privacy

- Do not embed credentials, secrets, or private keys.
- Do not store passwords because V2 has no accounts.
- Bundle only content that may safely be distributed publicly.
- Treat compiled mobile code and web assets as inspectable by a determined user.
- Introduce networking only through a reviewed HTTPS adapter if future scope requires it.
