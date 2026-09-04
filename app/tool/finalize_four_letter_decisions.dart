import 'dart:convert';
import 'dart:io';

/// Completes the four-letter queue without replacing any existing editorial
/// choices. It distinguishes answer-quality words from broader accepted guesses.
void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final report = _read('../reports/content/four_letter_candidates.json');
  final decisionFile = File(
    'assets/content/curation/four_letter_decisions.json',
  );
  final document = _read(decisionFile.path);
  final decisions = <String, Map<String, Object?>>{};
  for (final item in document['entries']! as List<Object?>) {
    final entry = item! as Map<String, Object?>;
    decisions[entry['word']! as String] = entry;
  }

  var approve = 0;
  var guessOnly = 0;
  var reject = 0;
  final newEntries = <Map<String, Object?>>[];
  for (final item in report['candidates']! as List<Object?>) {
    final candidate = item! as Map<String, Object?>;
    final word = candidate['word']! as String;
    if (candidate['currentlyActiveAnswer'] == true ||
        decisions.containsKey(word)) {
      continue;
    }

    final classification = _classify(candidate);
    newEntries.add(
      _decision(candidate, classification.decision, classification.note),
    );
    switch (classification.decision) {
      case 'approve':
        approve++;
      case 'guess_only':
        guessOnly++;
      case 'reject':
        reject++;
      default:
        throw StateError('Unexpected decision: ${classification.decision}');
    }
  }

  stdout.writeln(
    'Final classification proposes $approve answers, $guessOnly accepted '
    'guesses, and $reject rejections.',
  );
  _printSample('Answer sample', newEntries, 'approve');
  _printSample('Guess-only sample', newEntries, 'guess_only');
  _printSample('Rejected-name/rude sample', newEntries, 'reject');
  if (!shouldWrite) {
    stdout.writeln('No decisions changed. Rerun with --write to save.');
    return;
  }

  for (final entry in newEntries) {
    decisions[entry['word']! as String] = entry;
  }
  final sorted = decisions.values.toList()
    ..sort((a, b) => (a['word']! as String).compareTo(b['word']! as String));
  document['entries'] = sorted;
  _write(decisionFile, document);
  stdout.writeln('Saved ${newEntries.length} final classifications.');
}

_Classification _classify(Map<String, Object?> candidate) {
  final word = candidate['word']! as String;
  final definition = (candidate['definition']! as String).trim();
  if (_rudeWords.contains(word)) {
    return const _Classification(
      'reject',
      'Explicit, rude, or derogatory term.',
    );
  }
  if (_isDirectName(definition)) {
    return const _Classification('reject', 'Direct personal or place name.');
  }

  final frequency = (candidate['zipfFrequency'] as num?)?.toDouble() ?? 0;
  final scowlSize = candidate['scowlSize'] as int?;
  final isWordNetConfirmed = candidate['openEnglishWordNet'] == true;
  if (_isAnswerDefinition(definition) &&
      frequency >= 3.0 &&
      scowlSize != null &&
      scowlSize <= 60 &&
      (isWordNetConfirmed || frequency >= 4.0)) {
    return const _Classification(
      'approve',
      'Suitable common word with a self-contained definition.',
    );
  }
  return const _Classification(
    'guess_only',
    'Valid word retained as an accepted guess but not selected as an answer.',
  );
}

bool _isDirectName(String definition) => RegExp(
  r'\b(proper name|given name|first name|forename|capital city|capital of|'
  r'city of|town of|river in|name of (a|the) (city|town|river|person))\b',
  caseSensitive: false,
).hasMatch(definition);

bool _isAnswerDefinition(String definition) {
  if (definition.length < 10 || definition.length > 170) return false;
  return !RegExp(
    r'^(of (be|do|go|have|say|see|take|use)\b|see\b|imp\.|p\. ?p\.|plural\b|past tense\b|present '
    r'participle\b|alternative spelling\b)|\b(archaic|obsolete|dialectal|'
    r'Shakespearean|same as|variant of|supposed to mean|formerly|'
    r'one of numerous species|street names|offensive term|ethnic slur|'
    r'racial slur|obscene|vulgar|profan(?:e|ity)|pornograph(?:y|ic)|'
    r'sexual intercourse|genitals?|penis|vagina|feces|excrement|'
    r'marijuana|narcotic)\b',
    caseSensitive: false,
  ).hasMatch(definition);
}

Map<String, Object?> _decision(
  Map<String, Object?> candidate,
  String decision,
  String note,
) => {
  'word': candidate['word'],
  'decision': decision,
  'definition': candidate['definition'],
  'notes': note,
  'method': 'automatic_final_v1',
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
};

void _printSample(
  String label,
  List<Map<String, Object?>> entries,
  String decision,
) {
  final sample = entries
      .where((entry) => entry['decision'] == decision)
      .take(25)
      .map((entry) => entry['word'])
      .join(', ');
  stdout.writeln('$label: ${sample.isEmpty ? 'none' : sample}');
}

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

void _write(File file, Map<String, Object?> document) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(document)}\n');
  temporary.renameSync(file.path);
}

class _Classification {
  const _Classification(this.decision, this.note);

  final String decision;
  final String note;
}

const _rudeWords = {
  'ANAL',
  'ANUS',
  'ARSE',
  'CLIT',
  'COCK',
  'COON',
  'CRAP',
  'CUNT',
  'DAGO',
  'DICK',
  'DOPE',
  'DYKE',
  'FUCK',
  'GOOK',
  'HOMO',
  'JISM',
  'JIZZ',
  'KIKE',
  'NAZI',
  'NUDE',
  'PISS',
  'POOP',
  'PORN',
  'PUSS',
  'RAPE',
  'SEXY',
  'SHIT',
  'SLUT',
  'SPIC',
  'SPIK',
  'TITS',
  'TURD',
};
