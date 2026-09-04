import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final wordLength = _wordLength(arguments);
  final name = _lengthName(wordLength);
  final curation = Directory('assets/content/curation');
  final decisionsFile = File('${curation.path}/${name}_letter_decisions.json');
  final solutionsFile = File('${curation.path}/starter_solutions.json');
  final overridesFile = File('${curation.path}/editorial_overrides.json');
  final supplementalFile = File('${curation.path}/supplemental_entries.json');
  final reportFile = File('../reports/content/${name}_letter_candidates.json');

  final decisionsDocument = _readDocument(decisionsFile);
  final reportDocument = _readDocument(reportFile);
  final solutionsDocument = _readDocument(solutionsFile);
  final overridesDocument = _readDocument(overridesFile);
  final supplementalDocument = _readDocument(supplementalFile);

  final candidates = <String, Map<String, Object?>>{};
  for (final item in reportDocument['candidates']! as List<Object?>) {
    final candidate = item! as Map<String, Object?>;
    candidates[candidate['word']! as String] = candidate;
  }
  final decisions = (decisionsDocument['entries']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .where((entry) => entry['decision'] != 'pending')
      .toList();
  final solutions = (solutionsDocument['solutionIds']! as List<Object?>)
      .cast<String>()
      .toSet();
  final overrides = <String, Map<String, Object?>>{};
  for (final item in overridesDocument['entries']! as List<Object?>) {
    final override = item! as Map<String, Object?>;
    overrides[override['id']! as String] = override;
  }
  final supplemental = <String, Map<String, Object?>>{};
  for (final item in supplementalDocument['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    supplemental[entry['id']! as String] = entry;
  }

  final generatedIds = <String>{};
  for (final length in const [4, 5, 6]) {
    final entries = jsonDecode(
      File('assets/content/generated/vocabulary_$length.json')
          .readAsStringSync(),
    ) as List<Object?>;
    generatedIds.addAll(
      entries.map((item) => (item! as Map<String, Object?>)['id']! as String),
    );
  }

  var approved = 0;
  var guessOnly = 0;
  var rejected = 0;
  var added = 0;
  for (final decision in decisions) {
    final word = decision['word']! as String;
    final candidate = candidates[word];
    if (candidate == null) throw FormatException('Unknown candidate: $word');
    final id =
        (candidate['internalId'] as String?) ?? 'english_${word.toLowerCase()}';
    final action = decision['decision']! as String;
    final definition = (decision['definition']! as String).trim();
    if (action == 'approve' && definition.isEmpty) {
      throw FormatException('$word cannot be approved without a definition.');
    }

    final exists = generatedIds.contains(id) || supplemental.containsKey(id);
    if (!exists && action != 'reject') {
      if (definition.isEmpty) {
        throw FormatException(
          '$word needs a definition before it can be added.',
        );
      }
      supplemental[id] = _supplementalEntry(
        id: id,
        word: word,
        definition: definition,
        solutionEligible: action == 'approve',
        wordLength: wordLength,
      );
      added++;
    }

    switch (action) {
      case 'approve':
        solutions.add(id);
        if (generatedIds.contains(id)) {
          overrides[id] = {
            ...?overrides[id],
            'id': id,
            'englishDefinition': definition,
            'acceptedGuess': true,
            'solutionEligible': true,
            'reviewStatus': 'editorApproved',
          };
        } else {
          _updateSupplemental(supplemental[id]!, definition, true, true);
        }
        approved++;
      case 'guess_only':
        solutions.remove(id);
        if (generatedIds.contains(id)) {
          overrides[id] = {
            ...?overrides[id],
            'id': id,
            if (definition.isNotEmpty) 'englishDefinition': definition,
            'acceptedGuess': true,
            'solutionEligible': false,
            'reviewStatus': 'editorApproved',
          };
        } else if (supplemental[id] != null) {
          _updateSupplemental(supplemental[id]!, definition, true, false);
        }
        guessOnly++;
      case 'reject':
        solutions.remove(id);
        if (generatedIds.contains(id)) {
          overrides[id] = {
            ...?overrides[id],
            'id': id,
            if (definition.isNotEmpty) 'englishDefinition': definition,
            'acceptedGuess': false,
            'solutionEligible': false,
            'reviewStatus': 'editorApproved',
          };
        } else {
          supplemental.remove(id);
        }
        rejected++;
      default:
        throw FormatException('Unknown decision for $word: $action');
    }
  }

  stdout.writeln(
    'Decision preview: $approved approved, $guessOnly guess-only, '
    '$rejected rejected, $added new records.',
  );
  if (!shouldWrite) {
    stdout.writeln('No files changed. Rerun with --write to apply.');
    return;
  }

  solutionsDocument['solutionIds'] = solutions.toList();
  overridesDocument['entries'] = overrides.values.toList()..sort(_compareById);
  supplementalDocument['entries'] = supplemental.values.toList()
    ..sort(_compareById);
  _writeDocument(solutionsFile, solutionsDocument);
  _writeDocument(overridesFile, overridesDocument);
  _writeDocument(supplementalFile, supplementalDocument);
  stdout.writeln(
    'Applied decisions to curated assets. Run the audit and tests.',
  );
}

Map<String, Object?> _readDocument(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

Map<String, Object?> _supplementalEntry({
  required String id,
  required String word,
  required String definition,
  required bool solutionEligible,
  required int wordLength,
}) => {
  'id': id,
  'language': 'english',
  'latin': word,
  'gurmukhi': null,
  'definitions': {
    'en': [definition],
    'pa': <String>[],
  },
  'lengths': {'latin': wordLength, 'gurmukhi': null},
  'acceptedGuess': true,
  'solutionEligible': solutionEligible,
  'reviewStatus': 'editorApproved',
  'sources': ['Open English WordNet 2025; SCOWL v2'],
};

int _wordLength(List<String> arguments) {
  final index = arguments.indexOf('--length');
  if (index == -1) return 4;
  if (index + 1 >= arguments.length) {
    throw ArgumentError('Provide a word length after --length.');
  }
  final value = int.tryParse(arguments[index + 1]);
  if (value == null || !const {4, 5, 6}.contains(value)) {
    throw ArgumentError('Supported word lengths are 4, 5, and 6.');
  }
  return value;
}

String _lengthName(int length) => switch (length) {
  4 => 'four',
  5 => 'five',
  6 => 'six',
  _ => throw ArgumentError('Unsupported word length: $length'),
};

void _updateSupplemental(
  Map<String, Object?> entry,
  String definition,
  bool acceptedGuess,
  bool solutionEligible,
) {
  if (definition.isNotEmpty) {
    (entry['definitions']! as Map<String, Object?>)['en'] = [definition];
  }
  entry['acceptedGuess'] = acceptedGuess;
  entry['solutionEligible'] = solutionEligible;
  entry['reviewStatus'] = 'editorApproved';
}

int _compareById(Map<String, Object?> a, Map<String, Object?> b) =>
    (a['id']! as String).compareTo(b['id']! as String);

void _writeDocument(File file, Map<String, Object?> document) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(document)}\n');
  temporary.renameSync(file.path);
}
