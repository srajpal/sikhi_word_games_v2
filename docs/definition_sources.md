# Dictionary v2 sources and maintenance

Dictionary v2 replaces the legacy English and Punjabi runtime banks. The V1
imports, WordNet reassessment files, Mahan Kosh queues and old overrides remain
an authoring archive. They do not feed the distributed dictionary. The ordinary
maintenance command is now one offline pipeline, with two small locked source
snapshots rather than tens of thousands of inherited editorial decisions.

## Licensed sources

English definitions come from **Simple English Wiktionary**, whose purpose is
clear definitions for readers learning English. The pinned Kaikki/Wiktextract
extraction is dated 2026-10-02 from the 2026-09-01 dump:
https://kaikki.org/simplewiktionary/rawdata.html
https://simple.wiktionary.org/wiki/Main_Page

Punjabi words and English glosses come from **English Wiktionary's Punjabi
entries**, via the Kaikki extraction dated 2026-10-03, dump 2026-09-02:
https://kaikki.org/dictionary/Punjabi/
See [Gurmukhi sources](gurmukhi_sources.md) for selection and transliteration.

Both data sources and our adapted dictionary are distributed under **CC BY-SA
4.0**, not CC BY 4.0. Every runtime entry keeps the originating Wiktionary page.
Its page history credits the contributors. Source snapshots retain exact senses;
generated English entries retain the original gloss, source snapshot hash,
sense index, part of speech, transformation method and frequency score. The
Punjabi answer decisions bind the exact original headword, sense ID and gloss.

The app bundles `THIRD_PARTY_NOTICES.txt` with contributor credits, extraction
credits, modification statements and license links. It is available offline and
is also copied into the web package. The adapted dictionary data may be shared
and adapted, including commercially, with attribution and ShareAlike. This data
license is distinct from the application code license.
https://creativecommons.org/licenses/by-sa/4.0/

English familiarity uses **wordfreq 3.1.1** by **Robyn Speer**, English large
word-list Zipf scores. Its data permit redistribution under CC BY-SA 4.0. The
full upstream attribution notice, including Google Books, Leeds, Wikipedia,
ParaCrawl, OpenSubtitles and freely available SUBTLEX authors' credits, is
retained in the bundled notice. See https://github.com/rspeer/wordfreq .
Frequency is a broad modern usage signal, not a child vocabulary certification.
It is neither current news frequency nor a Punjabi frequency estimate.

## Selection

`assets/content/curation/english_v2_policy.json` is the one English policy file.
Dictionary and accepted-guess inclusion use Zipf 4.0, roughly ten occurrences
per million words. Random answers use the higher Zipf 4.5 threshold, roughly
32 occurrences per million words. Both allow a small explicit list of familiar animals, fruit and household words that
fall below that threshold. VOTARY, BATHOS, ECLAT and specified inappropriate
words are explicitly excluded, independently of frequency.

English words contain 3-12 Latin letters. The importer considers the source's
first leading sense only. It never rescues a rejected ordinary adjective by
silently selecting an obscure noun sense. A bounded exception can select or
paraphrase a different sense only with its exact source gloss recorded in the
policy. These are source-checked AI decisions, not human review.

Mechanical cleanup removes introductory answer words and keeps a complete first
sentence. It screens sense labels, sensitive/stigmatizing text, references,
inflection-only definitions, source maintenance messages, vague definitions,
answer-revealing text and unclear/overlong clues. Failed entries stay out of the
English runtime dictionary. The deterministic report records the holds; they
are optional future improvements, not a mandatory manual-review backlog.

Punjabi imports retain filtered, source-backed dictionary/accepted-guess words;
only the bounded everyday source-checked decisions in
`assets/content/curation/punjabi_v2_answers.json` are random answers. No verified
redistributable Punjabi frequency dataset is currently bundled. Hindi or Urdu
frequency must not be substituted. Gurmukhi six-grapheme answers remain a small
pool and must not be expanded with rare compounds merely to satisfy a quota.

All current v2 records are explicitly `machineChecked`. Screening and frequency
cannot prove cultural, age, pronunciation or semantic suitability. A targeted
sample found cross-part-of-speech fallback, source maintenance text and vague
senses; those classes now have holds and regression tests. Only actual named
human review may be represented as community/editor approval.

## Routine workflow

Run from `app/`, with Python 3 and the configured Dart SDK:

```powershell
dart run tool/dictionary_v2.dart
dart run tool/dictionary_v2.dart --write
dart run tool/dictionary_v2.dart --check
dart run tool/audit_content.dart
```

The default previews candidates and reports existing release staleness.
`--write` builds both generated banks, builds the two compact release banks, and
runs the distribution audit. `--check` recomputes source-locked outputs and fails
on any changed generated data, report or runtime asset. Source snapshots are
committed under `tool/content/sources/`; routine runs and CI need no source
network access or third-party Python dependencies. The old
`vocabulary_pipeline.dart` command delegates to this workflow.

Never hand-edit generated or release assets. For a definition correction, change
its bounded source-linked policy/decision, then run `--write` and `--check`.
Reports are `reports/content/english_dictionary_v2.json` and
`reports/content/punjabi_dictionary_v2.json`. They report exact counts,
selection policy, exceptions and review limitations.

Focused checks:

```powershell
python -m unittest discover -s tool/tests -p test_english_dictionary_v2.py
flutter test test/core/content test/tool test/features/word_bridges/domain/word_bridges_content_test.dart --suppress-analytics
```

Run the repository's full Flutter checks and a release web build before handoff.
CI checks these exact v2 outputs; it no longer downloads or validates retired
WordNet/Mahan Kosh fingerprints as the current release pipeline.

## Deliberate source refresh

A refresh is separate from routine rebuilding. English source preparation uses
`tool/prepare_english_v2_sources.py --source <locked-raw-jsonl.gz>` with
`wordfreq==3.1.1`. It rejects a raw source whose SHA-256 differs from the pinned
snapshot. Review a new dump deliberately before updating that pin. Preparation
extracts only the applicable lemmas/senses and official wordfreq scores into an
attributed compressed snapshot, retaining the original dump hash and versions.
It does not redistribute examples, quotations, audio or unrelated etymologies.
The ordinary builder verifies the compressed snapshot against
`tool/content/english_v2_source_lock.json` before reading it. Punjabi uses its
separate source lock and exact-sense decisions.

Old tools remain for historical investigations only. The old archive audit is
available explicitly as `dart run tool/audit_content.dart --legacy-archive`.
Do not use legacy review UI or blanket Mahan Kosh/WordNet approval tools to
change the v2 release; their outputs are no longer release inputs.
