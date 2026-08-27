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

## Initial V1 import findings

The first reproducible import produced 38,510 accepted-guess records: 20,859 English and 17,651 Panjabi. All V1 word and definition keys align and no duplicate stable IDs were found. Imported entries default to `solutionEligible: false` until curated.

The review queue currently contains two empty English definitions, eight Panjabi records without a valid Gurmukhi form, and six of those eight containing Gujarati rather than Gurmukhi script. See `reports/content/v1_import_report.md` for exact records.
