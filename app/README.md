# Flutter application

This directory contains Sikhi Word Games V2, with six playable games and an
offline vocabulary browser. Start with the repository [README](../README.md)
for setup, validation, versioning, and itch.io release steps.

- [Architecture](../docs/architecture.md)
- [Testing strategy](../docs/testing_strategy.md)
- [Current work and release gaps](../TODO.md)

Run Flutter and Dart commands from this directory. Approved content must be
imported through `tool/build_release_content.dart`, never edited by hand.

## itch.io page copy

**Title:** Sikhi Word Games

**Publisher:** Khalsa Game Studio ([khalsagamestudio.com](https://khalsagamestudio.com/))

**Short description:** Six relaxed word and letter games in English, Romanized Punjabi and Gurmukhi.

### Six relaxed ways to play

Build words, discover Punjabi, and collect badges in an illustrated Paper & Play world.

- **Guess the Word / Bujho:** Find the hidden word with coloured letter clues. Your letters go straight into the grid.
- **Word Search / Khoj:** Find six hidden words across, down and diagonally, forwards or backwards.
- **Word Quest / Chardi Kala:** Read a clue and deduce the word from the full alphabet before your misses run out. An easier letter bank is also available.
- **Word Bridges / Jodo (ਜੋੜੋ):** Match four words with their meanings in a fresh randomized set.
- **Learn Letters / Akhar Pachhaan (ਅੱਖਰ ਪਛਾਣ):** Listen and find a Gurmukhi letter, or practice recognizing its name. Explore 35 letters in five-question rounds.
- **Word Scramble / Shabad Banao (ਸ਼ਬਦ ਬਣਾਓ):** Unscramble the tiles. Reveal the meaning as an optional hint. Tap or drag tiles both ways, or recall them all to start again.

### Your way to play

The word games offer **English, Romanized Punjabi and Gurmukhi**. Choose simple Romanized Punjabi or the original accented spelling in Settings. Gurmukhi tiles keep written letter clusters together and show pronunciation labels.

Choose **Modern, Sikhi or Dark**, explore the Dictionary, follow your Progress, and earn **60 achievement badges**. No account, ads or payment is needed. Games are untimed and unfinished rounds are saved in this browser.

### Playtest 1.18.4 (build 36)

This build includes the October 9 owner-approved vocabulary release: **20,601 Dictionary entries** across the three languages. Learn Letters pronunciation is computer-generated preview audio and still awaits fluent-speaker review.

### Controls

- Use on-screen tiles or a physical keyboard where supported. In Bujho, Enter submits and Backspace removes the last written unit.
- In Khoj, drag from the first letter to the last. Keyboard players can use arrow keys, Enter or Space for endpoints, and Escape to cancel.
- In Quest, choose letters and use hints when available. Switch to the easier bank from the game controls.
- In Jodo, choose a word and its meaning in either order.
- In Learn Letters, Hear repeats the prompt. Choose the matching letter or name, then continue.
- In Scramble, tap or drag tiles into and out of the word. Recall all tiles clears your arrangement; Hint reveals the meaning.

Game menus include help and options. Settings apply immediately, with separate controls for letter clicks, button clicks, sounds and celebrations.

### Saves and browser support

Progress stays in this browser and does not sync between devices. Clearing browser data removes saves. The first load needs a connection. Offline reload depends on completed caching and browser storage policy; it is not guaranteed inside the itch.io frame. Mobile-browser and screen-reader testing are still in progress.

### Feedback and credits

Use Share feedback in the game or email [khalsagamestudio.apps@gmail.com](mailto:khalsagamestudio.apps@gmail.com). Please include the game, language and what happened.

Vocabulary sources include Princeton WordNet 3.0 and Wiktionary. The game includes source attribution and full licenses, plus bundled Noto font notices. Code, original artwork, sounds and some text were developed with AI assistance.

Created by **Khalsa Game Studio**. Thank you for helping us test.

## Current itch.io public playtest

Updated October 10, 2026 in project **5023423**:
[editor](https://itch.io/game/edit/5023423) and
[public page](https://khalsagamestudio.itch.io/sikhi-word-games).
The existing Seva Jump project is unchanged. This is an HTML, In development,
free-access project with **Public** visibility, published October 10, 2026
after the owner's explicit request. The reloaded page shows PUBLISHED.

The playable ZIP is `dist/sikhi-word-games-web-1.18.4+36.zip`.
The previous 1.9.0+17 ZIP remains uploaded, hidden and non-playable for rollback.
The embed is 960 by 720, click-to-play, with a fullscreen button. Mobile Friendly
remains off pending physical mobile-browser checks. Screenshots use the visible
Sidebar layout; cream surfaces and teal links match the Paper & Play identity.

The actual uploaded Chromium iframe launched all six games and Dictionary.
Bujho accepted a physical-keyboard guess and restored it after a full page reload.
Quest opened with the full alphabet and retained all four lantern lights on a
correct guess. Jodo matched a pair; Scramble placed and recalled a tile with its
meaning hidden; the existing Learn Letters round survived the update and entered
the Stop audio state after Hear. Gurmukhi dictionary queries and fonts render.
Audio control state is not proof of speaker audibility or pronunciation quality.
itch.io emitted an unsupported desktop orientation-lock error during fullscreen,
but fullscreen and the games remained usable. Physical browsers, screen readers
and hosted offline restart remain separate open checks in `../TODO.md`.

## Release artwork and credits

Use `reports/release/itch-cover-630x500.png` at the repository root for the cover.
Editable artwork is in `branding/`; regenerate it with
`node app/tool/create_brand_assets.cjs` in a Node environment with `sharp`.
The approved mark pairs English S and Gurmukhi ਗ for Sikhi + Games.

The seven current real browser screenshots at the repository root are
`reports/release/library-current.jpg`, `bujho-current.jpg`, `khoj-current.jpg`,
`quest-current.jpg`, `jodo-current.jpg`, `letters-current.jpg` and
`scramble-current.jpg`. Bujho was captured in the uploaded fullscreen game;
the remaining captures use an isolated HTTP preview of the exact uploaded ZIP.
Older PNG screenshots are historical and must not be used for this release.

Preserve the three approved masters, their supplied attribution and full licenses
in `assets/content/release/`, including Princeton WordNet 3.0 and Wiktionary
CC BY-SA 4.0 notices, plus the Noto font notices in `THIRD_PARTY_NOTICES.txt`.
Do not substitute retired vocabulary provenance for the current release.
Archive integrity is recorded in `../reports/release/package_audit.json`;
actual browser evidence is recorded separately in `../reports/release/browser_qa.json`.
