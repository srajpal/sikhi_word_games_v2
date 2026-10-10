# Chardi Kala: Word Quest

## Product and visual contract

Word Quest is a clue-led, one-letter-at-a-time deduction game. Its secular paper
lantern provides the clear countdown of hangman without a person, injury or
punishment. One lit fold represents each remaining missed-letter allowance.
Incorrect letters dim a fold; correct and repeated letters leave the light alone.
The lantern stays intact. A completed word earns a small star in the lantern.

All colors and paper surfaces come from the shared Modern, Sikhi and Dark theme.
No sacred text or mark is a key, target, countdown, reward or mutable game object.
The static Sikhi library mark remains separate from game state.

## Round rules

1. Choose a solution-eligible, defined entry from English, Romanized Punjabi or
   Gurmukhi, using a 4-, 5- or 6-grapheme word. Random language only selects among
   these three modes. Latin and Gurmukhi input never mix within a round.
2. Normalize with the shared case/Gurmukhi comparison. A grapheme cluster is one
   tile; combining marks are never split. Correct guesses reveal every occurrence.
3. New rounds allow word length minus one distinct incorrect guesses: 3, 4 or 5
   misses for 4, 5 or 6 graphemes. The counter says "misses left" because correct
   guesses do not consume it. Repeated or invalid guesses are inert.
4. Hints are 0, 1 or 2 respectively. A hint reveals the first hidden grapheme and
   every occurrence without consuming a miss. A used hint cannot be reused.
5. Reveal every grapheme to win. Exhaust the miss allowance to enter the learning
   finish. Show the answer and definition in either case, with New word and,
   following a missed word, Try this word again. Do not use shame or injury copy.
6. Valid unfinished pre-1.11 saves retain their previous 5/6/7 allowance. Session
   schema 1 validates that legacy allowance; schema 2 validates 3/4/5. Re-saving
   an old round retains schema 1; replacing it starts the new rules. Arbitrary
   altered budgets, unsupported sizes and moves after completion remain rejected.

This is a deliberately tighter challenge than the previous forgiving rule. The
clue, optional easier letter bank and non-punitive finish provide support. New
rounds start with the full alphabet so choosing likely letters is the core skill.
Switching banks never changes guesses, misses or hints. Real playtesting
must assess whether familiar-word selection or a future optional easier mode is
needed; a passing rule test does not establish child suitability.

## Screen layout and consistency

- Use the shared two-line GameHeading: smaller English title above Chardi Kala.
  The shared text-only language/word-size line sits inside its paper label. There is no
  language icon or duplicate language pill in the body.
- The wrapping status row contains remaining misses, the Hint control and the
  easier/full alphabet toggle. Counts have text alternatives.
- Follow with a full, wrapping definition clue, grapheme tiles, the compact paper
  lantern, and the letter bank. At completion, show the result card. Expanded
  keyboards retain the lantern so deduction keeps its visible miss feedback.
- Shared feedback uses the same five-second paper toast as other games, floating
  below the toolbar without shifting the board or covering keyboard controls.
  It includes Dismiss; accessible navigation keeps it until dismissed. Terminal
  information is also durable in the result card.
- Game settings lives in the menu with language and 4/5/6 size. Applying begins a
  new word; cancelling preserves the current round. Global preferences belong
  on the dedicated Settings page, and statistics use a shared paper details page.

## Keyboards, responsiveness and accessibility

English and Romanized Punjabi share Latin input. English and Simple Punjabi
start with A-Z; the original Romanized view also retains its accented units.
Use easier letter bank offers every unique answer letter and up to six shuffled
distractors; Use full alphabet switches back. The selection persists with the
unfinished round through an optional `fullKeyboard` field; older saves default
to full. A fresh word or retry starts full. Hardware letters use the same handler;
modifiers/shortcuts are ignored.

Gurmukhi hardware input accepts exactly one letter or vowel sign per event,
excluding digits, ੴ, other signs and multi-code-point input. A vowel sign is
validated and saved like a letter guess; a sign absent from the answer's whole
tiles counts as a miss. Roman combining marks alone remain invalid and cost no
miss. These hardware limits do not split or restrict the on-screen marked tiles.

Gurmukhi's bank uses whole answer graphemes plus eligible-vocabulary distractors.
Keys and revealed tiles show shared Romanized pronunciation aids. The full bank
adds basic Gurmukhi letters and marked distractors while retaining complete
solution graphemes. Its keys are sorted, never displayed in answer order. It never
asks a child to assemble isolated marks. The terminal answer shows the source
Romanized spelling below the Gurmukhi word.

Keep the game column at maxWidth 620 and scroll vertically when a short viewport,
narrow width or enlarged text needs it. Use shared focus, button and tile tokens.
Announce hidden/revealed tile positions, used-key states, hint effects and numeric
lantern progress without relying on color alone. Respect app/system reduce motion
and haptic settings; no countdown or animation uses a sacred symbol.

## Verification and content boundaries

Engine/session tests cover 3/4/5 misses, 0/1/2 hints, repeated/invalid guesses,
Unicode graphemes, terminal replay rejection, save restoration and old budgets.
Widget/golden tests cover headings, status, clues, keyboard activation, the
lantern, shared feedback, 320px layouts and 200% text. Fresh browser, physical
screen-reader, audio and hosted/offline evidence remain separate in TODO.md.

Eligibility and source checks do not establish that every clue is familiar or
suitable for children. Definitions and exclusions remain owned by the curation
pipeline; never hand-edit generated/release assets or call machine decisions a
human review. Intended-audience and common-word work remain open in TODO.md.
