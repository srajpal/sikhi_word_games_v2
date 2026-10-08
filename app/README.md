# Flutter application

This directory contains Sikhi Word Games V2, with five playable games and an
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

**Publisher:** Khalsa Game Studio ([khalsagamestudio.com](https://khalsagamestudio.com/))

**Short description:** Five relaxed word and letter games with English, Punjabi and Gurmukhi.

Take your time with five ways to play:

- **Bujho: Guess the Word:** Find the hidden word using letter clues.
- **Khoj: Word Search:** Find six words running across, down, or diagonally.
- **Chardi Kala: Word Quest:** Read a clue and choose letters to grow a word garden.
- **Jodo: Word Bridges (ਜੋੜੋ):** Match four words with their English meanings, without a timer. Starter sets support English, Romanized Punjabi and Gurmukhi.
- **Akhar Pachhaan: Learn Letters:** Practice the names of 35 Gurmukhi letters in five-question rounds, with gentle retries and saved practice progress.

The word games offer language choices; Bujho, Khoj and Word Quest support four
to six letters. Choose Modern, Sikhi or Dark theme. Use the
Dictionary to look up words and meanings. No account, ads, or payment is needed
to play. Unfinished games are saved in this browser.

This is **public playtest 1.9.0 (build 17)**. Words and meanings are still being
reviewed. Some vocabulary is uncommon or historical. Report confusing clues or
problems through **Share feedback** in the game library or the game page's
comments. The feedback link opens a public GitHub issue form and requires a
GitHub account; playing does not.

Learn Letters includes computer-generated pronunciation previews for feedback.
They have not been approved by a fluent speaker as teaching audio. Words and
meanings are not yet comprehensively reviewed for children.

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
- Jodo: select a word and its matching meaning, in either order.
- Learn Letters: select a letter name, retry if needed, then choose Next.
  Use Hear after answering or in Letter progress to play the audio preview.
- Theme and feedback settings are in the game library. Each game's menu contains
  its help and settings.

### Known limits for the page

Browser storage can be cleared or restricted, and saved games are not shared
between devices. The first load needs a connection. Offline reload depends on
successful browser caching and the host's storage policy; do not advertise it
as guaranteed in the itch.io frame until the uploaded draft is verified.
Mobile browser and real screen-reader testing are still pending. Jodo currently
has two starter sets per language. Sound and celebration particles can be
disabled in App settings or the game menu.

### Khalsa Game Studio draft setup

An unpublished project is prepared under the existing `khalsagamestudio` account:
[draft editor](https://itch.io/game/edit/5023423) and
[owner preview](https://khalsagamestudio.itch.io/sikhi-word-games).
The existing Seva Jump project is unchanged. Settings: **Sikhi Word Games**,
kind **HTML**, **In development**, free access, and **Draft** visibility.

Upload `dist/sikhi-word-games-web-1.9.0+17.zip` and mark it playable in browser.
Use a 960 by 720 embedded viewport, click-to-play and the fullscreen button.
Leave Mobile Friendly off until actual mobile-browser testing passes.
Use the cover below; refresh gameplay screenshots from the current package
before uploading them because the existing screenshot set predates Learn Letters.

Before changing visibility to Public, test all five games and Dictionary in the
actual draft iframe, keyboard/focus, Hear audio, saved progress after reload,
Gurmukhi fonts and offline restart. Resolve the content/audio review gates in
`../TODO.md`. Preserve the previous ZIP for rollback. Draft preparation is not
public publication; visibility must remain Draft until release review completes.

Upload settings follow the [itch.io HTML5 guide](https://itch.io/docs/creators/html5).
The archive audit is recorded in `../reports/release/package_audit.json`.

### Release artwork and credits

Use `reports/release/itch-cover-630x500.png` at the repository root for the cover.
The original editable artwork is in `branding/`. Rebuild it with
`node app/tool/create_brand_assets.cjs` from the root in a Node environment with
`sharp` installed. The small web icons are generated from the same mark.
Artwork uses letter tiles and a plant; sacred marks are not gameplay objects.

Keep the English WordNet, Mahan Kosh and bundled-font notices in the game and ZIP.
Their source links and licenses are listed in `THIRD_PARTY_NOTICES.txt`.
Add actual gameplay screenshots from the final package, not mockups.



Version 1.9.0 adds Akhar Pachhaan: Learn Letters, with five-question letter-name recognition rounds, saved practice progress and 35 offline generated pronunciation previews. All five games support victory particles, a trophy banner and the original bundled chime. Use each game's Celebration settings or the home App settings for sound and particle controls. Reduce motion suppresses the visual celebration. Typing Challenge is no longer shown as an upcoming game.
