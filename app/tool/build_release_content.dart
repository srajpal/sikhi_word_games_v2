import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'package:sikhi_word_games_v2/core/content/vocabulary_licenses.dart';

import 'content/punjabi_quality.dart';
import 'content/vocabulary_checks.dart';

/// Builds the only vocabulary files intended for distribution.
/// Authoring imports and curation records remain unchanged.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  final shards = <String, List<Map<String, Object?>>>{
    'english': [],
    'punjabi': [],
  };
  final seen = <String>{};
  for (final language in ['english', 'punjabi']) {
    final entries = jsonDecode(
      File('assets/content/generated/${language}_v2.json').readAsStringSync(),
    ) as List<Object?>;
    for (final item in entries) {
      final raw = Map<String, Object?>.from(item! as Map<String, Object?>);
      final id = raw['id']! as String;
      if (!(id.startsWith('en_v2_') || id.startsWith('panjabi_v2_'))) {
        throw StateError('Legacy vocabulary cannot enter a v2 release: $id');
      }
      ensureUniqueVocabularyId(seen, raw);
      final entry = buildReleaseEntry(raw);
      // Source evidence stays in the authoring snapshot and deterministic report.
      entry.remove('evidence');
      shards[language]!.add(entry);
    }
  }
  final output = Directory('assets/content/release')
    ..createSync(recursive: true);
  var trusted = 0;
  var hidden = 0;
  var stale = 0;
  for (final shard in shards.entries) {
    shard.value.sort(
      (a, b) => (a['id']! as String).compareTo(b['id']! as String),
    );
    for (final entry in shard.value) {
      final definition =
          ((entry['definitions']! as Map<String, Object?>)['en']!
                      as List<Object?>)
                  .first
              as String;
      definition.isEmpty ? hidden++ : trusted++;
    }
    final file = File('${output.path}/${shard.key}_v2.json');
    final encoded = jsonEncode(shard.value);
    if (!file.existsSync() || file.readAsStringSync() != encoded) stale++;
    if (write) file.writeAsStringSync(encoded);
  }
  for (final length in [4, 5, 6]) {
    final retired = File('${output.path}/vocabulary_$length.json');
    if (retired.existsSync()) {
      if (write) {
        retired.deleteSync();
      } else {
        stale++;
      }
    }
  }
  stdout.writeln(
    'Built ${trusted + hidden} release records: $trusted sourced definitions, '
    '$hidden hidden definitions; $stale stale shards.',
  );
  if (check && stale != 0) {
    throw StateError(
      'Release content is stale. Run build_release_content.dart --write.',
    );
  }
}

void ensureUniqueVocabularyId(Set<String> seen, Map<String, Object?> entry) {
  final id = entry['id']! as String;
  if (!seen.add(id)) throw FormatException('Duplicate vocabulary ID: $id');
}

Map<String, Object?> buildReleaseEntry(
  Map<String, Object?> sourceEntry, {
  Map<String, Object?>? override,
  Set<String> solutionIds = const {},
  Map<String, Object?>? hold,
}) {
  final entry = Map<String, Object?>.from(sourceEntry);
  final id = entry['id']! as String;
  final definitions = Map<String, Object?>.from(
    entry['definitions']! as Map<String, Object?>,
  );
  var definition = (definitions['en']! as List<Object?>).first as String;
  var accepted = entry['acceptedGuess']! as bool;
  var solution = entry['solutionEligible']! as bool || solutionIds.contains(id);
  var reviewStatus = entry['reviewStatus']! as String;
  var sources = (entry['sources']! as List<Object?>).cast<String>().toList();
  if (override != null) {
    if (override['englishDefinition'] case final String replacement) {
      definition = replacement;
      if (override['source'] == null) {
        sources = ['Legacy definition source unclear; not distributed'];
      }
    }
    if (override['latin'] case final String latin) entry['latin'] = latin;
    if (override['gurmukhi'] case final String gurmukhi) {
      entry['gurmukhi'] = gurmukhi;
    }
    accepted = override['acceptedGuess'] as bool? ?? accepted;
    solution = override['solutionEligible'] as bool? ?? solution;
    reviewStatus = override['reviewStatus'] as String? ?? reviewStatus;
    if (override['source'] case final String source) sources = [source];
    if (override['reviewMethod'] case final String method) {
      entry['reviewMethod'] = method;
    }
  }
  final latin = entry['latin']! as String;
  final gurmukhi = entry['gurmukhi'] as String?;
  entry['lengths'] = {
    'latin': latin.characters.length,
    'gurmukhi': gurmukhi?.characters.length,
  };
  final trusted = sources.any(isTrustedVocabularySource);
  final standalone =
      definition.trim().isNotEmpty &&
      !_referenceOnly.hasMatch(definition.trim());
  definitions
    ..clear()
    ..addAll({
      'en': [trusted ? definition : ''],
      'pa': <String>[],
    });
  entry['definitions'] = definitions;
  entry['acceptedGuess'] = accepted;
  final passesPunjabiPolicy =
      entry['language'] != 'panjabi' ||
      assessPunjabiQuality(
        PunjabiQualityCandidate(
          gurmukhi: gurmukhi ?? '',
          latin: latin,
          englishDefinition: definition,
        ),
      ).isPromotionCandidate;
  if (!passesPunjabiPolicy) definitions['en'] = [''];
  entry['solutionEligible'] =
      accepted && trusted && standalone && solution && passesPunjabiPolicy;
  entry['reviewStatus'] = reviewStatus;
  entry['sources'] = sources;
  return hold == null ? entry : applyVocabularyHold(entry, hold);
}

final _referenceOnly = RegExp(
  r'^(?:see(?: also)?|plural of|past tense of|present participle of|alternative spelling of)\b|^of\s+\S+\.?$',
  caseSensitive: false,
);
