import 'dart:convert';
import 'dart:io';

/// Builds a deterministic second-pass queue from licensed OEWN candidates.
///
/// Preview by default. Use `--write --limit N` to apply at most N definition
/// updates. This tool never promotes an entry based on spelling or a word-list
/// match alone.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final limit = _intArgument(arguments, '--limit') ?? 0;
  if (write && limit <= 0) {
    throw ArgumentError('Writing requires a positive --limit.');
  }

  final reassessment = _read(
    '../reports/content/english_definition_reassessment.json',
  );
  final overridesFile = File(
    'assets/content/curation/editorial_overrides.json',
  );
  final overridesDocument = _read(overridesFile.path);
  final overrides = <String, Map<String, Object?>>{
    for (final item in overridesDocument['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['id']! as String:
          item as Map<String, Object?>,
  };
  final currentDefinitions = _effectiveDefinitions(overrides);
  final sparkManualIds = _sparkManualIds();
  final rows = <Map<String, Object?>>[];

  for (final item in reassessment['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    final id = entry['id']! as String;
    final recommended = entry['recommendedDefinition'] as String?;
    final current =
        currentDefinitions[id] ?? entry['currentDefinition']! as String;
    if (recommended == null || current == recommended) {
      continue;
    }

    final reason = _manualReason(id, recommended, sparkManualIds);
    rows.add({
      'id': id,
      'word': entry['word'],
      'currentDefinition': current,
      'recommendedDefinition': recommended,
      'classification': 'manual_review',
      'recommendedAction': 'retain_current_until_reviewed',
      'reason': reason ?? 'The licensed candidate passes structural checks but its meaning and audience suitability still need review.',
      'source': _source,
    });
  }
  for (final correction in _curatedCorrections.entries) {
    final id = correction.key;
    final definition = correction.value.$1;
    final existing = overrides[id];
    rows.removeWhere((row) => row['id'] == id);
    if (currentDefinitions[id] == definition &&
        (correction.value.$2 == null ||
            existing?['solutionEligible'] == correction.value.$2)) {
      rows.add({
        'id': id,
        'word': id.substring('english_'.length).toUpperCase(),
        'currentDefinition': definition,
        'recommendedDefinition': definition,
        'classification': 'verified_current',
        'recommendedAction': 'none',
        'reason': 'The selected neutral OEWN sense and answer eligibility are already applied.',
        'source': _source,
      });
      continue;
    }
    rows.add({
      'id': id,
      'word': id.substring('english_'.length).toUpperCase(),
      'currentDefinition': currentDefinitions[id],
      'recommendedDefinition': definition,
      'classification': 'verified_correction_pending',
      'recommendedAction': correction.value.$2 == false
          ? 'replace_definition_and_keep_guess_only'
          : 'replace_definition_only',
      'reason': 'A more useful neutral sense was selected from the bundled licensed OEWN sense list.',
      'source': _source,
      'solutionEligible': ?correction.value.$2,
    });
  }
  rows.sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));

  final safe = rows
      .where((row) => row['classification'] == 'verified_correction_pending')
      .toList();
  final manual = rows
      .where((row) => row['classification'] == 'manual_review')
      .length;
  final verified = rows
      .where((row) => row['classification'] == 'verified_current')
      .length;
  final auditFile = File('../reports/content/dictionary_audit.json');
  final auditFlags = auditFile.existsSync()
      ? (_read(auditFile.path)['issueCount'] as num).toInt()
      : null;
  final report = {
    'schemaVersion': 1,
    'method': 'licensed_definition_triage_v1',
    'source': _source,
    'verifiedCorrectionPendingCount': safe.length,
    'manualReviewCount': manual,
    'verifiedCurrentCount': verified,
    'dictionaryAuditFlagsRemaining': ?auditFlags,
    'entries': rows,
  };
  _write(File('../reports/content/remaining_content_triage.json'), report);
  File('../reports/content/remaining_content_triage.md').writeAsStringSync(
    '# Remaining Content Triage\n\n'
    '- Explicitly verified corrections pending: ${safe.length}\n'
    '- Manual review among changed OEWN candidates: $manual\n'
    '- Previously applied and verified: $verified\n'
    '${auditFlags == null ? '' : '- Broader dictionary audit flags still queued: $auditFlags\n'}'
    '\n'
    'Only explicitly checked corrections can be written. Other OEWN differences '
    'remain manual candidates even when they pass structural checks. This report '
    'does not cover unchanged definitions or prove that all remaining words were '
    'reviewed. It does not promote guess-only words to answers. Spark suggestions are '
    'review signals only because that report provides no licensed replacement text.\n',
  );

  stdout.writeln(
    'Triage: ${safe.length} verified corrections pending; $manual manual; '
    '$verified previously applied and verified.',
  );
  if (!write) {
    return;
  }
  final selected = safe.take(limit).toList();
  for (final row in selected) {
    final id = row['id']! as String;
    overrides[id] = {
      ...?overrides[id],
      'id': id,
      'englishDefinition': row['recommendedDefinition'],
      'source': _source,
      'reviewStatus': 'machineChecked',
      'solutionEligible': ?row['solutionEligible'],
    };
  }
  overridesDocument['entries'] = overrides.values.toList()
    ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  _write(overridesFile, overridesDocument);
  stdout.writeln('Applied ${selected.length} bounded definition updates.');
}

String? _manualReason(
  String id,
  String definition,
  Set<String> sparkManualIds,
) {
  if (sparkManualIds.contains(id)) {
    return 'Existing Spark review marked this entry for expert review.';
  }
  if (_manualMeaningIds.contains(id)) {
    return 'Meaning or family suitability needs a human choice.';
  }
  final text = definition.trim();
  if (text.length < 6 || text.length > 140) {
    return 'Definition is outside the concise clue range.';
  }
  if (_referenceOnly.hasMatch(text)) {
    return 'Definition depends on another entry.';
  }
  final word = id.substring('english_'.length).replaceAll('_', ' ');
  if (_normalized(text).split(' ').contains(word)) {
    return 'Definition repeats the headword.';
  }
  return null;
}

Set<String> _sparkManualIds() {
  final file = File('../reports/content/spark_definition_proposals.json');
  if (!file.existsSync()) {
    return const {};
  }
  final document = _read(file.path);
  return {
    for (final item in document['entries']! as List<Object?>)
      if ((item! as Map<String, Object?>)['decision'] == 'needs_expert_review')
        (item as Map<String, Object?>)['id']! as String,
  };
}

Map<String, String> _effectiveDefinitions(
  Map<String, Map<String, Object?>> overrides,
) {
  final result = <String, String>{};
  for (final length in const [4, 5, 6]) {
    final entries = jsonDecode(
      File('assets/content/generated/vocabulary_$length.json')
          .readAsStringSync(),
    ) as List<Object?>;
    for (final item in entries) {
      final entry = item! as Map<String, Object?>;
      result[entry['id']! as String] = _definition(entry);
    }
  }
  final supplemental = _read(
    'assets/content/curation/supplemental_entries.json',
  );
  for (final item in supplemental['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    result[entry['id']! as String] = _definition(entry);
  }
  for (final entry in overrides.entries) {
    if (entry.value['englishDefinition'] case final String definition) {
      result[entry.key] = definition;
    }
  }
  return result;
}

String _definition(Map<String, Object?> entry) =>
    (((entry['definitions']! as Map<String, Object?>)['en']! as List<Object?>)
                .first
            as String)
        .trim();
String _normalized(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
int? _intArgument(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  return index >= 0 && index + 1 < arguments.length
      ? int.tryParse(arguments[index + 1])
      : null;
}

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
void _write(File file, Map<String, Object?> value) {
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
  temporary.renameSync(file.path);
}

const _source = 'Open English WordNet 2025 (CC BY 4.0)';
const _manualMeaningIds = {
  'english_derp',
  'english_dike',
  'english_hick',
  'english_jazz',
  'english_perv',
};
const _curatedCorrections = <String, (String, bool?)>{
  'english_give': (
    'transfer possession of something concrete or abstract to somebody',
    null,
  ),
  'english_take': (
    'pick out, select, or choose from a number of alternatives',
    null,
  ),
  'english_want': ('a specific feeling of desire', null),
  'english_lust': ('have a craving, appetite, or great desire for', false),
  'english_stud': ('an upright in house framing', false),
};
final _referenceOnly = RegExp(
  r'^(?:see|of|plural of|past tense of|present participle of|alternative spelling)\b',
  caseSensitive: false,
);
