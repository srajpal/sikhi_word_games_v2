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

Use JSON for canonical content and editorial review. For the current 39,004-record
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

The reproducible V1 import produced 38,510 accepted-guess records: 20,859 English and 17,651 Panjabi. Curated supplements currently bring the runtime total to 39,004. All V1 word and definition keys align and no duplicate stable IDs were found. Imported entries default to `solutionEligible: false` until curated.

The review queue currently contains two empty English definitions, eight Panjabi records without a valid Gurmukhi form, and six of those eight containing Gujarati rather than Gurmukhi script. See `reports/content/v1_import_report.md` for exact records.
