import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

/// Builds the only vocabulary files intended for distribution.
/// Authoring imports and curation records remain unchanged.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  final solutionIds =
      (_read('assets/content/curation/starter_solutions.json')['solutionIds']!
              as List<Object?>)
          .cast<String>()
          .toSet();
  final overrides = <String, Map<String, Object?>>{
    for (final item
        in _read('assets/content/curation/editorial_overrides.json')['entries']!
            as List<Object?>)
      (item! as Map<String, Object?>)['id']! as String:
          item as Map<String, Object?>,
  };
  final shards = <int, List<Map<String, Object?>>>{1: [], 2: [], 3: []};
  final seen = <String>{};
  for (final shard in shards.keys) {
    final entries = jsonDecode(
      File('assets/content/generated/vocabulary_${shard + 3}.json')
          .readAsStringSync(),
    ) as List<Object?>;
    for (final item in entries) {
      final entry = Map<String, Object?>.from(item! as Map<String, Object?>);
      shards[shard]!.add(_releaseEntry(entry, overrides, solutionIds));
      seen.add(entry['id']! as String);
    }
  }
  final supplemental =
      _read('assets/content/curation/supplemental_entries.json')['entries']!
          as List<Object?>;
  for (final item in supplemental) {
    final entry = Map<String, Object?>.from(item! as Map<String, Object?>);
    if (!seen.add(entry['id']! as String)) {
      throw FormatException('Duplicate vocabulary ID: ${entry['id']}');
    }
    final lengths = entry['lengths']! as Map<String, Object?>;
    final latin = lengths['latin']! as int;
    final gurmukhi = lengths['gurmukhi'] as int?;
    final shard = latin >= 4 && latin <= 6
        ? latin - 3
        : (gurmukhi == 5 ? 2 : 3);
    shards[shard]!.add(_releaseEntry(entry, overrides, solutionIds));
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
    final file = File('${output.path}/vocabulary_${shard.key + 3}.json');
    final encoded = jsonEncode(shard.value);
    if (!file.existsSync() || file.readAsStringSync() != encoded) stale++;
    if (write) file.writeAsStringSync(encoded);
  }
  stdout.writeln(
    'Built ${trusted + hidden} release records: $trusted sourced definitions, '
    '$hidden hidden legacy definitions; $stale stale shards.',
  );
  if (check && stale != 0) {
    throw StateError(
      'Release content is stale. Run build_release_content.dart --write.',
    );
  }
}

Map<String, Object?> _releaseEntry(
  Map<String, Object?> sourceEntry,
  Map<String, Map<String, Object?>> overrides,
  Set<String> solutionIds,
) {
  final entry = Map<String, Object?>.from(sourceEntry);
  final id = entry['id']! as String;
  final override = overrides[id];
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
    if (override['gurmukhi'] case final String gurmukhi) {
      entry['gurmukhi'] = gurmukhi;
      final lengths = Map<String, Object?>.from(
        entry['lengths']! as Map<String, Object?>,
      );
      lengths['gurmukhi'] = gurmukhi.characters.length;
      entry['lengths'] = lengths;
    }
    accepted = override['acceptedGuess'] as bool? ?? accepted;
    solution = override['solutionEligible'] as bool? ?? solution;
    reviewStatus = override['reviewStatus'] as String? ?? reviewStatus;
    if (override['source'] case final String source) sources = [source];
  }
  final trusted = sources.any(_trustedSource);
  final standalone =
      definition.trim().isNotEmpty &&
      !_referenceOnly.hasMatch(definition.trim());
  if (trusted) {
    definitions['en'] = [definition];
  } else {
    definitions
      ..clear()
      ..addAll({
        'en': [''],
        'pa': <String>[],
      });
  }
  entry['definitions'] = definitions;
  entry['acceptedGuess'] = accepted;
  entry['solutionEligible'] = trusted && standalone && solution;
  entry['reviewStatus'] = reviewStatus;
  entry['sources'] = sources;
  return entry;
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

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
