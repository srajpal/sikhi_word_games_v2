# Chardi Kala: Word Quest — UX and implementation design

## Product idea

**Chardi Kala: Word Quest** is a gentle hidden-word game for children. A player
sees a short clue, chooses letters one at a time, and grows a small garden path
until the word is complete. It keeps the satisfying deduction loop of a
hangman-style game without a person, animal, broken object, or punishment being
shown. The default difficulty is forgiving: five, six, or seven unique
incorrect guesses for 4-, 5-, or 6-grapheme words, two free hints, and a
learning-focused end state when the word is not solved.

The visual metaphor is a **word garden**: correct letters light stepping stones
and add leaves/flowers to a path toward a garden gate. Incorrect guesses only
receive a calm “Try another letter” response; they never remove progress or
damage the scene. The garden, path, sun, leaves, and flowers are secular,
Sikhi-inspired warmth rather than depictions of sacred objects.

Reuse the existing `VocabularyRepository`, `WordPool`, `LanguageMode`, app
themes, settings, and Unicode grapheme utilities. The game rule engine should
remain pure Dart; this document describes the presentation contract around it.

## Respectful visual direction

- Use the existing tokens and theme choices. In the Sikhi theme, favor the
  current navy app bar (`#173A67`), saffron accent (`#E28A16`), warm cream
  background (`#FFF8E8`), and the existing rounded-card treatment. Modern and
  Dark use their existing color scheme and `GameThemeTokens`.
- Progress is represented by secular garden objects: a sunlit stone, leaf,
  flower, or gate. Correct answers may gently brighten or add these objects;
  nothing is broken, burned, crossed out, or made to fall.
- If the app theme includes a decorative Ik Onkar or other sacred mark, it is a
  static, non-interactive header accent only. It is never a tile, target,
  reward, countdown, miss marker, animation subject, or selectable item. Give
  it an accessible label when exposed to assistive technology and keep it out
  of mutable game state. Do not place sacred text, Guru imagery, or a Khanda in
  a board, keyboard, score, or “lives” meter.
- Do not use death, hanging, injury, fear, “you failed,” or spiritually loaded
  loss language. The experience should teach the answer even after the miss
  budget is used.
- Keep illustration secondary to the letters. Use high-contrast text and the
  same theme surfaces/borders as the existing Bujho: Guess the Word and Khoj: Word Search
  cards so the new game feels native to the app.

## Round rules

1. Select one curated, solution-eligible entry from the active `LanguageMode`
   and a 4-, 5-, or 6-grapheme length. A solution must have a short usable
   definition; if the source definition is long or a cross-reference, display a
   shortened/fallback clue rather than exposing the answer.
2. Normalize comparison using the same case and grapheme rules as Guess the
   Word. A revealed position is a Unicode grapheme cluster, not a code unit.
   Repeated graphemes reveal together.
3. A unique correct letter reveals every matching position, increments the
   positive path progress, and marks the key as “in the word.” A unique
   incorrect letter increments the miss count and marks the key as “try
   another.” Tapping an already-used key is inert and never consumes a miss.
4. The round is won when every solution grapheme is revealed. The round enters
   the learning finish state after its adaptive miss budget: five tries for a
   4-grapheme word, six for 5 graphemes, and seven for 6 graphemes. The latter
   is technically a terminal/lost state for persistence, but the UI must call
   it “Keep learning” or “The word is ready to discover,” never “You lost.”
5. Hints reveal information without consuming a miss. A round has two hints:
   **Reveal a letter** reveals the first unrevealed grapheme (all occurrences)
   and **Show a clue helper** adds a child-friendly sentence or category when
   available. Disable a used hint and announce what it did. If no helper text
   is available, the second hint reveals another grapheme instead.
6. On either terminal state, show the complete word, its concise definition,
   and a single positive action: **New word**. In Gurmukhi mode, show the
   curated Romanized spelling directly below the Gurmukhi answer. Also offer
   **Try this word again** in the Keep learning state so a child can practice
   it.

## Mobile-first fixed viewport and exact screen layout

Design the playable area against a fixed portrait baseline of **375 × 667
logical pixels**. This is a fixed gameplay composition, not a hard-coded device
size: wrap it in `SafeArea`, use `LayoutBuilder`, and constrain the content to
`maxWidth: 620` on tablets and desktop. There is no horizontal scrolling. On a
short viewport, only the body may scroll; the app bar and the current keyboard
action remain reachable.

From top to bottom, the round screen contains these sections:

1. **App bar (56 px minimum):** back button; title `Chardi Kala: Word Quest`;
   subtitle `<language> · <N> letters`; overflow menu with **New word**, **Game
   settings**, and **How to play**. Keep the app bar structure consistent with
   Bujho: Guess the Word.
2. **Quest status strip:** a compact `Round` label and a text counter such as
   `3 of 8 path steps` / `2 letters found`. This is text, not color alone.
3. **Clue card:** a labeled `Clue` heading and a one-line definition preview.
   If the definition does not fit one line, end it with an ellipsis and expose
   a small action that displays the complete concise definition in a floating
   message. The card must not include the answer or an answer-length spelling
   hint that makes Gurmukhi grapheme behavior unclear.
4. **Word card:** one large, centered tile per solution grapheme. Unknown tiles
   show an accessible “hidden letter” label and a neutral shape; revealed tiles
   show the grapheme. Preserve spaces only if the content policy later allows
   multiword entries; V1 of this mode is single-word only.
5. **Garden path panel:** a quiet row/arc of eight secular stones, sprouts, or flowers,
   with completed steps highlighted by `tokens.correct`. Include a text
   alternative (`3 of 8 steps`) and do not use a sacred symbol as the endpoint.
   When the full keyboard is open, replace the garden with a simple separator
   so the expanded keyboard remains usable in one phone viewport.
6. **Feedback line:** one live status line for `Letter found`, `Try another
   letter`, hint confirmation, or the positive terminal message. Use
   `Semantics(liveRegion: true)` where supported; do not rely on a transient
   SnackBar as the only feedback.
7. **Top status actions:** keep **Hint** beside the heart counter, with `1` or
   `2` remaining, followed by a compact open/close keyboard icon. Both stay
   reachable without consuming separate rows. Hide or disable them after
   completion while keeping the result card visible.
8. **Letter keyboard:** the language-specific keyboard described below. It is
   the final major section and must not be pushed below an unbounded
   illustration. The keyboard has visible focus, disabled-used states, and
   semantic labels for every key.
9. **Terminal result card (terminal states only):** `You found the word!` or
   `The word is ready to discover`; the answer; definition; and **New word** /
   **Try this word again**. This card replaces the feedback line but does not
   remove the clue or word board.

## Language and settings flow

- Use the same four modes as the other games: **English**, **Romanized
  Punjabi**, **Mixed English/Punjabi**, and **Gurmukhi**. English and Romanized Punjabi
  use Latin letters; Mixed English/Punjabi allows either eligible pool; Gurmukhi uses
  Punjabi in Gurmukhi. Never combine Latin and Gurmukhi input in one round.
- The overflow **Game settings** opens the existing dialog/bottom-sheet pattern
  with `Language` and `Word size` (4/5/6 letters). Show a short description for
  each language. Apply starts a new round only after the child taps **Apply**;
  cancel leaves the current round untouched. If a round is active, include a
  concise confirmation in the Apply action (`Start a new word?`) or make the
  new-round consequence explicit in the sheet.
- Remember only the active game snapshot/settings through the existing
  repository contracts. Restore the mode, length, solution, revealed keys,
  misses, and hint usage if the app is reopened. A malformed/unsupported
  snapshot starts a fresh round safely.
- Keep the global theme, haptic level, and Reduce motion controls in the
  existing app settings entry point. Do not add a game-local duplicate.

## Letter keyboard behavior

### Latin (English, Romanized Punjabi, Mixed English/Punjabi)

- Use the familiar three-row QWERTY layout already used by `GameKeyboard`, with
  uppercase labels. A tap immediately evaluates that one grapheme; there is no
  word entry or submit step. Hardware letters call the same handler. Ignore
  modifier shortcuts and non-Latin characters.
- Default **Easy** behavior shows a reduced bank: the distinct letters in the
  answer plus up to six common distractors, shuffled with a seeded round RNG.
  Include a visible **Show all letters** affordance for children who want the
  normal full A–Z keyboard. If a future difficulty setting is added, Easy uses
  the reduced bank and Standard uses the full alphabet. The reduced bank must
  never omit a solution letter. The same control changes to **Show simple
  letters** so the player can return to the reduced bank.
- A correct key uses the positive color/icon and remains disabled; an incorrect
  key uses a neutral muted state and remains disabled. Never communicate key
  status by color alone: add check/try-again icons and spoken labels.

### Gurmukhi

- Use an **answer-specific shuffled letter bank** made from the solution’s
  distinct, visible Unicode grapheme clusters, not code points and not isolated
  matras. For example, a tile may be `ਕਾ` as one selectable grapheme; do not
  require a child to assemble `ਕ` + `ਾ` to make a guess. This is both easier for
  children and safe for Unicode comparison.
- Add a small set of distinct distractor graphemes from eligible reviewed
  vocabulary only, capped so the bank stays readable. Shuffle deterministically
  per round and keep tiles at a consistent visual width. The expanded bank may
  continue vertically in the page’s scrollable body rather than shrinking keys.
- Include **Show all letters** / **Show simple letters** for Gurmukhi too. The
  expanded bank contains the standard Gurmukhi letters plus any whole solution
  grapheme clusters, preserving immediate whole-grapheme guessing.
- Show a short romanized pronunciation below each Gurmukhi key, such as
  `ਸਾ` / `Saa`. Revealed Gurmukhi answer tiles show the same learning aid;
  hidden tiles never expose it.
- The terminal answer card shows the curated Romanized spelling below the
  revealed Gurmukhi word.
- A tap immediately evaluates one whole grapheme. Used keys become disabled;
  there is no separate combining-mark state, IME composition, or code-unit
  deletion. A physical/IME input path may submit one grapheme at a time after
  normalization, but the on-screen whole-grapheme bank is the primary child
  path. Announce `Gurmukhi letter <grapheme>` rather than a Unicode name.
- The bank order should follow the answer-specific shuffle, not alphabetic
  order, so the target is not visually singled out. Never include `ੴ`, Khanda,
  Gurbani lines, or other sacred marks as distractors.

## Messaging, accessibility, and feedback

- Use encouraging, concrete copy: `Nice find!`, `That letter is not in this
  word. Try another one.`, `Hint used — the first letter is showing.`, `You
  found the word!`, and `The word is ready to discover. Let’s learn it
  together.` Avoid shame, streak pressure, or “wrong child” language.
- Show momentary gameplay feedback in an accessible floating message instead
  of reserving a permanent status row. Do not show an instructional message
  before the child has acted; the clue and keyboard make the first action clear.
- Every tile/key has a useful semantic label and state. The word board reads in
  order as `Letter 1, hidden` / `Letter 1, <grapheme>, revealed`; the garden
  panel reads its numeric progress. Do not expose decorative symbols twice.
- Maintain logical focus order: app bar → clue → word tiles → status → Hint →
  keyboard → terminal actions. Make keyboard focus visible. Support screen
  readers, keyboard navigation on web/desktop, 200% text scaling, and
  high-contrast themes without clipping or relying on color.
- Use at least 44 logical px of vertical hit area for keys and actions where the
  viewport permits. At the 320 px minimum width, preserve the existing compact
  three-row layout with generous spacing and readable labels; if needed, let
  the body scroll vertically rather than overlap controls.
- Respect `HapticFeedbackLevel`: key selection uses selection feedback, correct
  and completed word use medium/strong feedback according to the setting, and
  an incorrect key uses the configured gentle error feedback. `Off` performs no
  haptic call. Haptics are never the only success/error cue.
- Respect `reducedMotion`: replace garden growth, tile reveal, and terminal
  animations with immediate state changes or short opacity changes; do not
  animate decorative sacred marks. Honor system text scale and platform
  accessibility settings.

## Responsive rules

- At widths below 360 px, reduce outer padding to 12 px, keep one-column cards,
  use the compact keyboard, and allow vertical scroll. Do not make the word
  tiles smaller than the grapheme can render.
- From 360–599 px, use the 375 px composition with 16–20 px side padding. The
  clue, word card, path, and keyboard remain in the order above.
- At 600 px and above, center the fixed gameplay column at `maxWidth: 620`; do
  not stretch letters across the full tablet/desktop width. The garden may use
  a little more breathing room, but it cannot become the dominant element.
- When height is below 650 px, collapse decorative garden art to the path strip,
  reduce vertical gaps, and keep the keyboard/action row visible after a single
  scroll. On landscape, preserve the same reading order and permit vertical
  scrolling; do not create a second ruleset.

## Acceptance checklist

- [ ] Game Library presents `Chardi Kala: Word Quest` with a clear kid-friendly
      description and opens the new route.
- [ ] A round selects a reviewed 4–6 grapheme solution in all four language
      modes and persists/restores its state safely.
- [ ] Correct/repeated/incorrect letters follow the rules; the adaptive 5/6/7
      miss budget produces the positive learning finish with the answer and definition.
- [ ] Two non-punitive hints work, announce their effect, and cannot be reused.
- [ ] Latin Easy reduced bank plus `Show all letters` and Gurmukhi
      answer-specific whole-grapheme bank are deterministic and Unicode-safe.
- [ ] No mutable board state contains or damages sacred marks; all decorative
      marks are static and semantically handled.
- [ ] Screen sections, focus order, semantic labels, text scaling, haptics,
      Reduce motion, compact height, and 320 px width are verified in widget
      tests and a web/mobile preview.
- [ ] `flutter analyze`, affected unit/widget tests, and a release web build
      pass before the mode is considered complete.
