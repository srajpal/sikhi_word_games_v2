# Flutter application

This directory contains Sikhi Word Games V2, with three playable games and an
offline vocabulary browser. Start with the repository [README](../README.md)
for setup, validation, versioning, and itch.io release steps.

- [Architecture](../docs/architecture.md)
- [Testing strategy](../docs/testing_strategy.md)
- [Current work and release gaps](../TODO.md)
- [Dictionary review workflow](../docs/dictionary_review_tool.md)

Run Flutter and Dart commands from this directory. Generated content must be
rebuilt through the documented import tools, never edited by hand.

## Public playtest page copy

**Title:** Sikhi Word Games

**Short description:** Three word games in English, romanized Punjabi, and Gurmukhi.

Take your time with three ways to play:

- **Bujho: Guess the Word:** Find the hidden word using letter clues.
- **Khoj: Word Search:** Find six words running across, down, or diagonally.
- **Chardi Kala: Word Quest:** Read a clue and choose letters to grow a word garden.

Choose a language, four to six letters, and one of three themes. Use the
Dictionary to look up words and meanings. No account, ads, or payment is needed
to play. Unfinished games are saved in this browser.

This is **public playtest 1.3.0 (build 5)**. Words and meanings are still being
reviewed. Some vocabulary is uncommon or historical. Report confusing clues or
problems through **Share feedback** in the game library or the game page's
comments. The feedback link opens a public GitHub issue form and requires a
GitHub account; playing does not.

### Controls

- Bujho: use the on-screen keys or a physical keyboard. Enter submits a guess;
  Backspace removes the last visible letter.
- Khoj: drag from the first letter to the last. With a keyboard, move with arrow
  keys, choose each end with Enter or Space, and cancel with Escape. Words can
  run forward or backward.
- Word Quest: choose letters on screen or type letters on a physical keyboard.
  The lightbulb reveals a letter. The keyboard button switches between the
  smaller letter bank and all letters.
- Gurmukhi: use the on-screen keys. Pronunciation labels appear below the letters.
- Theme and feedback settings are in the game library. Each game's menu contains
  its help and settings.

### Known limits for the page

Browser storage can be cleared or restricted, and saved games are not shared
between devices. The first load needs a connection. Offline reload depends on
successful browser caching and the host's storage policy; do not advertise it
as guaranteed in the itch.io frame until the uploaded draft is verified.
Mobile browser testing is still pending. Typing Challenge is future work.

### Release artwork and credits

Use `reports/release/itch-cover-630x500.png` at the repository root for the cover.
The original editable artwork is in `branding/`. Rebuild it with
`node app/tool/create_brand_assets.cjs` from the root in a Node environment with
`sharp` installed. The small web icons are generated from the same mark.
Artwork uses letter tiles and a plant; sacred marks are not gameplay objects.

Keep the English WordNet, Mahan Kosh and bundled-font notices in the game and ZIP.
Their source links and licenses are listed in `THIRD_PARTY_NOTICES.txt`.
Add actual gameplay screenshots from the final package, not mockups.
