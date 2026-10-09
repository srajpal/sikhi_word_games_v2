import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/language/gurmukhi_normalization.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/word_bridges/domain/word_bridges_content.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_definition_quality.dart';

import 'build_release_content.dart' as release;
import 'dictionary_v2.dart' as dictionary_v2;
import 'content/vocabulary_checks.dart';
import 'content/vocabulary_sources.dart';

const holdPath = 'assets/content/curation/vocabulary_holds.json';
const reportPath = '../reports/content/vocabulary_recheck.json';

/// One offline workflow: effective content -> pinned source/quality checks ->
/// grouped exceptions -> reversible holds -> release checks. No answer promotion.
void main(List<String> arguments) => dictionary_v2.main(arguments);

// Retained authoring-archive implementation for historical investigations only.
void legacyPipeline(List<String> arguments) {
  if (arguments.any((a) => !['--write', '--check'].contains(a)) ||
      arguments.contains('--write') && arguments.contains('--check')) {
    throw ArgumentError('Usage: vocabulary_pipeline.dart [--write | --check]');
  }
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  final sourceFiles = verifySourceLock(
    readObject('tool/content/source_lock.json'),
  );
  final sources = VocabularySources.load();
  final inputs = <String>[
    for (final length in [4, 5, 6])
      'assets/content/generated/vocabulary_$length.json',
    'assets/content/curation/supplemental_entries.json',
    'assets/content/curation/editorial_overrides.json',
    'assets/content/curation/starter_solutions.json',
    'tool/content/source_lock.json',
    'tool/vocabulary_pipeline.dart',
    'tool/build_release_content.dart',
    'tool/content/vocabulary_checks.dart',
    'tool/content/vocabulary_sources.dart',
    'tool/content/punjabi_quality.dart',
    'tool/content/mahan_kosh_text.dart',
    'lib/features/word_bridges/domain/word_bridges_content.dart',
    'lib/features/word_quest/domain/word_quest_definition_quality.dart',
    'lib/core/language/gurmukhi_normalization.dart',
  ];
  final decisions = <String, Map<String, Object?>>{};
  for (final item in readObject(inputs[4])['entries']! as List) {
    final decision = item as Map<String, Object?>;
    final id = decision['id']! as String;
    if (decisions.containsKey(id)) throw StateError('Duplicate decision: $id');
    decisions[id] = decision;
  }
  final starters = (readObject(inputs[5])['solutionIds']! as List)
      .cast<String>()
      .toSet();
  final raw = <Map<String, Object?>>[
    for (final path in inputs.take(3))
      ...(jsonDecode(File(path).readAsStringSync()) as List)
          .cast<Map<String, Object?>>(),
    ...(readObject(inputs[3])['entries']! as List).cast<Map<String, Object?>>(),
  ];
  final seen = <String>{};
  final holds = <Map<String, Object?>>[];
  final queue = <String, Map<String, Object?>>{};
  final projected = <Map<String, Object?>>[];
  final sampleGroups = <String, List<Map<String, Object?>>>{};
  final counts = <String, int>{};
  void count(String key) => counts.update(key, (n) => n + 1, ifAbsent: () => 1);
  for (final entry in raw) {
    release.ensureUniqueVocabularyId(seen, entry);
    final id = entry['id']! as String;
    final effective = release.buildReleaseEntry(
      entry,
      override: decisions[id],
      solutionIds: starters,
    );
    final definition = englishDefinition(effective);
    count('authoringRecords');
    if (definition.isEmpty) {
      count('alreadyHiddenDefinitions');
      projected.add(effective);
      continue;
    }
    count('visibleBeforeHolds');
    final reasons = definitionHoldReasons(definition);
    final attribution = (effective['sources']! as List).cast<String>();
    final english = effective['language'] == 'english';
    final word = effective['latin']! as String;
    final editorial = attribution.contains(editorialLabel);
    String evidence;
    if (english && attribution.contains(oewnLabel)) {
      final matches = sources.matchesEnglish(word, definition);
      evidence = matches ? 'exact_oewn_lemma_and_sense' : 'oewn_sense_mismatch';
      if (!matches) reasons.add(evidence);
    } else if (!english) {
      final matches = sources.matchesPunjabi(
        word: effective['gurmukhi']! as String,
        definition: definition,
        decision: decisions[id],
        editorial: editorial,
      );
      evidence = matches
          ? (editorial
                ? 'source_linked_editorial_paraphrase'
                : 'exact_mahan_kosh_headword_and_cleaned_sense')
          : (decisions[id]?['sourceId'] == null
                ? 'missing_punjabi_source_link'
                : 'mahan_kosh_source_mismatch');
      if (!matches) reasons.add(evidence);
    } else if (editorial) {
      evidence = 'original_editorial_text';
    } else {
      evidence = 'unsupported_language_source';
      reasons.add(evidence);
    }
    count(evidence);
    if (reasons.isNotEmpty) {
      reasons.sort();
      final hold = <String, Object?>{
        'id': id,
        'fingerprint': vocabularyFingerprint(effective),
        'reasons': reasons,
      };
      holds.add(hold);
      projected.add(applyVocabularyHold(effective, hold));
      for (final reason in reasons) {
        count('hold:$reason');
      }
      final key = jsonEncode([
        effective['language'],
        word,
        effective['gurmukhi'],
        definition,
        reasons,
      ]);
      final group = queue.putIfAbsent(
        key,
        () => {
          'ids': <String>[],
          'language': effective['language'],
          'word': word,
          'gurmukhi': effective['gurmukhi'],
          'definition': definition,
          'reasons': reasons,
          'wasAnswer': false,
          'candidates': english
              ? sources
                    .englishCandidates(word)
                    .where((s) => definitionHoldReasons(s.definition).isEmpty)
                    .map((s) => s.toJson())
                    .toList()
              : <Object?>[],
        },
      );
      (group['ids']! as List<String>).add(id);
      if (effective['solutionEligible'] == true) group['wasAnswer'] = true;
    } else {
      projected.add(effective);
      final stratum = '${effective['language']}:$evidence';
      sampleGroups.putIfAbsent(stratum, () => []).add(effective);
    }
  }
  holds.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
  if (!seen.containsAll(decisions.keys) || !seen.containsAll(starters)) {
    throw StateError('Curation references unknown vocabulary IDs.');
  }
  final pools = measurePools(projected);
  final failures = <String>[
    for (final mode in ['english', 'romanized', 'mixed', 'gurmukhi'])
      for (final length in [4, 5, 6])
        if ((pools['$mode:$length'] ?? 0) < 300)
          '$mode:$length needs 300 unique answers',
    for (final mode in ['english', 'romanized', 'mixed', 'gurmukhi'])
      for (final length in [4, 5, 6])
        if ((pools['quest:$mode:$length'] ?? 0) < 250)
          'Quest $mode:$length needs 250 usable clues',
  ];
  final bridges = WordBridgesContent(projected.map(VocabularyEntry.fromJson));
  for (final mode in [
    LanguageMode.english,
    LanguageMode.romanizedPanjabi,
    LanguageMode.gurmukhi,
  ]) {
    if (bridges.decksFor(mode).length != 2) {
      failures.add('Jodo ${mode.name} loses a starter deck');
    }
  }
  final exceptions = queue.values.toList()
    ..sort((a, b) {
      final priority =
          (b['wasAnswer'] == true ? 1 : 0) - (a['wasAnswer'] == true ? 1 : 0);
      return priority != 0
          ? priority
          : '${a['word']}'.compareTo('${b['word']}');
    });
  final sample = <Map<String, Object?>>[];
  for (final stratum in sampleGroups.entries) {
    // Deduplicate aliases, then choose by hash rather than alphabetical bias.
    final unique = <String, Map<String, Object?>>{};
    for (final entry in stratum.value) {
      unique.putIfAbsent(
        jsonEncode([
          entry['latin'],
          entry['gurmukhi'],
          englishDefinition(entry),
        ]),
        () => entry,
      );
    }
    final values = unique.values.toList()
      ..sort(
        (a, b) => vocabularyFingerprint(a).compareTo(vocabularyFingerprint(b)),
      );
    for (final entry in values.take(20)) {
      sample.add({
        'stratum': stratum.key,
        'id': entry['id'],
        'word': entry['latin'],
        'gurmukhi': entry['gurmukhi'],
        'definition': englishDefinition(entry),
      });
    }
  }
  final document = {
    'schemaVersion': 1,
    'ruleVersion': vocabularyRuleVersion,
    'inputs': {for (final path in inputs) path: textFileHash(path)},
    'sourceFiles': sourceFiles,
    'summary': counts,
    'heldRecords': holds.length,
    'exceptionGroups': exceptions.length,
    'projectedUniquePools': pools,
    'coverageFailures': failures,
    'exceptions': exceptions,
    'semanticSample': sample,
    'limitations': [
      'Exact source matching does not prove meaning, familiarity, pronunciation or age suitability.',
      'Editorial paraphrases have source links, not automatic semantic verification.',
      'Risk rules are conservative and incomplete; samples are not certification.',
      'Valid guess spellings and explicit editorial exclusions are preserved. No new answers are approved.',
    ],
  };
  final holdDocument = {
    'schemaVersion': 1,
    'ruleVersion': vocabularyRuleVersion,
    'entries': holds,
  };
  const encoder = JsonEncoder.withIndent('  ');
  final reportText = '${encoder.convert(document)}\n';
  final holdText = '${encoder.convert(holdDocument)}\n';
  stdout.writeln(
    jsonEncode({
      'summary': counts,
      'heldRecords': holds.length,
      'exceptionGroups': exceptions.length,
      'coverageFailures': failures,
      'projectedUniquePools': pools,
    }),
  );
  if (check) {
    for (final item in {reportPath: reportText, holdPath: holdText}.entries) {
      if (!File(item.key).existsSync() ||
          File(item.key).readAsStringSync().replaceAll('\r\n', '\n') !=
              item.value) {
        throw StateError(
          'Stale vocabulary recheck: ${item.key}. Run the pipeline --write.',
        );
      }
    }
  } else {
    Directory('../reports/content').createSync(recursive: true);
    File(reportPath).writeAsStringSync(reportText);
  }
  if ((write || check) && failures.isNotEmpty) {
    throw StateError(
      'Holds require pool/deck repairs before release: $failures',
    );
  }
  if (write) File(holdPath).writeAsStringSync(holdText);
  if (write || check) {
    release.main([write ? '--write' : '--check']);
    final audit = Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/audit_release_content.dart',
    ]);
    stdout.write(audit.stdout);
    stderr.write(audit.stderr);
    if (audit.exitCode != 0) throw StateError('Release audit failed.');
  }
}

Map<String, int> measurePools(Iterable<Map<String, Object?>> entries) {
  final pools = <String, Set<String>>{};
  void add(String mode, String word) {
    final size = word.characters.length;
    if (size >= 4 && size <= 6) {
      pools.putIfAbsent('$mode:$size', () => {}).add(word);
    }
  }

  for (final entry in entries.where(
    (e) => e['acceptedGuess'] == true && e['solutionEligible'] == true,
  )) {
    final latin = (entry['latin']! as String).trim().toUpperCase();
    final mode = entry['language'] == 'english' ? 'english' : 'romanized';
    add(mode, latin);
    add('mixed', latin);
    if (WordQuestDefinitionQuality.usableClue(
          answer: latin,
          clue: englishDefinition(entry),
        ) !=
        null) {
      add('quest:$mode', latin);
      add('quest:mixed', latin);
    }
    if (entry['language'] == 'panjabi') {
      final word = normalizeGurmukhi(entry['gurmukhi']! as String);
      add('gurmukhi', word);
      if (WordQuestDefinitionQuality.usableClue(
            answer: word,
            clue: englishDefinition(entry),
          ) !=
          null) {
        add('quest:gurmukhi', word);
      }
    }
  }
  return {for (final item in pools.entries) item.key: item.value.length};
}
