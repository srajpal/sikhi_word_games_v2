# Definition Sources and Editorial Policy

## Canonical English source

English definitions are reassessed against the **Open English WordNet 2025
base edition**, released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Use the base edition, not `2025+`: the base deliberately contains common nouns,
verbs, adjectives, and adverbs, while the plus edition adds proper names.

Download: <https://en-word.net/downloads>

## Selection policy

For each English word, collect every OEWN sense and select a concise,
self-contained, ordinary modern sense. Never display a sense labelled or
described as offensive, vulgar, a slur, derogatory, sexual, or otherwise
unsuitable for the game. A word remains eligible when it has an ordinary,
neutral sense; only the unsafe sense is excluded.

Keep answer eligibility independent from dictionary availability. Uncommon,
technical, regional, or archaic words can remain accepted guesses; they do not
become rejected merely because they are not ideal answers.

## Workflow

1. Download and unpack the OEWN JSON edition outside the app assets.
2. Run:

   ```text
   dart run tool/reassess_english_definitions.dart --source <unpacked-oewn-json-folder>
   ```

3. Review `reports/content/english_definition_reassessment.json`.
4. Put final concise definitions in `editorial_overrides.json` or
   `supplemental_entries.json`, with source provenance.
5. Run `dart run tool/audit_content.dart`, then Flutter analysis and tests.

## Other sources

Merriam-Webster is appropriate for manual editorial verification but is not a
bundled runtime source: its API is query-based and licensed. Wiktionary-derived
data is a coverage fallback only, since its CC BY-SA/GFDL terms require separate
attribution and licensing review.

## Attribution

Release builds using OEWN-derived definitions must include a visible notice:

> English definition data adapted from Open English WordNet 2025, licensed
> CC BY 4.0.
