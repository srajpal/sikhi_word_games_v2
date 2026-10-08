# Sikhi Word Games V2 — Content Schema

## Canonical editable record

```json
{
  "id": "panjabi_baag",
  "language": "panjabi",
  "latin": "BAAG",
  "gurmukhi": "ਬਾਗ",
  "definitions": {
    "en": ["Orchard"],
    "pa": []
  },
  "lengths": {"latin": 4, "gurmukhi": 2},
  "acceptedGuess": true,
  "solutionEligible": false,
  "reviewStatus": "unreviewed",
  "sources": []
}
```

This is the persisted import/supplemental/runtime shape. Curation overrides use
`id` plus partial fields such as `englishDefinition`, eligibility, spelling,
source and review method. Category/difficulty labels and per-mode eligibility
arrays are future design options, not fields consumed by the current runtime.
The release builder always recomputes grapheme lengths.

## Required validation

- IDs are stable and unique.
- Spellings are normalized to an agreed Unicode form.
- Runtime matching decomposes only the six canonically equivalent Gurmukhi
  nukta letters. ੜ (U+0A5C) stays distinct from ਡ਼: it has no Unicode
  decomposition. Old saved targets using the retired alias are not rewritten
  ambiguously; normal restore eligibility checks replace an invalid target.
- Calculated Latin and Gurmukhi grapheme lengths are stored only in generated output, not trusted from hand-edited data.
- Every curated solution is also an accepted guess for the same mode.
- Duplicate spellings within a mode are either merged or explicitly disambiguated.
- Definitions cannot contain malformed field separators inherited from V1 parsing.
- `reviewStatus` is explicit: `unreviewed`, `machineChecked`, `communityReviewed`, or `editorApproved`.
- Source entries contain enough information to locate the original reference.

## Generated artifacts

Human-editable source content may be transformed into compact, indexed application assets. Generated files are reproducible and must not be edited manually.

Editorial corrections and exclusions live in
`app/assets/content/curation/editorial_overrides.json`. Each override references a
stable imported ID and may replace its definition or Gurmukhi spelling, change
guess/solution eligibility, and advance its review status. This keeps explicit
editorial decisions separate from reproducible V1 imports.

Curated words that do not exist in V1 live in
`app/assets/content/curation/supplemental_entries.json`. They use the same
runtime record shape, retain their external source attribution, and are loaded
after generated imports. Stable IDs must remain unique across both sources.

Machine quarantine decisions live separately in
`app/assets/content/curation/vocabulary_holds.json`, maintained by
`dart run tool/vocabulary_pipeline.dart --write`. They contain stable IDs,
public-content fingerprints and reasons. Holds hide definitions and disable
solutions without changing accepted guesses or promoting review status. A stale
fingerprint fails building and requires a recheck. See `docs/definition_sources.md`
for preview, checking, source locking and the small semantic-review sample.

The four-letter English review queue cross-references Open English WordNet,
SCOWL, and modern usage frequency. Its numeric score only prioritizes human
review; it never grants editorial approval by itself. The reproducible JSON and
Markdown results live under `reports/content/four_letter_candidates.*`.

The generated dictionary audit is JSON so it can be filtered or imported into a
spreadsheet/review tool, with a short Markdown summary for humans.

## Runtime storage decision

Use JSON for canonical content and editorial review. For the current 47,093-record
offline dataset, prefer compact, sharded, indexed JSON runtime assets shared by
Android, iOS, and web. Do not introduce SQLite yet:

- mobile SQLite would require a separate web implementation or a WebAssembly
  database layer;
- the vocabulary is read-only and small enough to index in memory;
- JSON keeps imports, diffs, review, and deployment reproducible;
- measured size, parse time, and lookup performance should determine whether a
  database is justified later.

Reconsider SQLite or another embedded database if content grows substantially,
startup/parse measurements remain unacceptable after compaction, or future games
need complex relational queries.

## Initial V1 import findings

The reproducible V1 import produced 38,510 accepted-guess records: 20,859 English and 17,651 Punjabi. Curated supplements currently bring the canonical total to 47,093 records. The October 7 recheck keeps all 45,416 accepted guesses, 14,689 answer records and 16,739 visible definitions; 30,354 definitions are hidden, including 17 fresh holds. All V1 word and definition keys align and no duplicate stable IDs were found in the original import. Imported entries default to `solutionEligible: false` until a source-matched or explicit editorial decision makes them playable.

The authoring-archive audit is intentionally broader than the release audit and
can contain empty, malformed, long, reference-only, or duplicate records that
are held from play. See `reports/content/dictionary_audit.md` for the latest raw
archive flags and `reports/content/v1_import_report.md` for the original import
findings. Those flags must not be reported as defects in the sanitized release
assets unless the release audit also finds them.

## Measured release coverage (2026-10-07)

After source filtering and the release-QA exclusions, the release-content audit
produced these unique Bujho answer counts using the actual bundled assets.

| Mode | 4 | 5 | 6 |
| --- | ---: | ---: | ---: |
| English | 1,712 | 2,563 | 4,028 |
| Romanized Punjabi | 990 | 1,378 | 1,106 |
| Mixed Latin | 2,631 | 3,932 | 5,126 |
| Gurmukhi | 337 | 2,346 | 533 |

Regression checks require every mode and length to retain at least 300 unique
Bujho answers and 250 Word Quest clues. Counts above are unique spellings; the
audit reports raw records separately because aliases can share a spelling.
Runtime selection deduplicates the actual spelling shown to the player. Khoj draws only accepted, answer-eligible records with a
distributable definition. These counts establish coverage, not everyday
usefulness, age suitability, or source accuracy. Authoring files preserve raw
definitions, while the bundled release shards omit unclear legacy definition
text. `displayDefinition` normalizes long dashes and Unicode ellipsis.
