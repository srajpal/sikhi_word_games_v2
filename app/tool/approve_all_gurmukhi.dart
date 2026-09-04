import 'dart:convert';
import 'dart:io';

/// Records the explicit bulk approval requested for every native Gurmukhi
/// candidate currently in the generated review report.
///
/// This writes editorial decisions only. The separate apply script performs
/// validation and imports only candidates with clean runtime fields.
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
  if (!reportFile.existsSync() || !decisionsFile.existsSync()) {
    throw StateError('Native report or decision store is missing.');
  }

  final report = jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
  final decisions = jsonDecode(decisionsFile.readAsStringSync()) as Map<String, dynamic>;
  final candidates = report['candidates'] as List<dynamic>? ?? const [];
  final entries = (decisions['entries'] as List<dynamic>? ?? const [])
      .map((entry) => Map<String, dynamic>.from(entry as Map))
      .toList();
  final index = <String, Map<String, dynamic>>{
    for (final entry in entries)
      if (entry['id'] is String) entry['id'] as String: entry,
  };

  var added = 0;
  var refreshed = 0;
  for (final raw in candidates) {
    final candidate = raw as Map<String, dynamic>;
    final sourceId = candidate['id'] as String?;
    final gurmukhi = candidate['gurmukhi'] as String?;
    if (sourceId == null || gurmukhi == null) continue;
    final id = 'gurmukhi_mahan_kosh_$sourceId';
    final entry = <String, dynamic>{
      'word': candidate['romanized'] ?? gurmukhi,
      'id': id,
      'language': 'gurmukhi',
      'length': candidate['length'],
      'decision': 'approve',
      'definition': candidate['definition'] ?? '',
      'notes': 'Bulk approval requested by project owner for native Gurmukhi queue.',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (index.containsKey(id)) {
      index[id] = entry;
      final position = entries.indexWhere((item) => item['id'] == id);
      if (position >= 0) entries[position] = entry;
      refreshed++;
    } else {
      entries.add(entry);
      index[id] = entry;
      added++;
    }
  }

  entries.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  decisions['entries'] = entries;
  final temporary = File('${decisionsFile.path}.tmp');
  await temporary.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(decisions)}\n',
  );
  await temporary.rename(decisionsFile.path);
  stdout.writeln('Native Gurmukhi approvals added: $added');
  stdout.writeln('Existing native decisions refreshed: $refreshed');
  stdout.writeln('Total native approvals recorded: ${candidates.length}');
}
