import 'dart:convert';
import 'dart:io';

/// Completes every unresolved runtime entry while preserving prior decisions.
/// This pass is intentionally inclusive: uncertain legitimate words remain
/// playable guesses; only clearly unsafe or name/place-only entries reject.
void main() {
  final curation = Directory('assets/content/curation');
  final solutionsFile = File('${curation.path}/starter_solutions.json');
  final overridesFile = File('${curation.path}/editorial_overrides.json');
  final unifiedFile = File('${curation.path}/dictionary_review_decisions.json');
  final solutions = _read(solutionsFile);
  final overridesDocument = _read(overridesFile);
  final unified = unifiedFile.existsSync()
      ? _read(unifiedFile)
      : <String, Object?>{'schemaVersion': 1, 'entries': <Object?>[]};
  final decided = <String>{};
  final decisionsById = <String, Map<String, Object?>>{};
  void addDecisions(List<Object?> items) {
    for (final item in items) {
      final entry = item! as Map<String, Object?>;
      final id =
          (entry['id'] as String?) ??
          'english_${(entry['word']! as String).toLowerCase()}';
      decided.add(id);
      decisionsById[id] = {...entry, 'id': id};
    }
  }

  final four = File('${curation.path}/four_letter_decisions.json');
  final five = File('${curation.path}/five_letter_decisions.json');
  if (four.existsSync()) {
    addDecisions((_read(four)['entries']! as List<Object?>));
  }
  if (five.existsSync()) {
    addDecisions((_read(five)['entries']! as List<Object?>));
  }
  addDecisions((unified['entries']! as List<Object?>));

  final overrideMap = <String, Map<String, Object?>>{};
  for (final item in overridesDocument['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    overrideMap[entry['id']! as String] = entry;
  }
  final solutionIds = (solutions['solutionIds']! as List<Object?>)
      .cast<String>()
      .toSet();
  final reassessment = _read(
    File('../reports/content/english_definition_reassessment.json'),
  );
  final englishReview = <String, Map<String, Object?>>{
    for (final item in reassessment['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['word']! as String:
          item as Map<String, Object?>,
  };
  final entries = _readEntries();
  var approved = 0;
  var guessOnly = 0;
  var rejected = 0;
  final now = DateTime.now().toUtc().toIso8601String();
  for (final entry in entries) {
    final id = entry['id']! as String;
    final lengths = entry['lengths']! as Map<String, Object?>;
    final length = (lengths['latin'] as num?)?.toInt();
    if (length == null || length < 4 || length > 6 || decided.contains(id)) {
      continue;
    }
    final word = entry['latin']! as String;
    final sourceDefinition = _definition(entry);
    final review = entry['language'] == 'english' ? englishReview[word] : null;
    final recommended = review?['recommendedDefinition'] as String?;
    final definition = recommended ?? sourceDefinition;
    final decision = _classify(
      word,
      entry['language']! as String,
      sourceDefinition,
      recommended,
    );
    if (decision == 'approve') {
      solutionIds.add(id);
      approved++;
    } else if (decision == 'guess_only') {
      guessOnly++;
    } else {
      rejected++;
    }
    final finalDefinition = definition.trim();
    final record = <String, Object?>{
      'id': id,
      'word': word,
      'language': entry['language'],
      'length': length,
      'decision': decision,
      'definition': finalDefinition,
      'notes': _note(decision),
      'method': 'inclusive_dictionary_review_v1',
      'updatedAt': now,
    };
    decisionsById[id] = record;
    decided.add(id);
    if (decision == 'reject') {
      overrideMap.remove(id);
      continue;
    }
    final existingDefinition = overrideMap[id]?['englishDefinition'] as String?;
    overrideMap[id] = {
      ...?overrideMap[id],
      'id': id,
      if ((existingDefinition ?? finalDefinition).isNotEmpty)
        'englishDefinition': existingDefinition ?? finalDefinition,
      'acceptedGuess': true,
      'solutionEligible': decision == 'approve',
      'reviewStatus': 'editorApproved',
    };
  }
  final orderedDecisions = decisionsById.values.toList()
    ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  unified['schemaVersion'] = 1;
  unified['entries'] = orderedDecisions;
  solutions['solutionIds'] = solutionIds.toList()..sort();
  overridesDocument['entries'] = overrideMap.values.toList()
    ..sort((a, b) => (a['id']! as String).compareTo(b['id']! as String));
  _write(solutionsFile, solutions);
  _write(overridesFile, overridesDocument);
  _write(unifiedFile, unified);
  stdout.writeln(
    'Finished pending review: $approved approved, $guessOnly guess-only, $rejected rejected.',
  );
}

String _classify(
  String word,
  String language,
  String definition,
  String? recommended,
) {
  if (_unsafe.hasMatch(word) || _unsafe.hasMatch(definition)) return 'reject';
  if (_nameOnly.hasMatch(definition) && recommended == null) return 'reject';
  if (definition.trim().isEmpty) return 'guess_only';
  if (language == 'english' && recommended == null) return 'guess_only';
  if (_referenceOnly.hasMatch(definition)) return 'guess_only';
  return 'approve';
}

String _note(String decision) => switch (decision) {
  'approve' => 'Inclusive review: neutral, defined word retained as an answer.',
  'reject' => 'Clear rude, curse, slur, or name/place-only entry.',
  _ => 'Legitimate word retained as a guess; definition needs fallback or editorial review.',
};

String _definition(Map<String, Object?> entry) =>
    (((entry['definitions']! as Map<String, Object?>)['en']! as List<Object?>)
                .first!
            as String)
        .trim();

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

final _unsafe = RegExp(
  r'\b(?:anal|anus|arse|bitch|cock|cocks|coon|crap|cunts?|dago|dick|dicks|dyke|fagot|fuck|gook|gooks|homo|jizz|kike|kikes|nigga|nigger|penis|piss|porn|pussy|rape|sexist|shits?|slut|spic|tits?|turd|turds|whore)\b',
  caseSensitive: false,
);
final _nameOnly = RegExp(
  r'^(?:a |the )?(?:proper name|given name|first name|forename|a city of|a town of|a river in|the city of|the town of|capital city|capital of)\b',
  caseSensitive: false,
);
final _referenceOnly = RegExp(
  r'^(?:see|alt\.? of|alternative spelling|variant of|plural of|past tense of|present participle of|of)\b',
  caseSensitive: false,
);
