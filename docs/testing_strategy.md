# Sikhi Word Games V2 — Testing Strategy

## Fast feedback loop

- Pure Dart unit tests cover game rules and content transformations.
- Flutter widget tests cover interaction, semantics, keyboard behavior, and responsive layouts.
- Golden tests protect the Modern and Sketch visual systems.
- Integration tests cover representative complete games and persistence restoration.
- Web previews provide human review on phones, tablets, and desktop browsers.

## Required engine cases

- Exact, present, and absent matches.
- Repeated letters in the guess, solution, or both.
- Four-, five-, and six-grapheme games.
- English, romanized Punjabi, Mixed English/Punjabi, and Gurmukhi filters.
- Invalid guesses and accepted-but-not-solution vocabulary.
- Seeded random selection and non-repetition policy.
- Winning, exhausting guesses, statistics, and serialization round trips.
- Gurmukhi grapheme entry, deletion, comparison, and restoration.

## Quality gates

Before a milestone is considered complete:

1. Format changed Dart files.
2. Run static analysis with no unresolved findings.
3. Run all unit and content tests.
4. Run affected widget and golden tests.
5. Build the affected target in release mode when platform configuration changes.
