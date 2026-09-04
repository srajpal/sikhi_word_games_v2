import 'dart:convert';
import 'dart:io';

/// Applies curator decisions for the native Gurmukhi queue to the app's
/// supplemental vocabulary. Pending entries are never imported.
Future<void> main() async {
  final app = Directory.current;
  final workspace = app.parent;
  final reportFile = File(
    '${workspace.path}${Platform.pathSeparator}reports${Platform.pathSeparator}'
    'content${Platform.pathSeparator}gurmukhi_candidates.json',
  );
  final decisionsFile = File(
    '${app.path}${Platform.pathSeparator}assets${Platform.pathSeparator}content${Platform.pathSeparator}'
    'curation${Platform.pathSeparator}dictionary_review_decisions.json',
  );
  final supplementalFile = File(
    '${app.path}${Platform.pathSeparator}assets${Platform.pathSeparator}content${Platform.pathSeparator}'
    'curation${Platform.pathSeparator}supplemental_entries.json',
  );

  if (!reportFile.existsSync()) {
    throw StateError('Missing native candidate report: ${reportFile.path}');
  }
  if (!decisionsFile.existsSync()) {
    throw StateError('Missing review decisions: ${decisionsFile.path}');
  }
  if (!supplementalFile.existsSync()) {
    throw StateError('Missing supplemental entries: ${supplementalFile.path}');
  }

  final report = jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
  final decisions = jsonDecode(decisionsFile.readAsStringSync()) as Map<String, dynamic>;
  final supplemental = jsonDecode(supplementalFile.readAsStringSync()) as Map<String, dynamic>;
  final candidates = (report['candidates'] as List<dynamic>? ?? const []);
  final decisionEntries = (decisions['entries'] as List<dynamic>? ?? const []);
  final entries = (supplemental['entries'] as List<dynamic>? ?? const [])
      .map((entry) => Map<String, dynamic>.from(entry as Map))
      .toList();

  final byId = <String, Map<String, dynamic>>{
    for (final entry in entries)
      if (entry['id'] is String) entry['id'] as String: entry,
  };
  final bySpelling = <String, Map<String, dynamic>>{
    for (final entry in entries)
      if (entry['latin'] is String && entry['language'] is String)
        '${entry['language']}:${entry['latin']}': entry,
  };
  final decisionById = <String, Map<String, dynamic>>{
    for (final raw in decisionEntries)
      if (raw is Map && (raw['id'] ?? raw['internalId']) is String)
        (raw['id'] ?? raw['internalId']) as String: Map<String, dynamic>.from(raw),
  };

  var approved = 0;
  var skipped = 0;
  var alreadyPresent = 0;
  for (final raw in candidates) {
    final candidate = raw as Map<String, dynamic>;
    final sourceId = candidate['id'] as String?;
    if (sourceId == null) {
      skipped++;
      continue;
    }
    final internalId = 'gurmukhi_mahan_kosh_$sourceId';
    final decision = decisionById[internalId];
    final status = decision?['decision'];
    if (status != 'approve' && status != 'guess_only') continue;

    final gurmukhi = candidate['gurmukhi'] as String?;
    final romanized = (candidate['romanized'] as String?)?.trim().toUpperCase();
    final sourceDefinition = (candidate['definition'] as String? ?? '').trim();
    final reviewedDefinition = (decision?['definition'] as String? ?? '').trim();
    final definition = reviewedDefinition.isNotEmpty ? reviewedDefinition : sourceDefinition;
    if (gurmukhi == null || romanized == null || romanized.isEmpty ||
        !RegExp(r'^[A-Z]+$').hasMatch(romanized) || definition.isEmpty) {
      skipped++;
      continue;
    }

    if (byId.containsKey(internalId) || bySpelling.containsKey('panjabi:$romanized')) {
      alreadyPresent++;
      continue;
    }

    final source = candidate['source'] as Map<String, dynamic>? ?? const {};
    final sourceLabel = StringBuffer('Mahan Kosh multilingual dataset; ')
      ..write('commit ${report['source'] is Map ? (report['source'] as Map)['commit'] : 'unknown'}');
    if (source['volume'] != null || source['page'] != null) {
      sourceLabel.write('; vol. ${source['volume'] ?? '?'}, p. ${source['page'] ?? '?'}');
    }

    final entry = <String, dynamic>{
      'id': internalId,
      'language': 'panjabi',
      'latin': romanized,
      'gurmukhi': gurmukhi,
      'definitions': {'en': [definition], 'pa': []},
      'lengths': {
        'latin': romanized.length,
        'gurmukhi': candidate['length'],
      },
      'acceptedGuess': true,
      'solutionEligible': status == 'approve',
      'reviewStatus': 'editorApproved',
      'sources': [sourceLabel.toString()],
    };
    entries.add(entry);
    byId[internalId] = entry;
    bySpelling['panjabi:$romanized'] = entry;
    approved++;
  }

  if (approved > 0) {
    supplemental['entries'] = entries;
    final temporary = File('${supplementalFile.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(supplemental),
    );
    await temporary.rename(supplementalFile.path);
  }

  stdout.writeln('Native Gurmukhi decisions applied: $approved');
  stdout.writeln('Already present: $alreadyPresent');
  stdout.writeln('Skipped (missing clean data): $skipped');
  stdout.writeln('Pending/rejected candidates left untouched: '
      '${candidates.length - approved - alreadyPresent - skipped}');
}
