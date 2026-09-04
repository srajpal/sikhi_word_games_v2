import 'dart:convert';
import 'dart:io';

/// Creates the five-letter English editorial queue from the full OEWN
/// reassessment report. It is intentionally inclusive: words without a safe
/// modern definition stay valid guesses rather than being rejected.
void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final reassessment = _read(
    '../reports/content/english_definition_reassessment.json',
  );
  final source = <String, Map<String, Object?>>{
    for (final item in reassessment['entries']! as List<Object?>)
      (item! as Map<String, Object?>)['word']! as String:
          item as Map<String, Object?>,
  };
  final entries =
      (jsonDecode(
        File('assets/content/generated/vocabulary_5.json').readAsStringSync(),
      ) as List<Object?>).cast<Map<String, Object?>>().where(
        (entry) => entry['language'] == 'english',
      );

  final decisions = <Map<String, Object?>>[];
  for (final entry in entries) {
    final word = entry['latin']! as String;
    final review = source[word];
    final original = _definition(entry);
    final recommended = review?['recommendedDefinition'] as String?;
    final decision = _classify(word, original, recommended);
    decisions.add({
      'word': word,
      'internalId': entry['id'],
      'decision': decision,
      'definition': recommended ?? original,
      'notes': _note(decision, recommended != null),
      'method': 'oewn_2025_inclusive_v1',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
  decisions.sort(
    (a, b) => (a['word']! as String).compareTo(b['word']! as String),
  );
  final counts = <String, int>{};
  for (final item in decisions) {
    final key = item['decision']! as String;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final report = {
    'schemaVersion': 1,
    'scope': 'Five-letter English candidate review',
    'sources': [
      {
        'name': 'Open English WordNet 2025 base edition',
        'url': 'https://en-word.net/downloads',
        'purpose': 'neutral definition selection and lexical confirmation',
      },
    ],
    'counts': counts,
    'candidates': decisions,
  };
  const encoder = JsonEncoder.withIndent('  ');
  File('../reports/content/five_letter_candidates.json')
      .writeAsStringSync('${encoder.convert(report)}\n');
  if (!shouldWrite) {
    stdout.writeln(
      'Five-letter preview: $counts. Rerun with --write to save decisions.',
    );
    return;
  }
  File('assets/content/curation/five_letter_decisions.json').writeAsStringSync(
    '${encoder.convert({'schemaVersion': 1, 'entries': decisions})}\n',
  );
  stdout.writeln('Saved five-letter decisions: $counts.');
}

String _classify(String word, String original, String? recommended) {
  if (_clearRudeWords.contains(word)) return 'reject';
  if (recommended == null) return 'guess_only';
  if (RegExp(r'(?:ED|ING|S)$').hasMatch(word)) return 'guess_only';
  if (_looksReferenceOnly(original)) return 'guess_only';
  return 'approve';
}

String _note(String decision, bool hasOewnDefinition) => switch (decision) {
  'approve' => 'Neutral OEWN-confirmed word with a standalone definition.',
  'reject' => 'Clear rude, curse, slur, or explicit sexual term.',
  _ when !hasOewnDefinition =>
    'Retained as a guess; no neutral OEWN definition candidate.',
  _ => 'Retained as a guess; inflection, variant, or reference-style entry.',
};

bool _looksReferenceOnly(String definition) => RegExp(
  r'^(?:see|alt\.? of|alternative spelling|variant of|of)\b',
  caseSensitive: false,
).hasMatch(definition.trim());

String _definition(Map<String, Object?> entry) =>
    (((entry['definitions']! as Map<String, Object?>)['en']! as List<Object?>)
                .first!
            as String)
        .trim();

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

const _clearRudeWords = {
  'BITCH',
  'COCKS',
  'CUNTS',
  'DAGOS',
  'DICKS',
  'FAGOT',
  'GOOKS',
  'KIKES',
  'NIGGA',
  'PENIS',
  'PUSSY',
  'SHITS',
  'SPICS',
  'TURDS',
  'WHORE',
};
