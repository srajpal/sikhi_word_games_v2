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
  "categories": ["nature", "places"],
  "difficulty": 1,
  "acceptedGuessModes": ["romanized", "gurmukhi", "mixedLatin"],
  "solutionModes": ["romanized", "gurmukhi"],
  "reviewStatus": "unreviewed",
  "sources": []
}
```

## Required validation

- IDs are stable and unique.
- Spellings are normalized to an agreed Unicode form.
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
guess/solution eligibility, and advance its review status. This keeps human
decisions separate from reproducible V1 imports.

Editor-approved words that do not exist in V1 live in
`app/assets/content/curation/supplemental_entries.json`. They use the same
runtime record shape, retain their external source attribution, and are loaded
after generated imports. Stable IDs must remain unique across both sources.

The four-letter English review queue cross-references Open English WordNet,
SCOWL, and modern usage frequency. Its numeric score only prioritizes human
review; it never grants editorial approval by itself. The reproducible JSON and
Markdown results live under `reports/content/four_letter_candidates.*`.

The generated dictionary audit is JSON so it can be filtered or imported into a
spreadsheet/review tool, with a short Markdown summary for humans.

## Runtime storage decision

Use JSON for canonical content and editorial review. For the current 46,995-record
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

The reproducible V1 import produced 38,510 accepted-guess records: 20,859 English and 17,651 Punjabi. Curated supplements currently bring the authoring total to 46,995 records. The sanitized release assets retain 46,989 accepted guesses and 14,892 sourced standalone answer records. All V1 word and definition keys align and no duplicate stable IDs were found in the original import. Imported entries default to `solutionEligible: false` until curated.

The current combined runtime audit contains two empty definitions, eight Punjabi records without a valid Gurmukhi form, and 16 duplicate-spelling flags. It also contains 2,180 definitions longer than 220 characters and 3,240 definitions that start as cross-references or inflected-form references. See `reports/content/dictionary_audit.md` for current counts and `reports/content/v1_import_report.md` for the original import findings.

## Measured release coverage (2026-09-12)

After source filtering and the release-QA exclusions, the release-content audit
produced these Bujho answer counts using the actual bundled assets.

| Mode | 4 | 5 | 6 |
| --- | ---: | ---: | ---: |
| English | 1,713 | 2,567 | 4,030 |
| Romanized Punjabi | 7 | 57 | 250 |
| Mixed Latin | 1,720 | 2,624 | 4,280 |
| Gurmukhi | 9 | 5,070 | 1,503 |

A regression check requires every mode and length to support at least six Bujho
answers and a nonempty Word Quest clue pool. Khoj draws only records with a
distributable definition. These counts establish coverage, not everyday
usefulness, age suitability, or source accuracy. Authoring files preserve raw
definitions, while the bundled release shards omit unclear legacy definition
text. `displayDefinition` normalizes long dashes and Unicode ellipsis.
