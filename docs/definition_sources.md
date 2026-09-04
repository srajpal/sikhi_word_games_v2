# Definition Sources and Editorial Policy

## Canonical English source

English definitions are reassessed against the **Open English WordNet 2025
base edition**, released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Use the base edition, not `2025+`: the base deliberately contains common nouns,
verbs, adjectives, and adverbs, while the plus edition adds proper names.

Download: <https://en-word.net/downloads>

## Selection policy

For each English word, collect every OEWN sense for its lowercase lemma. The
automated baseline takes the first neutral, standalone sense in OEWN's order,
preferring noun, verb, adjective, adjective satellite, then adverb. This keeps
ordinary lowercase words separate from title-cased name and title senses. The
baseline is marked `machineChecked`; editors may replace it with a more concise,
self-contained, ordinary modern clue when needed. Never display a sense labelled
or described as offensive, vulgar, a slur, derogatory, sexual, or otherwise
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
4. Run `dart run tool/apply_oewn_definitions.dart --write` to apply available
   OEWN baseline definitions to the curated runtime assets. Put later concise
   editorial revisions in `editorial_overrides.json` or
   `supplemental_entries.json`, retaining source provenance.
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
