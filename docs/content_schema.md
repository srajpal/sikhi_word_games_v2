# Sikhi Word Games V2 content schema

## Dictionary v2

The runtime dictionary consists of two compact, generated JSON banks:

- `app/assets/content/release/english_v2.json`
- `app/assets/content/release/punjabi_v2.json`

They contain the same `VocabularyEntry` record shape used by the game engines:

```json
{
  "id": "en_v2_apple",
  "language": "english",
  "latin": "APPLE",
  "gurmukhi": null,
  "definitions": {"en": ["A sweet, red, yellow or green fruit."], "pa": []},
  "lengths": {"latin": 5, "gurmukhi": null},
  "acceptedGuess": true,
  "solutionEligible": true,
  "reviewStatus": "machineChecked",
  "sources": ["Simple English Wiktionary contributors (CC BY-SA 4.0); https://simple.wiktionary.org/wiki/apple"]
}
```

Punjabi IDs begin `panjabi_v2_` and encode the native source headword. English
IDs begin `en_v2_`. ID-based saved targets cannot silently resolve to a new dictionary entry.
Game restore validation rejects unavailable content and creates a fresh round;
cumulative statistics remain in their existing storage keys. Bujho and Khoj
snapshots store spellings, so still-eligible words can resume after current
spelling/answer validation; changing entry IDs alone does not erase these saves.

`acceptedGuess` and `solutionEligible` are independent. Punjabi has more
source-backed dictionary/guess words than bounded everyday answers. Every answer
must be an accepted guess with a distributable standalone definition. The only
review statuses are `unreviewed`, `machineChecked`, `communityReviewed`, and
`editorApproved`; source-checked agent decisions use `machineChecked`.

## Generation and editorial inputs

The English importer reads a hashed, attributed source snapshot plus
`assets/content/curation/english_v2_policy.json`. The Punjabi importer reads its
own hashed snapshot plus `assets/content/curation/punjabi_v2_answers.json`.
English source evidence is retained on authoring records under `evidence`:
original gloss, part of speech, sense index, Zipf score, source version/hash and
transformation method. The compact release builder removes that authoring-only
field while retaining per-entry source URLs. Punjabi curation binds the exact
headword, sense ID and original gloss.

The generated authoring banks are `generated/english_v2.json` and
`generated/punjabi_v2.json`. No inherited V1 record, old editorial override,
starter list or legacy hold can enter a v2 release. Legacy authoring files remain
an archive. Only the two compact release banks and third-party notice are
bundled. The builder removes the retired release `vocabulary_4/5/6.json` files.

Use `dart run tool/dictionary_v2.dart --write`, followed by `--check`, from
`app/`. `build_release_content.dart --write` remains the only writer of runtime
assets; `audit_release_content.dart` checks what is actually distributed. See
[definition sources](definition_sources.md) for the complete routine and source
refresh policy.

## Validation and game lengths

IDs and mode spellings are normalized/deduplicated, and both Latin and Gurmukhi
lengths are recomputed from Unicode grapheme clusters. Runtime matching decomposes
only the six canonically equivalent Gurmukhi nukta letters. ੜ remains distinct
from ਡ਼ because it has no Unicode decomposition.

English v2 supports 3-12 letters. Bujho and Word Quest apply their existing
4/5/6-grapheme filters. Khoj and Jodo draw from their broader eligible pools,
with Khoj limiting words to the available grid. A source-backed longer word is
not truncated to fit a fixed word-length bank.

The shared source policy recognizes Wiktionary's **CC BY-SA 4.0** attribution,
distinct from the retired sources' CC BY 4.0 licenses. The full offline notice
retains contributor/source credits, modification statements and license links.
Every current release definition has a recognized source; no blank legacy
placeholder records are distributed. Player-facing punctuation normalization
happens through `displayDefinition`, preserving source evidence.

The current coverage is reported by the deterministic v2 reports and release
audit. The higher English answer-frequency threshold and everyday-sense holds
currently retain 221/191/109 answers at 4/5/6 letters (809 across all lengths),
from 2,443 dictionary words. Punjabi
coverage is intentionally smaller, especially six-grapheme Gurmukhi. Tests
verify honest usable coverage and reject unavailable pools instead of treating
old 300-answer quotas as approval criteria.

## Runtime storage

Read-only JSON remains appropriate for the offline dictionary across Android,
iOS and web. Native decoding runs in a compute isolate; web decoding yields
between language banks and every 250 records. Repository loads coalesce and
cache immutable entries. No database, API key or runtime network is required.
Reconsider indexing or an embedded database only with measured evidence that
loading or lookups need it.
