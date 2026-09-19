import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'content/mahan_kosh_text.dart';
import 'content/punjabi_quality.dart';
import 'review_punjabi_content.dart' show editorialSource, sourceCommit;

Future<void> main() async {
  final app = Directory.current;
  final workspace = app.parent;
  await applyGurmukhiDecisions(
    reportFile: File(
      '${workspace.path}/reports/content/gurmukhi_candidates.json',
    ),
    decisionsFile: File(
      '${app.path}/assets/content/curation/dictionary_review_decisions.json',
    ),
    supplementalFile: File(
      '${app.path}/assets/content/curation/supplemental_entries.json',
    ),
    overridesFile: File(
      '${app.path}/assets/content/curation/editorial_overrides.json',
    ),
  );
}

Future<void> applyGurmukhiDecisions({
  required File reportFile,
  required File decisionsFile,
  required File supplementalFile,
  required File overridesFile,
}) async {
  for (final file in [
    reportFile,
    decisionsFile,
    supplementalFile,
    overridesFile,
  ]) {
    if (!file.existsSync()) {
      throw StateError('Missing required file: ${file.path}');
    }
  }
  final report = _read(reportFile);
  final source = report['source'];
  if (source is! Map || source['commit'] != sourceCommit) {
    throw FormatException('Candidate report is not pinned to $sourceCommit.');
  }
  final supplemental = _read(supplementalFile);
  final overridesDocument = _read(overridesFile);
  final supplementalEntries = (supplemental['entries'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  final supplementsById = {
    for (final entry in supplementalEntries) entry['id'] as String: entry,
  };
  final overrides = {
    for (final item in overridesDocument['entries'] as List)
      (item as Map)['id'] as String: Map<String, dynamic>.from(item),
  };
  final candidates = {
    for (final item in report['candidates'] as List)
      'gurmukhi_mahan_kosh_${(item as Map)['id']}': Map<String, dynamic>.from(
        item,
      ),
  };

  var applied = 0;
  var stale = 0;
  final seenDecisionIds = <String>{};
  for (final raw in (_read(decisionsFile)['entries'] as List)) {
    final decision = Map<String, dynamic>.from(raw as Map);
    final id = (decision['id'] ?? decision['internalId']) as String?;
    if (id != null && !seenDecisionIds.add(id)) {
      throw FormatException('Duplicate manual decision: $id');
    }
    final candidate = id == null ? null : candidates[id];
    if (candidate == null) continue;
    if ('${decision['notes']}'.contains('Bulk approval requested') ||
        !_modernReviewMethod(decision['reviewMethod'])) {
      stale++;
      continue;
    }
    final status = decision['decision'];
    if (status != 'approve' && status != 'guess_only' && status != 'reject') {
      throw FormatException('Unsupported decision for $id: $status');
    }
    final existing = supplementsById[id];
    if (status == 'reject') {
      // A rejection may be the operation that removes a malformed legacy
      // record, so it must not depend on that record passing spelling checks.
      // There is nothing to reject when no supplemental record exists.
      if (existing == null) continue;
      existing['acceptedGuess'] = false;
      existing['solutionEligible'] = false;
      overrides[id!] = {
        ...?overrides[id],
        'id': id,
        'englishDefinition': '',
        'acceptedGuess': false,
        'solutionEligible': false,
        'reviewStatus': 'machineChecked',
        'reviewMethod': decision['reviewMethod'],
        'note':
            decision['notes'] ??
            'Rejected from the manual Punjabi review queue.',
      };
      applied++;
      continue;
    }
    final gurmukhi = (decision['gurmukhi'] ?? candidate['gurmukhi']) as String?;
    final latin = '${decision['latin'] ?? candidate['romanized'] ?? ''}'
        .trim()
        .toUpperCase();
    final sourceDefinition = '${candidate['definition'] ?? ''}'.trim();
    final definition = '${decision['definition'] ?? sourceDefinition}'.trim();
    if (gurmukhi == null || !hasMatchingPunjabiConsonants(gurmukhi, latin)) {
      throw FormatException(
        'Invalid Punjabi spelling for $id: $latin / $gurmukhi',
      );
    }
    final quality = assessPunjabiQuality(
      PunjabiQualityCandidate(
        gurmukhi: gurmukhi,
        latin: latin,
        englishDefinition: definition,
      ),
    );
    if (!quality.isPromotionCandidate) {
      throw FormatException(
        'Unsafe decision for $id: '
        '${quality.blockingIssues.map((issue) => issue.code).join(', ')}',
      );
    }

    final sourceDetails = candidate['source'] as Map? ?? const {};
    final mahanSource =
        'Mahan Kosh multilingual dataset; commit $sourceCommit; '
        'vol. ${sourceDetails['volume'] ?? '?'}, p. ${sourceDetails['page'] ?? '?'}; '
        'entry ${candidate['id']}';
    final rewritten = definition != sourceDefinition;
    if (rewritten && '${decision['verificationSource'] ?? ''}'.trim().isEmpty) {
      throw FormatException(
        'Rewritten definition lacks verificationSource: $id',
      );
    }
    const accepted = true;
    final eligible = status == 'approve';
    final definitionSource = rewritten ? editorialSource : mahanSource;
    if (existing == null && accepted) {
      final entry = <String, dynamic>{
        'id': id,
        'language': 'panjabi',
        'latin': latin,
        'gurmukhi': gurmukhi,
        'definitions': {
          'en': [definition],
          'pa': <String>[],
        },
        'lengths': {
          'latin': latin.characters.length,
          'gurmukhi': gurmukhi.characters.length,
        },
        'acceptedGuess': accepted,
        'solutionEligible': eligible,
        'reviewStatus': 'machineChecked',
        'sources': [definitionSource],
      };
      supplementalEntries.add(entry);
      supplementsById[id!] = entry;
    } else {
      existing['acceptedGuess'] = accepted;
      existing['solutionEligible'] = eligible;
    }

    // A current manual decision is authoritative even when an older override
    // exists, so write the correction and eligibility together.
    overrides[id!] = {
      ...?overrides[id],
      'id': id,
      'latin': latin,
      'gurmukhi': gurmukhi,
      'englishDefinition': definition,
      'acceptedGuess': accepted,
      'solutionEligible': eligible,
      'reviewStatus': 'machineChecked',
      'source': definitionSource,
      'verificationSource': mahanSource,
      'reviewMethod': decision['reviewMethod'],
      'note':
          decision['notes'] ?? 'Applied from the manual Punjabi review queue.',
    };
    applied++;
  }

  if (applied == 0) {
    stdout.writeln('Manual Gurmukhi decisions applied: 0');
    stdout.writeln('Stale blanket decisions skipped: $stale');
    return;
  }

  // Everything validates before either canonical document is replaced.
  supplemental['entries'] = supplementalEntries
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  overridesDocument['entries'] = overrides.values.toList()
    ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  await _atomicWrite(supplementalFile, supplemental);
  await _atomicWrite(overridesFile, overridesDocument);
  stdout.writeln('Manual Gurmukhi decisions applied: $applied');
  stdout.writeln('Stale blanket decisions skipped: $stale');
}

bool _modernReviewMethod(Object? value) =>
    value == 'manual-review-v1' ||
    value == 'human-reviewed-v1' ||
    value == 'agent-editorial-source-checked-v1';

Map<String, dynamic> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Future<void> _atomicWrite(
  File destination,
  Map<String, dynamic> document,
) async {
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
    flush: true,
  );
  await temporary.rename(destination.path);
}
