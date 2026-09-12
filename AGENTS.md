# AGENTS.md

Sikhi Word Games V2 is an offline-first Flutter/Dart app. Active development is
under `app/`. `sikhi_word_games-main/` is the untracked V1 reference and must never
be included in commits.

## Essential references

- `README.md` — setup, repository layout, and basic validation.
- `TODO.md` — persistent implementation checklist and current project state. Keep it
  accurate as durable work is completed or discovered.
- `docs/product_decisions.md` — agreed product, language, vocabulary, and hosting policy.
- `docs/architecture.md` — application boundaries, persistence, and game rules.
- `docs/testing_strategy.md` — coverage expectations and quality gates.
- `docs/content_schema.md` and `docs/definition_sources.md` — vocabulary model,
  generation, curation, and sourcing policy.
- `docs/dictionary_review_tool.md` and `docs/gurmukhi_sources.md` — content-review
  workflows.
- `docs/word_quest_design.md` — Word Quest rules, UX, accessibility, and respectful
  visual constraints.

Read only the code and documentation relevant to the task. Do not scan the full
repository or vocabulary corpus without a concrete need.

## Durable constraints

- The app has exactly three themes: Modern, Sikhi, and Dark. Implement game-wide
  design through the shared theme/components in `app/lib/core/themes/`; do not
  duplicate palettes or common visual elements per screen.
- Preserve accessibility, responsive behavior, offline operation, and Unicode
  grapheme-safe handling (especially for Gurmukhi).
- Do not edit `app/assets/content/generated/` by hand. Put editorial decisions and
  supplemental entries in `app/assets/content/curation/`, following the content docs.
- Do not edit `app/assets/content/release/` by hand. Rebuild it with
  `dart run tool/build_release_content.dart --write` from `app/`; check it with
  `--check` and `dart run tool/audit_release_content.dart`. Only these compact
  vocabulary files belong in the distributed app.
- Preserve unrelated user changes and avoid unrelated refactoring.

## Validation

Run from `app/`, using targeted checks while iterating and the applicable full checks
before handoff:

```powershell
dart format lib test integration_test test_driver tool
flutter analyze --suppress-analytics
flutter test --suppress-analytics
dart run tool\audit_content.dart
flutter build web --release --no-web-resources-cdn --suppress-analytics
```

The content audit is required for vocabulary changes; a release web build is required
when platform/build configuration or release web behavior changes.

## Documentation discipline

Update existing durable documentation when architecture, design, game rules, content
policy, or testing decisions change. Do not create Markdown files for temporary notes;
use `TODO.md`, an existing relevant document, or the conversation.

## Web playtest release

- Use `app/tool/build_itch_io.ps1` for itch.io packaging after validation.
- Run `node tool/test_web_app_cache_service_worker.mjs` from `app/` when changing
  the offline web cache. Verify the actual packaged build after changing it.
- Keep editorial queues, backups, and V1 reference files out of runtime assets.
- A successful content-audit exit does not mean its flagged definitions are safe
  or editorially approved. Do not label bulk machine decisions as human review.
- Record browser/iframe, real-storage, Gurmukhi font, and offline-reload evidence
  separately from widget tests. Keep release blockers in `TODO.md`.
- Use simple player-facing text without em dashes. Preserve quoted source data
  and provenance; normalize display punctuation through shared presentation code.
