# Sikhi Word Games V2 — Product Decisions

## Confirmed scope

- Build V2 as a clean Flutter/Dart application rather than modifying V1 in place.
- Target Android, iPhone/iPad, and web from one codebase.
- Operate completely offline in the initial release.
- Provide the app for free with no ads or monetization initially.
- Do not include accounts, online leaderboards, or a backend dependency.
- Do not migrate V1 user settings, scores, or statistics.
- Begin with unlimited random Bujho: Guess the Word games.
- Add Khoj: Word Search, Hangman or a themed equivalent, and a typing challenge later.

## Language modes

- English uses Latin script.
- Romanized Punjabi uses Latin script.
- English and romanized Punjabi share one on-screen Latin keyboard.
- Mixed English/Punjabi selects English or romanized Punjabi solutions and accepts valid guesses from both pools.
- Gurmukhi is a separate mode with a purpose-built on-screen keyboard.
- Every Gurmukhi on-screen keyboard shows a short romanized pronunciation under
  each key and uses the shared pronunciation/label components.
- Gurmukhi word length is measured in user-visible Unicode grapheme clusters.
- Do not combine Latin and Gurmukhi guesses in one game because their keyboards and length rules differ.

## Vocabulary policy

- Maintain a broad accepted-guess collection.
- Maintain a smaller curated solution collection.
- A word may be accepted as a guess without being eligible as a solution.
- Imported or researched content must retain its source and review status.
- Unreviewed vocabulary must not silently enter the curated solution pool.

## Design policy

- Players choose their active theme.
- Ship Modern and Sketch themes first.
- Allow future themes, including a Sikhi-inspired theme, without duplicating game screens.
- Use semantic design tokens and reusable themed components.
- Keep game rules independent of visual themes.

## Hosting

- Cloudflare Pages is the leading candidate for static web previews and hosting.
- The playable web app may eventually live separately from the marketing website, including possible itch.io distribution.
- The final marketing-site relationship is intentionally undecided.
