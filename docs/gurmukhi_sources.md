# Native Gurmukhi word-source policy

## Clean Punjabi dictionary v2

The October 8, 2026 source review selected the [English Wiktionary Punjabi
extract published by Kaikki](https://kaikki.org/dictionary/Punjabi/index.html)
for a clean replacement dictionary. It offers ordinary modern words and English
glosses as well as uncommon and historical entries. The complete downloaded
snapshot had 10,668 part-of-speech records and 9,459 distinct forms across
Gurmukhi and Shahmukhi; 6,121 distinct forms were entirely Gurmukhi. These are
coverage counts, not approved-answer counts.

The snapshot was extracted October 3 from the September 2, 2026 English
Wiktionary dump. Its original 36,556,919-byte JSONL download has SHA-256
`8bbee081aa826ba360edeec75fd3cace1d0971b172569c33631cadcea5a250a2`.
The postprocessed per-language download is deprecated upstream, so the project
vendors a 579,775-byte compressed, stripped snapshot outside runtime assets.
It retains spellings, romanizations, part of speech, and sense IDs/glosses/tags;
examples, quotations, audio, etymologies, categories and other merged metadata
are excluded. The source lock verifies the compressed snapshot before importing.
The original raw Wiktextract download is a larger future migration option;
upstream mutable URLs are never silently refreshed.

[Wiktionary's copyright policy](https://en.wiktionary.org/wiki/Wiktionary:Copyrights)
licenses original entry text under **CC BY-SA 4.0** and GFDL. This project uses the
CC BY-SA 4.0 route. Retain the per-entry source page link, license notice, dump and
extraction dates, and selected sense identifier. Adapted definitions and this
derived dictionary remain under CC BY-SA 4.0, with the license and change notice
distributed alongside the app. The MIT license of Wiktextract covers its
extractor software; it does not relicense Wiktionary definitions. Separately
licensed quotations and media must not be imported merely because they appear
on Wiktionary.

Run from `app/`:

```powershell
dart run tool/build_punjabi_dictionary_v2.dart
dart run tool/build_punjabi_dictionary_v2.dart --write
dart run tool/build_punjabi_dictionary_v2.dart --check
```

The default command previews counts without writing. `--write` rebuilds
`assets/content/generated/punjabi_v2.json` and
`reports/content/punjabi_dictionary_v2.json` through the importer; do not edit
the generated dictionary by hand. The separate lock is
`tool/content/punjabi_v2_source_lock.json`. Everyday answer decisions live in
`assets/content/curation/punjabi_v2_answers.json`, binding each native word to
an exact source sense and gloss. A changed sense fails the build until checked.
Existing Mahan Kosh editorial decisions still use the legacy preview/write
workflow below; v2 selections do not rewrite or blanket-approve those decisions.

The import retains native Gurmukhi lemmas with one standalone English gloss,
known romanization notation and matching consonant order. It excludes
inflections, reference-only meanings, unsafe sense tags, malformed meanings,
selected adult/violent/stigmatizing text and sample-discovered uncertain
headwords. Holds are absent from the runtime dictionary as well as the answer
pool. Mechanical checks do not prove semantic or age suitability. Only a bounded
exact-sense curation decision enables a random answer. Decisions made in this
pass are source-checked AI editorial selections marked `machineChecked`; they
do not claim community or independent human Punjabi review.

The measured import has 4,026 dictionary entries and 279 bounded everyday answer
selections. Latin lengths 4/5/6 have 54/75/48 unique answer spellings; Gurmukhi
grapheme lengths 4/5/6 have 28/40/6. Six-grapheme Gurmukhi everyday vocabulary is
naturally sparse in this source; do not promote obscure political or technical
terms merely to fill a pool. The report is authoritative when curation changes.
Shorter native words still support dictionary lookup and games that permit them.

No verified Punjabi frequency dataset is bundled. [Wordfreq's supported
language list](https://github.com/rspeer/wordfreq#sources-and-supported-languages)
does not include Punjabi. Hindi or Urdu frequency scores must not be substituted.
Frequency and familiarity remain separate from source validity and approval.

## Other sources checked online

- [Punjabi University RCPLT](https://dic.learnpunjabi.org/) remains a useful
  authoritative cross-check. Its page carries a copyright notice without a
  verified bulk redistribution grant; public lookup access is not permission.
- [CFILT's resources](https://www.cfilt.iitb.ac.in/download_new.html) say their
  resources are freely available for research purposes only. IndoWordNet may
  improve linguistic verification, but this review did not establish an
  unrestricted Punjabi dictionary distribution license or ready English gloss
  download. Princeton English WordNet's license does not apply to IndoWordNet.
- The DSAL electronic editions of [Maya Singh's 1895 dictionary](https://dsal.uchicago.edu/dictionaries/singh/)
  and [Bashir/Kazmi's 2012 dictionary](https://dsal.uchicago.edu/dictionaries/bashir/)
  link to CC BY-NC-ND 2.0. Those electronic editions are not the default source
  for an adapted, generally redistributable app dictionary. The age of Maya
  Singh's original printed work does not by itself establish reuse rights for a
  particular modern electronic edition.
- [PanLex's current database license](https://panlex.org/license/) is
  CC BY-NC-SA 4.0. Old mirrors claiming CC0 are not evidence of the current
  database's terms. PanLex also provides translations rather than independently
  sufficient standalone English definitions for every Punjabi sense.
- [Punjabi App](https://punjabiapp.com/dictionary) provides useful public lookup
  and credits volunteers, but no verified bulk data reuse license was found.
  [Punjabi Sahit's project description](https://punjabisahit.com/update/modern-punjabi-dictionary/)
  describes a large merged dictionary including Apple and Punjabi University
  content and AI-generated enrichment, without a verified redistribution grant
  for each source. Neither site's size establishes licensed or reviewed content.
- Leipzig is a possible corpus-frequency research lead. Its current download
  and terms pages returned a bot challenge during this review, so no specific
  Punjabi archive or unrestricted frequency-data redistribution permission was
  verified. Do not invent a licensed frequency score from this lead.

## Legacy Mahan Kosh source

The prior expansion source is the [Mahan Kosh multilingual dataset](https://github.com/redroyals/mahan-kosh-multilingual), pinned for this project at commit `fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6`.

It packages the 1930 *Gurushabad Ratnakar Mahan Kosh* by Bhai Kahan Singh Nabha, English definitions based on the Punjabi University Patiala edition, and native Gurmukhi headwords. The repository publishes the compiled dataset under **CC BY 4.0**. If these records are shipped in the app, the attribution and license must remain in the app's credits and repository.

The Punjabi University RCPLT [online Punjabi dictionary](https://dic.learnpunjabi.org/) remains a useful authoritative cross-check. Its page carries a Punjabi University copyright notice, so it is a verification source unless reuse permission is obtained; it is not treated as a bulk-import source by default.

## Import policy

- Import native Gurmukhi headwords, not Romanized words padded to a target size.
- Count the displayed word using Unicode grapheme/akhar units. Four, five, and six are gameplay lengths, not Latin transliteration lengths.
- Keep the source ID, volume, page, repository, commit, and license in the candidate report.
- Require a clean Romanized form when adding an entry to the shared vocabulary schema. The shared phoneme-preserving converter rejects unknown notation instead of silently deleting it. A missing or broken Romanized form is held out of play, not invented.
- Preserve the source definition for review, then write a short, neutral, standalone game definition before approval.
- Reject or hold definite names, places, abbreviations, scripture quotations, inflection-only entries, cross-reference-only entries, and rude/curse terms.
- Ranking is only triage. It never changes `acceptedGuess` or `solutionEligible`.

## Reproducible command

Download `core.json` and `en.json` from the pinned source commit into temporary files outside the repository, then run:

```text
cd app
dart run tool/import_gurmukhi_source.dart `
  --core=../mahan-kosh-core.json `
  --english=../mahan-kosh-en.json `
  --commit=fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6
```

The importer writes `reports/content/gurmukhi_candidates.json` and
`reports/content/gurmukhi_candidates.md`. Those files are review queues; they
are not runtime content until editorial decisions are recorded and applied.

## Current Punjabi review

Use the locally pinned root files for the combined source and editorial pass:

```powershell
cd app
dart run tool/review_punjabi_content.dart
dart run tool/review_punjabi_content.dart --write
```

The first command previews changes; `--write` applies them. The report records
the exact Mahan Kosh source ID and sense index. Source-matched automatic
decisions and source-checked, owner-authorized editorial decisions are marked
`machineChecked`; this does not claim community or independent human review.
The compatibility wrapper uses the same review policy. Blanket approval of the
old queue is obsolete.

The importer and review pipeline accept actual four-, five-, and six-grapheme
Gurmukhi headwords. Latin spellings come from the phoneme-preserving helper or
an explicit reviewed override, and lengths are recalculated after an override.
Explicit exclusions remain protected unless a later per-entry decision reopens
them. Missing, unsafe, uncertain, reference-only, or malformed meanings remain
held. Familiarity and child suitability remain useful future curation passes;
they do not prevent applying decisions already authorized and recorded.
