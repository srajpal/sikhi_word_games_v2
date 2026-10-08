# Definition Sources and Editorial Policy

## Canonical English source

English definitions are reassessed against the **Open English WordNet 2025
base edition**, released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Use the base edition, not `2025+`: the base deliberately contains common nouns,
verbs, adjectives, and adverbs, while the plus edition adds proper names.

Download: <https://en-word.net/downloads>

## Selection policy

For each English word, collect every OEWN sense for its lowercase lemma. The
automated baseline takes the first neutral, standalone sense in OEWN's order,
preferring noun, verb, adjective, adjective satellite, then adverb. This keeps
ordinary lowercase words separate from title-cased name and title senses. The
baseline is marked `machineChecked`; editors may replace it with a more concise,
self-contained, ordinary modern clue when needed. Never display a sense labelled
or described as offensive, vulgar, a slur, derogatory, sexual, or otherwise
unsuitable for the game. A word remains eligible when it has an ordinary,
neutral sense; only the unsafe sense is excluded.

Keep answer eligibility independent from dictionary availability. Uncommon,
technical, regional, or archaic words can remain accepted guesses; they do not
become rejected merely because they are not ideal answers.

## Routine workflow: one pipeline

Run from `app/`. Fetch the pinned source cache once (or on a fresh checkout):

```powershell
python tool/fetch_vocabulary_sources.py
dart run tool/vocabulary_pipeline.dart
dart run tool/vocabulary_pipeline.dart --write
dart run tool/vocabulary_pipeline.dart --check
```

The first Dart command previews the effective vocabulary, including overrides,
without changing curation or runtime assets. `--write` recomputes that preview,
checks projected unique-answer/clue floors and the actual Jodo deck provider,
writes machine holds, rebuilds release assets through the release builder and
runs the distribution audit. `--check` fails on stale reports, holds or release
assets. CI fetches the same locked bytes and runs `--check`; routine rechecks are
offline once the cache is present. Downloads and extracted files are verified
against `tool/content/source_lock.json`. Source updates require an intentional
lock update and full recheck; no source is silently upgraded.

The deterministic report is `reports/content/vocabulary_recheck.json`. It has
input hashes, exact-source counts, projected pools, grouped exceptions, licensed
English alternative senses and a semantic sample of up to 20 unique entries per
source stratum. Input hashes normalize Git line endings; source hashes verify raw
bytes. It examines every effective record but concentrates the review queue on
visible definitions. Already hidden archive records stay held rather than
creating tens of thousands of mandatory manual checks.

English verification requires the current definition to be an exact sense of
the lowercase OEWN lemma, not merely a source label. Punjabi source-only text
requires its exact headword, source ID and sense index after the shared cleanup.
Original Punjabi paraphrases require a valid pinned headword/sense link; that is
evidence of provenance, not proof of semantic equivalence or pronunciation.
Reference-only, corrupt, overlong and selected sensitive/stigmatizing text is
quarantined. The conservative risk list is incomplete and can overflag neutral
contexts; it does not certify child suitability.

`assets/content/curation/vocabulary_holds.json` is a separate generated decision
layer. Each hold binds an ID to its public spelling, definition and attribution
fingerprint. The release builder hides the definition and disables answers while
preserving accepted guesses, IDs, source records, previous editorial exclusions
and review status. A changed held record fails release building until rechecked.
Correct a meaning in the normal curation layer, then rerun the pipeline. A hold
clears only when the new effective record passes all checks; that never overrides
a separate explicit answer exclusion. No command in this routine workflow picks
an alternative sense or approves a new answer automatically.

## Focused improvement and human verification

1. Leave uncertain content held. Restoring all archive words is optional.
2. Resolve missing Punjabi source links and current active-answer exceptions
   first. Choose an exact supported ordinary sense, or write a checked original
   meaning with retained evidence. Alternative OEWN senses are suggestions, not
   decisions; the first sense is not automatically the most familiar meaning.
3. Inspect the deterministic sample for meaning, modern usage, culture and
   pronunciation, especially the editorial paraphrases. Record the actual
   reviewer/method. A sample failure triggers a targeted class recheck and a
   regression or rule before increasing sample size. Passing a sample is not
   certification of every word.
4. Establish intended-audience and familiarity criteria before expanding answers.
   Automate ranking and mechanical checks, then use bounded common-word batches
   for ambiguous senses and linguistic judgments. Pool quotas never grant approval.
5. Preview Punjabi source-backed changes with `review_punjabi_content.dart`, use
   `--write` only for checked decisions, and rerun this pipeline. Run the archive
   audit plus applicable Flutter validation before handoff.

This replaces the old bulk English baseline sequence for routine maintenance.
The following tools remain available for deliberate imports and investigations;
their historical reports are not the current effective-content review queue.

## Legacy import and investigation tools

Do not rerun `apply_oewn_definitions.dart` as general cleanup: its baseline
selection can replace a deliberate sense choice. Use the fresh pipeline's
specific exceptions and edit bounded curation decisions instead.

1. Download and unpack the OEWN JSON edition outside the app assets.
2. Run:

   ```text
   dart run tool/reassess_english_definitions.dart --source <unpacked-oewn-json-folder>
   ```

3. Review `reports/content/english_definition_reassessment.json`.
4. Run `dart run tool/apply_oewn_definitions.dart --write` to apply available
   OEWN baseline definitions to the curated runtime assets. Put later concise
   editorial revisions in `editorial_overrides.json` or
   `supplemental_entries.json`, retaining source provenance.
5. Run `dart run tool/audit_content.dart`, then Flutter analysis and tests.

For a bounded second pass over remaining English definition differences, run
`dart run tool/triage_remaining_content.dart`. The command writes JSON and
Markdown dry-run reports. It treats Spark proposals as review signals, never as
definition sources. Generic OEWN differences always remain manual-review
candidates. To apply only corrections explicitly recorded in the tool after
review, use `dart run tool/triage_remaining_content.dart --write --limit
<count>`. Writing never promotes a guess-only entry to an answer and records
each applied definition as `machineChecked` with its OEWN license source.

The September 2026 bounded pass selected clearer OEWN senses for GIVE, TAKE,
WANT, and STUD. LUST and STUD remain accepted guesses but are no longer random
answers. Five changes were applied and the next dry run reported no pending
verified corrections. The generated report retains those five records as
verified current decisions. This report compares changed OEWN candidates only;
it is not evidence that unchanged definitions or all remaining words were
reviewed.

## Limits of automatic approval

Automation can verify IDs, scripts, lengths, duplicate state, source licenses,
definition structure, and whether an already reviewed decision was applied. It
can safely route entries with missing or ambiguous evidence to guess-only or
manual review. It cannot establish that every sense is culturally appropriate,
age-appropriate, current, or the most useful meaning. Frequency, word-list
membership, and the absence of a flagged term are ranking signals only. They do
not approve an answer. New random-answer approvals still require a licensed
standalone meaning plus an explicit reviewed decision.

For Punjabi content, `dart run tool/review_punjabi_content.dart` previews the
current source-matched and explicit editorial decisions. Add `--write` to apply
them. The command reads the locally pinned `mahan-kosh-core.json` and
`mahan-kosh-en.json`, records the precise source ID and sense index, and marks
applied decisions `machineChecked`. This status records reproducible machine
checks and owner-authorized editorial work; it does not claim community or
independent human review. The compatibility wrapper follows the same policy.
Blanket queue approval is obsolete. Explicit exclusions remain protected and
can be reopened only by a later per-entry decision.

## Other sources

Merriam-Webster is appropriate for manual editorial verification but is not a
bundled runtime source: its API is query-based and licensed. Wiktionary-derived
data is a coverage fallback only, since its CC BY-SA/GFDL terms require separate
attribution and licensing review.

## Attribution

Release builds using OEWN-derived definitions must include a visible notice:

> English definition data adapted from Open English WordNet 2025, licensed
> CC BY 4.0.

## Distributed content policy

Authoring imports and review files stay outside the application bundle. Run
`dart run tool/build_release_content.dart --write` after curation changes. It
folds approved overrides into `app/assets/content/release/`, keeps all accepted
guess spellings, clears every definition field whose reuse source is unclear,
and makes those records ineligible as random answers. It also keeps sourced
cross-reference-only definitions out of the answer pool. Run the same command
with `--check` before a release build to reject stale release shards, followed
by `dart run tool/audit_release_content.dart`.

The release allowlist is exact: Open English WordNet 2025 marked CC BY 4.0;
Mahan Kosh records from pinned commit
`fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6`; and short definitions written
specifically for Sikhi Word Games. A source license establishes reuse rights,
not semantic, cultural, or age suitability. Existing editorial exclusions and
the unresolved review queue still apply.

The September release baseline contained 47,093 records, 45,416 accepted guesses,
14,701 answer records, and 16,756 visible sourced definitions. The October 7
recheck adds 17 holds: 12 sensitive/stigmatizing definitions and five Punjabi
editorial meanings without sufficient source links. The final reference check
preserves ordinary senses such as 'of or relating to...' and 'see with attention';
a broad prefix match would incorrectly quarantine valid adjective/verb meanings.
These five are provenance exceptions, not a claim that their meanings are wrong.
Current release counts and pools are measured in `docs/content_schema.md` and the
fresh recheck report. The latest legacy Punjabi review report covers
13,678 source-matched records and 288 explicit edited definitions: 187 familiar
Romanized words and 101 native four-grapheme proposals. It records 6,386
approved and 5,186 held decisions. Missing, unsafe, uncertain, or malformed
meanings remain held; broken pronunciations are excluded from play. These are
release decisions, not a claim that every archived dictionary sense has been
reviewed for familiarity or children.
