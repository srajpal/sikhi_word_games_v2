# Native Gurmukhi word-source policy

## Candidate source

The first expansion source is the [Mahan Kosh multilingual dataset](https://github.com/redroyals/mahan-kosh-multilingual), pinned for this project at commit `fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6`.

It packages the 1930 *Gurushabad Ratnakar Mahan Kosh* by Bhai Kahan Singh Nabha, English definitions based on the Punjabi University Patiala edition, and native Gurmukhi headwords. The repository publishes the compiled dataset under **CC BY 4.0**. If these records are shipped in the app, the attribution and license must remain in the app's credits and repository.

The Punjabi University RCPLT [online Punjabi dictionary](https://dic.learnpunjabi.org/) remains a useful authoritative cross-check. Its page carries a Punjabi University copyright notice, so it is a verification source unless reuse permission is obtained; it is not treated as a bulk-import source by default.

## Import policy

- Import native Gurmukhi headwords, not Romanized words padded to a target size.
- Count the displayed word using Unicode grapheme/akhar units. Five and six are gameplay lengths, not Latin transliteration lengths.
- Keep the source ID, volume, page, repository, commit, and license in the candidate report.
- Require a clean Romanized form when adding an entry to the shared vocabulary schema. A missing Romanized form is a review flag, not a reason to invent one.
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
