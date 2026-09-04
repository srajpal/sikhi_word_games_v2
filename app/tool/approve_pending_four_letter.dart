import 'dart:convert';
import 'dart:io';

/// Approves every currently pending four-letter runtime entry. Existing
/// decisions and rejections are preserved. This is intentionally explicit
/// because the owner requested approval of the complete pending queue.
void main() {
  final curation = Directory('assets/content/curation');
  final solutionsFile = File('${curation.path}/starter_solutions.json');
  final overridesFile = File('${curation.path}/editorial_overrides.json');
  final decisionsFile = File('${curation.path}/four_letter_decisions.json');
  final unifiedFile = File('${curation.path}/dictionary_review_decisions.json');
  final solutions = _read(solutionsFile);
  final overridesDocument = _read(overridesFile);
  final decisionsDocument = _read(decisionsFile);
  final unified = unifiedFile.existsSync()
      ? _read(unifiedFile)
      : <String, Object?>{'entries': <Object?>[]};
  final decided = <String>{};
  for (final item in decisionsDocument['entries']! as List<Object?>) {
    decided.add(
      'english_${((item! as Map<String, Object?>)['word']! as String).toLowerCase()}',
    );
  }
  for (final item in unified['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    if (entry['length'] == 4) decided.add(entry['id']! as String);
  }
  final overrideMap = <String, Map<String, Object?>>{};
  for (final item in overridesDocument['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    overrideMap[entry['id']! as String] = entry;
  }
  final solutionIds = (solutions['solutionIds']! as List<Object?>)
      .cast<String>()
      .toSet();
  final approved = <String>[];
  final entries = _readEntries();
  final entriesById = {
    for (final entry in entries) entry['id']! as String: entry,
  };
  for (final item in entries) {
    final entry = item;
    final id = entry['id']! as String;
    if (entry['language'] != 'panjabi' && entry['language'] != 'english') {
      continue;
    }
    final latinLength =
        ((entry['lengths']! as Map<String, Object?>)['latin'] as num?)?.toInt();
    if (latinLength != 4 || decided.contains(id)) {
      continue;
    }
    final definition =
        (((entry['definitions']! as Map<String, Object?>)['en']!
                        as List<Object?>)
                    .first!
                as String)
            .trim();
    if (definition.isEmpty) throw StateError('$id has no definition.');
    solutionIds.add(id);
    final existingDefinition = overrideMap[id]?['englishDefinition'] as String?;
    overrideMap[id] = {
      ...?overrideMap[id],
      'id': id,
      'englishDefinition': existingDefinition ?? definition,
      'acceptedGuess': true,
      'solutionEligible': true,
      'reviewStatus': 'editorApproved',
    };
    approved.add(id);
  }
  final decisionEntries = <Map<String, Object?>>[];
  for (final id in approved) {
    final entry = entriesById[id]!;
    decisionEntries.add({
      'id': id,
      'word': entry['latin'],
      'language': entry['language'],
      'length': 4,
      'decision': 'approve',
      'definition':
          (((entry['definitions']! as Map<String, Object?>)['en']!
                          as List<Object?>)
                      .first!
                  as String)
              .trim(),
      'notes': 'Owner-requested approval of all pending four-letter entries.',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
  final unifiedEntries = (unified['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();
  unifiedEntries.addAll(decisionEntries);
  solutions['solutionIds'] = solutionIds.toList()..sort();
  overridesDocument['entries'] = overrideMap.values.toList()
    ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  unified['schemaVersion'] = 1;
  unified['entries'] = unifiedEntries;
  _write(solutionsFile, solutions);
  _write(overridesFile, overridesDocument);
  _write(unifiedFile, unified);
  stdout.writeln('Approved ${approved.length} pending four-letter entries.');
}

List<Map<String, Object?>> _readEntries() {
  final entries = <Map<String, Object?>>[];
  for (final length in const [4, 5, 6]) {
    final values = jsonDecode(
      File('assets/content/generated/vocabulary_$length.json')
          .readAsStringSync(),
    ) as List<Object?>;
    entries.addAll(values.cast<Map<String, Object?>>());
  }
  return entries;
}

Map<String, Object?> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

void _write(File file, Map<String, Object?> value) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(value)}\n');
  temporary.renameSync(file.path);
}
