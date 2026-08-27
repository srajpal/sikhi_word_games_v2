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

## Guess the Word rules

- Evaluation uses a two-pass algorithm: mark exact matches first, then consume remaining solution-letter counts for present matches.
- Text processing uses Unicode grapheme clusters rather than code units.
- Accepted guesses and eligible solutions are different collections.
- Random selection can be seeded for deterministic tests.
- Mixed Latin accepts both English and romanized Panjabi guesses.
- Gurmukhi remains a separate mode.

## Security and privacy

- Do not embed credentials, secrets, or private keys.
- Do not store passwords because V2 has no accounts.
- Bundle only content that may safely be distributed publicly.
- Treat compiled mobile code and web assets as inspectable by a determined user.
- Introduce networking only through a reviewed HTTPS adapter if future scope requires it.

