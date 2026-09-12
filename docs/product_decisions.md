# Sikhi Word Games V2 — Product Decisions

## Confirmed scope

- Build V2 as a clean Flutter/Dart application rather than modifying V1 in place.
- Target Android, iPhone/iPad, and web from one codebase.
- Operate completely offline in the initial release.
- Provide the app for free with no ads or monetization initially.
- Do not include accounts, online leaderboards, or a backend dependency.
- Do not migrate V1 user settings, scores, or statistics.
- Begin with unlimited random Bujho: Guess the Word games.
- The playable collection includes Bujho: Guess the Word, Khoj: Word Search, and Chardi Kala: Word Quest, plus the Dictionary. A typing challenge remains future scope.

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
- Ship exactly three themes: Modern, Sikhi, and Dark. Sikhi is the default.
- Keep all three themes in the shared theme system without duplicating game screens.
- Use semantic design tokens and reusable themed components.
- Keep game rules independent of visual themes.
- Modern uses teal actions and light neutral surfaces. Sikhi uses navy actions,
  warm cream surfaces and restrained geometric decoration. Dark uses deep blue
  surfaces with pale blue actions. Keep readable sans-serif text in all three.
- Game previews and garden illustration colors belong in the shared theme
  components. Sacred marks remain static header decoration, never game pieces.
- Give Continue game the strongest emphasis when a saved game exists; otherwise
  emphasize New game. Keep options visually secondary.

## Hosting

- Cloudflare Pages is the leading candidate for static web previews and hosting.
- Prepare the playable web app for an itch.io public playtest. Publishing remains a separate release action; see README.md and TODO.md for gates.
- The final marketing-site relationship is intentionally undecided.
