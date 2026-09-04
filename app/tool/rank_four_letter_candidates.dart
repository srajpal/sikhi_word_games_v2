import 'dart:convert';
import 'dart:io';

/// Cross-references four-letter English entries with Open English WordNet and
/// SCOWL, then writes a deterministic editorial review queue.
///
/// Usage:
/// dart run tool/rank_four_letter_candidates.dart `oewn-directory scowl.txt`
///     [wordfreq.json]
void main(List<String> arguments) {
  if (arguments.length < 2 || arguments.length > 3) {
    stderr.writeln(
      'Usage: dart run tool/rank_four_letter_candidates.dart '
      '<oewn-directory> <scowl.txt> [wordfreq.json]',
    );
    exitCode = 64;
    return;
  }

  final oewnDirectory = Directory(arguments[0]);
  final scowlFile = File(arguments[1]);
  if (!oewnDirectory.existsSync() || !scowlFile.existsSync()) {
    stderr.writeln('The OEWN directory or SCOWL file does not exist.');
    exitCode = 66;
    return;
  }

  final scowlSizes = _readScowl(scowlFile);
  final oewn = _readOewn(oewnDirectory);
  final frequencies = arguments.length == 3
      ? (jsonDecode(File(arguments[2]).readAsStringSync())
                as Map<String, Object?>)
            .map((word, value) => MapEntry(word, (value! as num).toDouble()))
      : const <String, double>{};
  final existing = _readExistingEntries();
  final activeIds = _readActiveIds();
  final candidates = <Map<String, Object?>>[];

  final words = {...existing.keys, ...oewn.keys}.toList()..sort();
  for (final word in words) {
    final internal = existing[word];
    final senses = oewn[word] ?? const <_OewnSense>[];
    final scowlSize = scowlSizes[word];
    final zipfFrequency = frequencies[word];
    final inOewn = senses.isNotEmpty;
    final inScowl = scowlSize != null;
    final isActive = internal != null && activeIds.contains(internal.id);
    final modernSenses = senses.where((sense) => sense.hasIli).toList();
    final definition = internal?.editoriallyReviewed == true
        ? internal!.definition
        : modernSenses.firstOrNull?.definition ??
              senses.firstOrNull?.definition ??
              internal?.definition ??
              '';

    var score = 0;
    if (inOewn) score += 35;
    if (inScowl) score += 20;
    if (scowlSize != null) {
      if (scowlSize <= 35) {
        score += 30;
      } else if (scowlSize <= 50) {
        score += 22;
      } else if (scowlSize <= 60) {
        score += 14;
      } else if (scowlSize <= 70) {
        score += 7;
      }
    }
    if (internal != null) score += 5;
    if (definition.isNotEmpty) score += 5;
    if (zipfFrequency != null) score += (zipfFrequency * 10).round();

    final recommendation = switch ((
      isActive,
      inOewn,
      scowlSize,
      zipfFrequency,
    )) {
      (true, _, _, _) => 'active',
      (false, true, final size?, final frequency?)
          when size <= 50 && frequency >= 4.0 =>
        'high_priority_review',
      (false, true, final size?, final frequency?)
          when size <= 60 && frequency >= 3.0 =>
        'standard_review',
      (false, true, _, _) => 'specialist_review',
      (false, false, _, _) => 'guess_only_or_reject',
    };

    candidates.add({
      'word': word.toUpperCase(),
      'score': score,
      'recommendation': recommendation,
      'currentlyInApp': internal != null,
      'currentlyActiveAnswer': isActive,
      'openEnglishWordNet': inOewn,
      'scowlSize': scowlSize,
      'zipfFrequency': zipfFrequency,
      'partsOfSpeech':
          senses.map((sense) => sense.partOfSpeech).toSet().toList()..sort(),
      'definition': definition,
      'internalId': internal?.id,
    });
  }

  candidates.sort((a, b) {
    final score = (b['score']! as int).compareTo(a['score']! as int);
    return score != 0
        ? score
        : (a['word']! as String).compareTo(b['word']! as String);
  });
  for (var index = 0; index < candidates.length; index++) {
    candidates[index] = {'rank': index + 1, ...candidates[index]};
  }

  final counts = <String, int>{};
  for (final candidate in candidates) {
    final key = candidate['recommendation']! as String;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final document = {
    'schemaVersion': 1,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'scope': 'Four-letter English candidate review',
    'sources': [
      {
        'name': 'Open English WordNet 2025',
        'url': 'https://en-word.net/downloads',
        'purpose': 'lemma, part-of-speech, and definition confirmation',
      },
      {
        'name': 'SCOWL v2',
        'url': 'https://github.com/engramtech/scowl',
        'purpose': 'spelling validity and commonness-size tier',
      },
      if (frequencies.isNotEmpty)
        {
          'name': 'wordfreq 3.1.1',
          'url': 'https://github.com/rspeer/wordfreq',
          'purpose': 'modern usage-frequency ranking',
        },
    ],
    'rankingRules': {
      'note':
          'Ranking is a review aid, not automatic editorial approval. Lower '
          'SCOWL sizes are generally more common; OEWN confirms lexical senses.',
      'highPriorityReview':
          'OEWN-confirmed, SCOWL size 50 or lower, and Zipf frequency 4+',
      'standardReview':
          'OEWN-confirmed, SCOWL size 60 or lower, and Zipf frequency 3+',
      'specialistReview': 'OEWN-confirmed but less common or absent from SCOWL',
    },
    'counts': counts,
    'candidates': candidates,
  };

  final reportDirectory = Directory('../reports/content')
    ..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  File('${reportDirectory.path}/four_letter_candidates.json')
      .writeAsStringSync('${encoder.convert(document)}\n');
  File('${reportDirectory.path}/four_letter_candidates.md')
      .writeAsStringSync(_toMarkdown(candidates, counts));
  stdout.writeln('Ranked ${candidates.length} English four-letter candidates.');
  stdout.writeln(counts);
}

Map<String, int> _readScowl(File file) {
  final result = <String, int>{};
  final pattern = RegExp(r'^(\d+): ([A-Za-z]{4})(?:\s|$)');
  for (final line in file.readAsLinesSync()) {
    final match = pattern.firstMatch(line);
    if (match == null) continue;
    final sourceWord = match.group(2)!;
    if (sourceWord != sourceWord.toLowerCase()) continue;
    final word = sourceWord.toLowerCase();
    final size = int.parse(match.group(1)!);
    final current = result[word];
    if (current == null || size < current) result[word] = size;
  }
  return result;
}

Map<String, List<_OewnSense>> _readOewn(Directory directory) {
  final wordSynsets = <String, List<String>>{};
  for (final file in directory.listSync().whereType<File>().where(
    (file) => file.uri.pathSegments.last.startsWith('entries-'),
  )) {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    for (final entry in decoded.entries) {
      if (!RegExp(r'^[a-z]{4}$').hasMatch(entry.key)) continue;
      final parts = entry.value! as Map<String, Object?>;
      final ids = <String>[];
      for (final part in parts.values.whereType<Map<String, Object?>>()) {
        final senses = part['sense'];
        if (senses is! List<Object?>) continue;
        for (final item in senses) {
          ids.add((item! as Map<String, Object?>)['synset']! as String);
        }
      }
      wordSynsets[entry.key] = ids;
    }
  }

  final wanted = wordSynsets.values.expand((ids) => ids).toSet();
  final synsets = <String, _OewnSense>{};
  for (final file
      in directory
          .listSync()
          .whereType<File>()
          .where((file) => !file.uri.pathSegments.last.startsWith('entries-'))
          .where((file) => file.path.endsWith('.json'))) {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    for (final entry in decoded.entries) {
      if (!wanted.contains(entry.key)) continue;
      final data = entry.value! as Map<String, Object?>;
      final definitions = data['definition'] as List<Object?>?;
      if (definitions == null || definitions.isEmpty) continue;
      synsets[entry.key] = _OewnSense(
        partOfSpeech: data['partOfSpeech']! as String,
        definition: definitions.first! as String,
        hasIli: data['ili'] is String,
      );
    }
  }
  return {
    for (final entry in wordSynsets.entries)
      entry.key: entry.value
          .map((id) => synsets[id])
          .whereType<_OewnSense>()
          .toList(),
  };
}

Map<String, _InternalEntry> _readExistingEntries() {
  final decoded = jsonDecode(
    File('assets/content/generated/vocabulary_4.json').readAsStringSync(),
  ) as List<Object?>;
  final supplemental = jsonDecode(
    File('assets/content/curation/supplemental_entries.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  decoded.addAll(supplemental['entries']! as List<Object?>);
  final entries = <String, _InternalEntry>{};
  for (final item in decoded) {
    final data = item! as Map<String, Object?>;
    if (data['language'] != 'english') continue;
    entries[(data['latin']! as String).toLowerCase()] = _InternalEntry(
      id: data['id']! as String,
      definition:
          (((data['definitions']! as Map<String, Object?>)['en']!
                      as List<Object?>)
                  .first!
              as String),
      editoriallyReviewed: data['reviewStatus'] == 'editorApproved',
    );
  }
  final overrides = jsonDecode(
    File('assets/content/curation/editorial_overrides.json').readAsStringSync(),
  ) as Map<String, Object?>;
  for (final item in overrides['entries']! as List<Object?>) {
    final override = item! as Map<String, Object?>;
    final id = override['id']! as String;
    final definition = override['englishDefinition'] as String?;
    if (definition == null) continue;
    final matching = entries.entries.where((entry) => entry.value.id == id);
    if (matching.isEmpty) continue;
    final match = matching.single;
    entries[match.key] = _InternalEntry(
      id: id,
      definition: definition,
      editoriallyReviewed: true,
    );
  }
  return entries;
}

Set<String> _readActiveIds() {
  final decoded = jsonDecode(
    File('assets/content/curation/starter_solutions.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return (decoded['solutionIds']! as List<Object?>).cast<String>().toSet();
}

String _toMarkdown(
  List<Map<String, Object?>> candidates,
  Map<String, int> counts,
) {
  final buffer = StringBuffer()
    ..writeln('# Four-letter English candidate ranking')
    ..writeln()
    ..writeln(
      'Generated from Open English WordNet 2025 and SCOWL v2. This is a '
      'machine-ranked editorial queue, not automatic approval.',
    )
    ..writeln()
    ..writeln('## Summary')
    ..writeln();
  for (final entry in counts.entries) {
    buffer.writeln('- ${entry.key}: ${entry.value}');
  }
  buffer
    ..writeln()
    ..writeln('## Ranked candidates')
    ..writeln()
    ..writeln(
      '| Rank | Word | Score | Zipf | SCOWL | OEWN | Status | Definition |',
    )
    ..writeln('| ---: | --- | ---: | ---: | ---: | :---: | --- | --- |');
  for (final candidate in candidates) {
    final definition = (candidate['definition']! as String)
        .replaceAll('|', r'\|')
        .replaceAll(RegExp(r'\s+'), ' ');
    buffer.writeln(
      '| ${candidate['rank']} | ${candidate['word']} | ${candidate['score']} '
      '| ${candidate['zipfFrequency'] ?? '—'} '
      '| ${candidate['scowlSize'] ?? '—'} '
      '| ${candidate['openEnglishWordNet'] == true ? 'yes' : 'no'} '
      '| ${candidate['recommendation']} | $definition |',
    );
  }
  return buffer.toString();
}

class _OewnSense {
  const _OewnSense({
    required this.partOfSpeech,
    required this.definition,
    required this.hasIli,
  });

  final String partOfSpeech;
  final String definition;
  final bool hasIli;
}

class _InternalEntry {
  const _InternalEntry({
    required this.id,
    required this.definition,
    required this.editoriallyReviewed,
  });

  final String id;
  final String definition;
  final bool editoriallyReviewed;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
