# Dictionary Review Tool

The dictionary review tool is a local editorial interface. It is not included
in release builds and binds only to `127.0.0.1`.

## Start the tool

From the `app` directory:

```powershell
dart run tool/dictionary_review_server.dart
```

Open `http://127.0.0.1:8787/`. An optional first argument changes the port.

The interface reads all generated vocabulary and writes review decisions to a
local decision store. It supports:

- word and definition search;
- language, word-size, decision, priority, and source filters;
- ranking, alphabetical, and frequency sorting;
- Approve answer, Guess only, Reject, and Clear decision actions;
- editable definitions and review notes;
- guarded bulk decisions for the visible selection;
- persistent progress totals.

It also includes the native Gurmukhi queue generated from the Mahan Kosh
source report. Native candidates are shown as Gurmukhi, retain a searchable
Romanized value when one is available, and are marked as missing until they
are explicitly reviewed.

An approved answer must have a non-empty definition. Reviewers should replace
reference-only, archaic, inappropriate, or misleading source definitions before
approval.

## Apply decisions

Preview changes first:

```powershell
dart run tool/apply_four_letter_decisions.dart
```

Apply them only after reviewing the preview:

```powershell
dart run tool/apply_four_letter_decisions.dart --write
dart run tool/audit_content.dart
flutter analyze
flutter test
```

The apply command updates the curated solution IDs and editorial overrides. It
also creates supplemental records for approved or guess-only words absent from
V1. Rejected imported words remain traceable in generated source data but are
disabled through editorial overrides.

Commit the decision file and resulting curated assets together so each runtime
change has an auditable editorial decision.

### Apply native Gurmukhi decisions

Native candidates are never imported automatically. After reviewing them in
the tool, preview and then apply only the entries marked `approve` or
`guess_only`:

```powershell
dart tool/apply_gurmukhi_decisions.dart
```

The command is idempotent and only writes `supplemental_entries.json` when it
finds new approved decisions. It requires a clean ASCII Romanized value and a
non-empty definition, records the Mahan Kosh commit and page provenance, and
keeps rejected or pending candidates out of the runtime pool.

If the project owner explicitly approves the entire generated native queue,
record that decision first with:

```powershell
dart tool/approve_all_gurmukhi.dart
dart tool/apply_gurmukhi_decisions.dart
```

The bulk command still leaves candidates without a clean Romanized value out
of the runtime dictionary; those entries remain visible in the review queue.

## Automatic first pass

Run the conservative automatic classifier in preview mode:

```powershell
dart run tool/auto_triage_four_letter_candidates.dart
```

Add `--write` to save its proposals. It preserves existing human decisions,
rejects only an explicit family-safety list, approves only independently
verified common words whose definitions pass clarity and sensitive-content
checks, and leaves uncertain entries pending. Its detailed audit is written to
`reports/content/four_letter_auto_triage.json`.

## Complete the queue

After the first pass, a broader final classifier can make every remaining
candidate either an answer, an accepted guess, or a rejection:

```powershell
dart run tool/finalize_four_letter_decisions.dart
dart run tool/finalize_four_letter_decisions.dart --write
```

It preserves all existing decisions. Appropriate familiar terms become answers;
valid but obscure terms remain accepted guesses; only explicit/rude terms and
clear standalone personal or place names are rejected.

## Broaden the answer rotation

To include a more varied set of legitimate words without making obscure terms
the default answer pool, use the broader pass:

```powershell
dart run tool/broaden_four_letter_answers.dart
dart run tool/broaden_four_letter_answers.dart --write
```

It promotes common, SCOWL-confirmed guess-only words while preserving explicit,
rude, and direct-name exclusions.
