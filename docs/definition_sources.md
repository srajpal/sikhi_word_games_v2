# Approved dictionary sources and maintenance

## Current content decision

On October 9, 2026, the owner approved all words and selected definitions in
`C:/dev/Projects/ChatGPT/sikhi_word_games_word_lists/release` for the app.
The latest 1.15.0+27 candidate imports the 21:07 UTC update, including 655
additional English inflections such as MICE, instead of rebuilding the earlier
Dictionary v2 selection. Source README screening limitations and seven wording
notes remain preserved provenance; they do not create an app review queue or
override the owner's approval. Do not reapply previous frequency thresholds,
quality filters, restricted everyday-answer lists or editorial holds.

The three modes use separate native JSON masters: `english/words.json`,
`punjabi/romanized/words.json` and `punjabi/gurmukhi/words.json`. Copy their bytes
unchanged, preserving each definition, spelling, source field and authoritative
written units. Counterpart spellings support presentation only and never add
membership to another mode. See [content schema](content_schema.md).

## Attribution and licenses

English data are **Princeton WordNet 3.0**, Copyright 2006 Princeton University,
under the supplied WordNet license. Preserve its copyright, full terms and
disclaimer with copies. This differs from the retired Open English WordNet 2025
and Simple English Wiktionary app imports.

Punjabi data in both scripts are **Wiktionary contributors**, extracted by
Tatu Ylonen/Wiktextract and distributed by Kaikki, under **CC BY-SA 4.0**.
Preserve page/history links, source metadata and modification notices; shared
adaptations remain subject to attribution and share-alike terms.

The source package also credits the **Shutterstock screening filter**, Copyright
2012-2020, under **CC BY 4.0**. The filter list itself is not runtime content.
Copy `ATTRIBUTION.txt` and the supplied license files unchanged:

- `licenses/WORDNET_LICENSE.txt`
- `licenses/CC_BY_SA_4_0_LICENSE.txt`
- `licenses/FILTER_CC_BY_4_0_LICENSE.txt`

Keep these notices with distributed masters and expose source credits offline.
Data licenses are distinct from the application-code license. Source metadata
documents upstream screening and adaptations; importing the approved masters
does not claim the app performed those reviews again.

## Import and ordinary rebuild

Run from `app/`:

```powershell
dart run tool/build_release_content.dart --import-from "C:/dev/Projects/ChatGPT/sikhi_word_games_word_lists/release" --write
dart run tool/build_release_content.dart --check
dart run tool/audit_release_content.dart
dart run tool/audit_content.dart
```

`--import-from` validates the release package and copies the approved snapshot to
`app/content/approved_release/` before rebuilding runtime assets. Later `--write`
uses that local snapshot; neither rebuilding nor checking requires the external
source directory or network access. `--check` checks exact hashes, counts,
spelling uniqueness, selected-definition structure, mode membership and written
units. It is an integrity audit, not editorial reapproval.

Never hand-edit the approved snapshot or runtime masters. A future vocabulary
change belongs in a newly owner-approved source release, followed by explicit
import, applicable tests and packaging checks. Manifest hashes describe exact
bytes, so text normalization must not silently alter imported masters. Internal
adapters may expose the game's model without rewriting the source.

## Retired workflows

V1 imports, WordNet reassessment, Mahan Kosh queues and the October 8 Dictionary
v2 source/frequency policies are historical authoring work. Their counts, holds,
machine-review labels and reports do not feed the current release. Do not run
old blanket-approval, transliteration conversion or source-sense selection tools
as ordinary maintenance. Dated milestones in `TODO.md` retain what was validated
at the time.

Owner approval is explicit for this imported snapshot. It is not a claim of
independent community review, nor approval of letter-pronunciation audio or
other content outside these dictionaries.

The optional Simple Romanized Punjabi view is an accent-free app adaptation by
Khalsa Game Studio. Original spellings, definitions, source IDs and links remain
in the approved masters; the app's shared dictionary attribution identifies this
adaptation and retains the supplied CC BY-SA 4.0 license and credits.
