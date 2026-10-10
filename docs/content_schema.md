# Sikhi Word Games V2 content schema

## Owner-approved release snapshot

The October 9, 2026 owner-approved release is the content boundary for candidate
1.13.0+24. Its authoring snapshot is `app/content/approved_release/`. Three native
JSON masters are copied unchanged into `app/assets/content/release/`:

- `english/words.json`
- `punjabi/romanized/words.json`
- `punjabi/gurmukhi/words.json`

Each master is an object with a `words` array, metadata and length counts. Each
word has one English `definition`, `word`, `part_of_speech`, `letter_units` and
`tile_count`, plus source-specific provenance. For example:

```json
{
  "word": "abbā",
  "letter_units": ["a", "b", "b", "ā"],
  "tile_count": 4,
  "definition": "father, dad",
  "part_of_speech": "noun",
  "gurmukhi_word": "ਅੱਬਾ",
  "gurmukhi_words": ["ਅੱਬਾ"]
}
```

Complete records retain original source senses, page/history links,
romanizations and tags. Runtime adapters construct game entries in memory; they
do not rewrite the JSON masters or definitions into a second release schema.
Shared display punctuation normalization preserves source wording and provenance.
English adapters retain the selected sense's supplied `tag_count` as nullable
`wordNetTagCount`, including through copies and entry serialization. English
game answers require a count of at least 3 through `AnswerEligibility`; missing
counts fail this answer-only gate. Dictionary rows and accepted guesses do not.
All supplied `romanizations` also survive decoding, copies and entry JSON
round-trips. Gurmukhi answer hygiene compares every alias, including its plain
form, against whole words in the definition. These remain counterpart metadata.

## Separate mode membership

English, Romanized Punjabi and Gurmukhi draw exclusively from their own master.
Counterpart spelling is lookup/presentation metadata, not permission to add a
word to another mode. A Romanized record's native counterpart cannot expand the
Gurmukhi pool, and a native record's Roman counterpart cannot expand Romanized
membership. Selection deduplicates each mode's own displayed spellings.

All imported words and selected definitions are owner approved for their mode.
The app does not apply retired frequency thresholds, everyday-answer subsets,
definition-quality holds or old curation queues. Game rules still select an
available size and a usable board/set; this is mechanical compatibility, not
editorial reapproval. Owner approval is not a claim of fresh independent
community review.

## Written units and coverage

Source `letter_units` and `tile_count` are authoritative. Integrity validation
checks that units reproduce the spelling, count matches units and the shared
written-unit helper agrees. Do not substitute bytes, code points or generic
`.characters.length` when it differs from source units. Each English letter
and Roman letter with attached diacritics is one unit; Roman `kh` occupies two.
A Gurmukhi base letter with marks and virama-linked subjoined letters occupies
one written unit.

The approved source manifest contains:

| Tiles | English | Romanized Punjabi | Gurmukhi |
| --- | ---: | ---: | ---: |
| 2 | unavailable | unavailable | 1,515 |
| 3 | unavailable | unavailable | 1,865 |
| 4 | 2,346 | 658 | 787 |
| 5 | 4,144 | 1,354 | 220 |
| 6 | 6,692 | 979 | 33 |
| 7 | unavailable | unavailable | 7 |
| 8 | unavailable | unavailable | 1 |
| Total | 13,182 | 2,991 | 4,428 |

Punjabi modes overlap in meaning; their totals are not a unique Punjabi word
count. Bujho and Word Quest retain 4/5/6-tile rounds. Khoj and Jodo use their
broader applicable mode bank. Six-tile Gurmukhi has 33 source words; describe
actual variety without importing other-mode words or imposing historical quotas.

After the October 9 mechanical answer-pool rule, dictionary/source counts above
are unchanged. With the English `tag_count >= 3` follow-up, current distinct
answer coverage is:

| Tiles | English | Romanized original | Romanized Simple | Gurmukhi |
| --- | ---: | ---: | ---: | ---: |
| 2 | 0 | 0 | 0 | 1,479 |
| 3 | 0 | 0 | 0 | 1,827 |
| 4 | 766 | 654 | 601 | 772 |
| 5 | 928 | 1,350 | 1,255 | 218 |
| 6 | 1,122 | 971 | 935 | 33 |
| 7 | 0 | 0 | 0 | 7 |
| 8 | 0 | 0 | 0 | 1 |
| Total | 2,816 | 2,975 | 2,791 | 4,337 |

Bujho and Word Quest use only the 4/5/6 rows. Khoj and Jodo use all displayed
rows. Shabad Banao uses the same rows except two-tile Gurmukhi is 1,465 (4,323
total), because 14 remaining repeated-identical-tile spellings cannot be scrambled.
Simple Romanized counts deduplicate spellings after folding marks; they do not
remove dictionary entries. Gurmukhi seven- and eight-tile pools contain fewer
than 20 answers (7 and 1) in Khoj, Jodo and Shabad Banao. Six-tile Gurmukhi
still has 33 answers in both spelling games. These are variety notes, not new
quotas. Reproduce coverage with the answer-coverage test in
`test/core/content/asset_vocabulary_repository_test.dart`.
The Romanization check finds 13 exact-spelling leaks and 87 with accent folding,
which covers granthī / "granthi". Two already fail other exclusions, leaving
85 additional exclusions and 4,337 native answers. Approved records stay intact.

## Import, distribution and checks

The release audit also fails on a small boundary-matched deny-list of crude
terms and vandalism phrases such as "your mom" in definitions, including
case/whitespace variants. Innocent substrings such as farther, sextant and
Sussex do not match. The guard reports dataset/word identity, including when
the supplied hashes and runtime bytes are otherwise valid. It never rewrites
approved definitions or removes Dictionary records. This regression check is
not exhaustive editorial verification; source changes still require a newly
owner-approved release.

From `app/`, import an approved release with
`dart run tool/build_release_content.dart --import-from <path> --write`.
Ordinary `--write` rebuilds from the local approved snapshot; `--check` verifies
integrity and exact reproduction. Follow with
`dart run tool/audit_release_content.dart` and applicable Flutter checks.
See [definition sources](definition_sources.md) for maintenance details.

The manifest binds source files to exact byte sizes and SHA-256 hashes. Keep
attribution and supplied WordNet, CC BY-SA 4.0 and filter license files with
runtime data. Source README, TXT exports, review notes, raw imports and editorial
queues remain authoring material. Only the three masters and required
attribution/licenses belong in runtime assets.

Prior `english_v2.json`/`punjabi_v2.json` banks and `vocabulary_4/5/6.json` shards
are obsolete release inputs. Dated reports are historical evidence, not current
counts, approval gates or build inputs.

## Runtime storage and saves

Read-only JSON remains appropriate for the offline app. Repository loads
coalesce and cache immutable entries; native decoding can use a compute isolate
and web decoding yields between banks and batches. No source project, database,
API key or network is required at runtime. Reconsider indexing with measured
loading or lookup evidence.

Saved targets validate against their current mode and written units. Unavailable
historical content recovers through existing fresh-round behavior; replacing
the dictionaries does not erase cumulative statistics. Counterpart lookup must
not validate an otherwise unavailable saved target in another mode.

The October 9 21:07 UTC release adds 655 English WordNet exception and
inflected forms, including MICE. It contains 20,601 records across all masters;
Punjabi files and licenses are unchanged. Source attribution and manifests are
imported with the release.

Simple Romanized Punjabi is an optional in-memory spelling view. Accented Latin
letters map to their plain base, with one output letter per source written unit
(for example ĀSĀN becomes ASAN). It preserves IDs, definitions, native metadata
and source bytes. Game pools deduplicate resulting spellings to avoid repeated
answers and ambiguous Jodo pairs. It adds no cross-mode words. New round saves
record the spelling view; absent markers mean the original view for legacy saves.
