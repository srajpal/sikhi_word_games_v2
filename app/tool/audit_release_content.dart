import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

void main() {
  final entries = <Map<String, Object?>>[];
  for (final length in const [4, 5, 6]) {
    entries.addAll(
      (jsonDecode(
        File('assets/content/release/vocabulary_$length.json')
            .readAsStringSync(),
      ) as List<Object?>).cast<Map<String, Object?>>(),
    );
  }
  var sourced = 0;
  var hidden = 0;
  var invalidSolutions = 0;
  final ids = <String>{};
  final pools = <String, int>{};
  for (final entry in entries) {
    final id = entry['id']! as String;
    if (!ids.add(id)) throw StateError('Duplicate release ID: $id');
    final definitions = entry['definitions']! as Map<String, Object?>;
    final englishDefinitions = definitions['en']! as List<Object?>;
    if (englishDefinitions.length != 1 || englishDefinitions.first is! String) {
      throw StateError('$id has malformed English definitions.');
    }
    final definition = englishDefinitions.single as String;
    final sources = (entry['sources']! as List<Object?>).cast<String>();
    final trusted = sources.any(_trustedSource);
    final allDefinitionText = definitions.values
        .whereType<List<Object?>>()
        .expand((values) => values)
        .whereType<String>();
    final solution = entry['solutionEligible']! as bool;
    final accepted = entry['acceptedGuess']! as bool;
    if (definition.isEmpty) {
      hidden++;
      if (allDefinitionText.any((text) => text.trim().isNotEmpty)) {
        throw StateError('$id leaks a non-English legacy definition.');
      }
    } else {
      sourced++;
      if (!trusted) {
        throw StateError('$id has an untrusted visible definition.');
      }
    }
    if (solution &&
        (!accepted ||
            definition.trim().isEmpty ||
            !trusted ||
            _referenceOnly.hasMatch(definition.trim()))) {
      invalidSolutions++;
    }
    final latin = entry['latin']! as String;
    final gurmukhi = entry['gurmukhi'] as String?;
    final language = entry['language']! as String;
    final lengths = entry['lengths']! as Map<String, Object?>;
    if (lengths['latin'] != latin.characters.length ||
        lengths['gurmukhi'] != gurmukhi?.characters.length) {
      throw StateError('$id has stale grapheme lengths.');
    }
    if (!solution) continue;
    _add(
      pools,
      '${language == 'english' ? 'english' : 'romanized'}:${latin.characters.length}',
    );
    _add(pools, 'mixed:${latin.characters.length}');
    if (language == 'panjabi' && gurmukhi != null) {
      _add(pools, 'gurmukhi:${gurmukhi.characters.length}');
    }
  }
  if (invalidSolutions != 0) {
    throw StateError('$invalidSolutions solutions have hidden definitions.');
  }
  for (final mode in const ['english', 'romanized', 'mixed', 'gurmukhi']) {
    for (final length in const [4, 5, 6]) {
      final count = pools['$mode:$length'] ?? 0;
      stdout.writeln('$mode/$length: $count');
      if (count < 6) throw StateError('$mode/$length has only $count answers.');
    }
  }
  stdout.writeln(
    'Release content: ${entries.length} records, $sourced sourced definitions, '
    '$hidden hidden legacy definitions, no unsourced solutions.',
  );
}

bool _trustedSource(String source) =>
    source == 'Open English WordNet 2025 (CC BY 4.0)' ||
    source.startsWith(
      'Mahan Kosh multilingual dataset; commit '
      'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
    ) ||
    source ==
        'Project editorial definition; original text for Sikhi Word Games';

final _referenceOnly = RegExp(
  r'^(?:see|of|plural|past tense|present participle|alternative spelling)\b',
  caseSensitive: false,
);

void _add(Map<String, int> counts, String key) =>
    counts.update(key, (value) => value + 1, ifAbsent: () => 1);
