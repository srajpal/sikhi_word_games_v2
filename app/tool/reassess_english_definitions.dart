import 'dart:convert';
import 'dart:io';

/// Produces a review queue for every bundled English entry using the
/// downloadable Open English WordNet (OEWN) 2025 base JSON edition.
///
/// Download OEWN separately, then run:
/// dart run tool/reassess_english_definitions.dart --source C:\path\to\oewn-json
///
/// This tool never changes shipped definitions. It records the neutral OEWN
/// senses available for each word so editorial changes remain deliberate.
void main(List<String> arguments) {
  final sourceIndex = arguments.indexOf('--source');
  if (sourceIndex == -1 || sourceIndex + 1 >= arguments.length) {
    throw ArgumentError('Usage: --source <Open-English-WordNet JSON folder>');
  }
  final source = Directory(arguments[sourceIndex + 1]);
  if (!source.existsSync()) {
    throw ArgumentError('OEWN source directory does not exist: ${source.path}');
  }

  final app = Directory.current;
  final reportDirectory = Directory(
    '${app.parent.path}${Platform.pathSeparator}reports'
    '${Platform.pathSeparator}content',
  )..createSync(recursive: true);
  final sensesByLemma = _readOewnSenses(source);
  final entries = _readEnglishEntries(app);
  final review =
      entries.map((entry) {
        final word = entry['latin']! as String;
        final current = _definition(entry);
        final candidates =
            (sensesByLemma[word.toLowerCase()] ?? const <String>[])
                .where(_isNeutralDefinition)
                .toSet()
                .toList()
              ..sort(_definitionOrder);
        return <String, Object?>{
          'id': entry['id'],
          'word': word,
          'currentDefinition': current,
          'recommendedDefinition': candidates.isEmpty ? null : candidates.first,
          'neutralOewnDefinitions': candidates,
          'status': candidates.isEmpty
              ? 'no_neutral_oewn_sense'
              : 'candidate_available',
        };
      }).toList()..sort(
        (a, b) => (a['word']! as String).compareTo(b['word']! as String),
      );

  final available = review
      .where((item) => item['status'] == 'candidate_available')
      .length;
  const encoder = JsonEncoder.withIndent('  ');
  File(
    '${reportDirectory.path}${Platform.pathSeparator}english_definition_reassessment.json',
  ).writeAsStringSync(
    encoder.convert({
      'schemaVersion': 1,
      'source': {
        'name': 'Open English WordNet 2025 base edition',
        'license': 'CC BY 4.0',
        'selection':
            'Neutral, standalone senses only; editorial review required.',
      },
      'entryCount': review.length,
      'candidateAvailableCount': available,
      'needsFallbackCount': review.length - available,
      'entries': review,
    }),
  );
  stdout.writeln(
    'Reassessed ${review.length} English entries: '
    '$available have neutral OEWN candidates; ${review.length - available} need a fallback.',
  );
}

Map<String, List<String>> _readOewnSenses(Directory source) {
  final byLemma = <String, List<String>>{};
  for (final file in source.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.json') ||
        name.startsWith('entries-') ||
        name == 'frames.json') {
      continue;
    }
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    for (final value in document.values) {
      if (value is! Map<String, Object?>) {
        continue;
      }
      final members = (value['members'] as List<Object?>? ?? const <Object?>[])
          .whereType<String>();
      final definitions =
          (value['definition'] as List<Object?>? ?? const <Object?>[])
              .whereType<String>();
      for (final member in members) {
        final list = byLemma.putIfAbsent(
          member.toLowerCase(),
          () => <String>[],
        );
        list.addAll(definitions);
      }
    }
  }
  return byLemma;
}

List<Map<String, Object?>> _readEnglishEntries(Directory app) {
  final entries = <Map<String, Object?>>[];
  for (final length in const [4, 5, 6]) {
    final values = jsonDecode(
      File(
        '${app.path}${Platform.pathSeparator}assets'
        '${Platform.pathSeparator}content${Platform.pathSeparator}generated'
        '${Platform.pathSeparator}vocabulary_$length.json',
      ).readAsStringSync(),
    ) as List<Object?>;
    entries.addAll(
      values.cast<Map<String, Object?>>().where(
        (entry) => entry['language'] == 'english',
      ),
    );
  }
  final supplemental = jsonDecode(
    File(
      '${app.path}${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}content${Platform.pathSeparator}curation'
      '${Platform.pathSeparator}supplemental_entries.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  entries.addAll(
    (supplemental['entries'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .where((entry) => entry['language'] == 'english'),
  );
  return entries;
}

String _definition(Map<String, Object?> entry) =>
    (((entry['definitions'] as Map<String, Object?>)['en'] as List<Object?>)
                .first
            as String)
        .trim();

bool _isNeutralDefinition(String value) {
  final definition = value.trim();
  if (definition.length < 6 || definition.length > 220) return false;
  return !RegExp(
    r'\b(?:offensive|vulgar|obscene|slur|pejorative|derogatory|ethnic|racial|sexual|genital|prostitute|rape|feces|excrement|narcotic)\b',
    caseSensitive: false,
  ).hasMatch(definition);
}

int _definitionOrder(String left, String right) {
  final leftScore = _score(left);
  final rightScore = _score(right);
  return leftScore != rightScore
      ? leftScore.compareTo(rightScore)
      : left.compareTo(right);
}

int _score(String definition) {
  var score = definition.length;
  if (RegExp(r'^(a|an|the|to)\b', caseSensitive: false).hasMatch(definition)) {
    score -= 20;
  }
  if (RegExp(
    r'\b(?:archaic|obsolete|formerly)\b',
    caseSensitive: false,
  ).hasMatch(definition)) {
    score += 100;
  }
  return score;
}
