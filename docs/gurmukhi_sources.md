# Punjabi source and written-unit policy

## Current owner-approved snapshot

The October 9, 2026 owner-approved release from
`C:/dev/Projects/ChatGPT/sikhi_word_games_word_lists/release` supplies two
separate Punjabi masters: `punjabi/romanized/words.json` and
`punjabi/gurmukhi/words.json`. The owner approved every included word and its
selected definition. The app imports them unchanged rather than rerunning the
retired Mahan Kosh or Dictionary v2 editorial pipelines.

Both masters derive from Punjabi entries in English Wiktionary, extracted by
Wiktextract and distributed by Kaikki. Source metadata retains the September 2,
2026 dump and October 3 extraction, downloaded/prepared on October 9. The source
JSONL SHA-256 is
`8bbee081aa826ba360edeec75fd3cace1d0971b172569c33631cadcea5a250a2`.
The approved package manifest supplies hashes for the current masters; raw
source files and mutable upstream downloads are not runtime dependencies.

Preserve each chosen English gloss, source sense, native spelling, original
romanizations, tags and Wiktionary page/history links. Preserve the package's
CC BY-SA 4.0 attribution, modification statements and full license. Extractor
software licensing does not relicense the dictionary text. See
[definition sources](definition_sources.md) for import commands and notices.

## Separate scripts and authoritative units

Romanized Punjabi retains the approved scholarly diacritics. Do not convert it
to the earlier ASCII gameplay transliteration or drop letters/marks. A Roman
letter with attached diacritics is one written unit; `kh` is two units. Gurmukhi
uses a base letter with its marks and virama-linked subjoined letters as one
written unit. Source `letter_units` and `tile_count` are authoritative and checked
against the shared written-unit helper; generic Unicode grapheme counts may
differ for Gurmukhi conjuncts.

The Romanized master contains 2,991 words at 4/5/6 tiles: 658/1,354/979.
The Gurmukhi master contains 4,428 words at 2-8 tiles: 1,515/1,865/787/220/33/7/1.
These are overlapping vocabularies, not additive unique-meaning totals.
Bujho and Word Quest use the native 4/5/6-tile pools, including 33 six-tile
Gurmukhi words. Other applicable games can use shorter or longer source words.

Counterpart fields supply pronunciation aids or lookup metadata only. Native
spelling attached to a Romanized word does not add a Gurmukhi game word;
romanizations attached to a native word do not add a Romanized game word. Each
mode's own master governs lookup, guesses, targets and saved-target validation.

Do not impose frequency estimates, familiarity quotas, old source-quality holds
or another linguistic approval gate on this approved import. Integrity checks
verify bytes, structure, provenance retention and written units. Owner approval
of dictionaries does not extend to the generated letter-name pronunciation
previews, whose separate review status remains recorded in `TODO.md`.

## Historical sources and queues

The prior Mahan Kosh import used the multilingual dataset at commit
`fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6`, with CC BY 4.0 attribution. It
supported earlier native expansion and editorial proposals. Its queues and
review commands are retired release inputs, as are the October 8 v2 import's
4,026 dictionary records and 279 bounded everyday selections. Dated reports
remain historical evidence; they cannot expand, exclude or rewrite this release.

Earlier source investigations considered Punjabi University RCPLT, IndoWordNet,
DSAL, PanLex and other lookup sites. None is a replacement source for the current
approved snapshot merely because public lookup is available. Any future source
change belongs in a newly owner-approved release with its own preserved licenses
and manifest, followed by explicit import and applicable validation.
