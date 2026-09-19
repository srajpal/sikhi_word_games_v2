import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'content/punjabi_quality.dart';

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
  final uniquePools = <String, Set<String>>{};
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
    final nonEnglishDefinitionText = definitions.entries
        .where((entry) => entry.key != 'en')
        .map((entry) => entry.value)
        .whereType<List<Object?>>()
        .expand((values) => values)
        .whereType<String>();
    if (nonEnglishDefinitionText.any((text) => text.trim().isNotEmpty)) {
      throw StateError('$id leaks a non-English definition.');
    }
    final solution = entry['solutionEligible']! as bool;
    final accepted = entry['acceptedGuess']! as bool;
    if (definition.isEmpty) {
      hidden++;
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
    if (language == 'panjabi' && definition.isNotEmpty) {
      final quality = assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: gurmukhi ?? '',
          latin: latin,
          englishDefinition: definition,
        ),
      );
      if (!quality.isPromotionCandidate) {
        throw StateError('$id has an unchecked Punjabi definition.');
      }
    }
    if (!solution) continue;
    final latinMode = language == 'english' ? 'english' : 'romanized';
    addPlayableSpelling(
      pools,
      uniquePools,
      mode: latinMode,
      graphemeLength: latin.characters.length,
      spelling: latin,
    );
    addPlayableSpelling(
      pools,
      uniquePools,
      mode: 'mixed',
      graphemeLength: latin.characters.length,
      spelling: latin,
    );
    if (language == 'panjabi' && gurmukhi != null) {
      addPlayableSpelling(
        pools,
        uniquePools,
        mode: 'gurmukhi',
        graphemeLength: gurmukhi.characters.length,
        spelling: gurmukhi,
      );
    }
  }
  if (invalidSolutions != 0) {
    throw StateError('$invalidSolutions solutions have hidden definitions.');
  }
  for (final mode in const ['english', 'romanized', 'mixed', 'gurmukhi']) {
    for (final length in const [4, 5, 6]) {
      final count = pools['$mode:$length'] ?? 0;
      final unique = uniquePools['$mode:$length']?.length ?? 0;
      stdout.writeln('$mode/$length: $count records, $unique unique spellings');
      if (unique < 300) {
        throw StateError('$mode/$length has only $unique unique answers.');
      }
    }
  }
  stdout.writeln(
    'Release content: ${entries.length} records, $sourced sourced definitions, '
    '$hidden hidden definitions, no unsourced solutions.',
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

void addPlayableSpelling(
  Map<String, int> rawPools,
  Map<String, Set<String>> uniquePools, {
  required String mode,
  required int graphemeLength,
  required String spelling,
}) {
  final key = '$mode:$graphemeLength';
  _add(rawPools, key);
  uniquePools.putIfAbsent(key, () => <String>{}).add(spelling);
}
