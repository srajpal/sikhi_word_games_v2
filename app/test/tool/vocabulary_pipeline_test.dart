import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_release_content.dart';
import '../../tool/content/mahan_kosh_text.dart';
import '../../tool/content/vocabulary_checks.dart';
import '../../tool/content/vocabulary_sources.dart';
import '../../tool/vocabulary_pipeline.dart';

void main() {
  test(
    'quarantines references and stigma without rejecting ordinary definitions',
    () {
      expect(definitionHoldReasons('someone deranged and possibly dangerous'), [
        'sensitive_or_stigmatizing',
      ]);
      expect(definitionHoldReasons('variant of orchard'), ['reference_only']);
      expect(definitionHoldReasons('See orchard.'), ['reference_only']);
      expect(definitionHoldReasons('water\uFFFD'), ['corrupt_definition']);
      expect(definitionHoldReasons('a small stream of water'), isEmpty);
      expect(definitionHoldReasons('seeds used for food'), isEmpty);
      expect(
        definitionHoldReasons('of or relating to living organisms'),
        isEmpty,
      );
      expect(definitionHoldReasons('of persons; feeling cold'), isEmpty);
      expect(definitionHoldReasons('see with attention'), isEmpty);
    },
  );

  test('holds hide definitions and answers while retaining IDs, guesses and status', () {
    final entry = _entry();
    final hold = {'fingerprint': vocabularyFingerprint(entry)};
    final result = buildReleaseEntry(entry, hold: hold);
    expect(result['acceptedGuess'], isTrue);
    expect(result['solutionEligible'], isFalse);
    expect(englishDefinition(result), isEmpty);
    expect(result['id'], entry['id']);
    expect(result['reviewStatus'], 'machineChecked');
    expect(entry['solutionEligible'], isTrue);
    expect(englishDefinition(entry), 'a volume of written pages');
  });

  test('stale holds fail closed after spelling, sense or source changes', () {
    final entry = _entry();
    final hold = {'fingerprint': vocabularyFingerprint(entry)};
    for (final change in [
      {'latin': 'BOOKS'},
      {'englishDefinition': 'a record of bets', 'source': oewnLabel},
      {'source': editorialLabel},
    ]) {
      expect(
        () => buildReleaseEntry(entry, override: change, hold: hold),
        throwsStateError,
      );
    }
  });

  test('holds cannot reopen an explicit exclusion or starter answer', () {
    final excluded = buildReleaseEntry(
      _entry(),
      override: {'acceptedGuess': false, 'solutionEligible': false},
    );
    final result = buildReleaseEntry(
      _entry(),
      override: {'acceptedGuess': false, 'solutionEligible': false},
      solutionIds: {'english_book'},
      hold: {'fingerprint': vocabularyFingerprint(excluded)},
    );
    expect(result['acceptedGuess'], isFalse);
    expect(result['solutionEligible'], isFalse);
  });

  test('source checks require exact lemma-sense membership and valid Punjabi evidence', () {
    const commit =
        'Mahan Kosh multilingual dataset; commit fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6; entry one';
    final sources = VocabularySources.fromIndexes(
      english: {
        'book': [const SourceSense('synset-book', 'a volume of written pages')],
      },
      punjabi: {
        'one': {'hw': 'ਬਾਗ'},
      },
      punjabiEnglish: {
        'one': {
          'definitions': ['n orchard.'],
        },
      },
    );
    expect(sources.matchesEnglish('BOOK', 'a volume of written pages'), isTrue);
    expect(
      sources.matchesEnglish('DOOR', 'a volume of written pages'),
      isFalse,
    );
    expect(sources.matchesEnglish('BOOK', 'a record of bets'), isFalse);
    final decision = {
      'sourceId': 'one',
      'sourceSenseIndex': 0,
      'verificationSource': commit,
    };
    expect(
      sources.matchesPunjabi(
        word: 'ਬਾਗ',
        definition: cleanMahanKoshSense('n orchard.')!,
        decision: decision,
        editorial: false,
      ),
      isTrue,
    );
    expect(
      sources.matchesPunjabi(
        word: 'ਘਰ',
        definition: 'orchard',
        decision: decision,
        editorial: false,
      ),
      isFalse,
    );
    expect(
      sources.matchesPunjabi(
        word: 'ਬਾਗ',
        definition: 'orchard',
        decision: {...decision, 'sourceSenseIndex': 4},
        editorial: true,
      ),
      isFalse,
    );
    expect(
      sources.matchesPunjabi(
        word: 'ਬਾਗ',
        definition: 'orchard',
        decision: null,
        editorial: true,
      ),
      isFalse,
    );
  });

  test('source lock rejects altered, missing and unexpected source files', () {
    final root = Directory.systemTemp.createTempSync('vocabulary-source-test-');
    addTearDown(() => root.deleteSync(recursive: true));
    const path = '.dart_tool/vocabulary_sources/oewn-2025/entries-b.json';
    final file = File('${root.path}/$path')..createSync(recursive: true);
    file.writeAsStringSync('{}');
    final lock = {
      'schemaVersion': 1,
      'files': {path: fileHash(file.path)},
    };
    expect(verifySourceLock(lock, root: root), hasLength(1));
    file.writeAsStringSync('{"wrong":true}');
    expect(() => verifySourceLock(lock, root: root), throwsStateError);
    file.writeAsStringSync('{}');
    final extra = File('${file.parent.path}/unexpected.json')
      ..writeAsStringSync('{}');
    expect(() => verifySourceLock(lock, root: root), throwsStateError);
    extra.deleteSync();
    file.deleteSync();
    expect(() => verifySourceLock(lock, root: root), throwsStateError);
  });

  test('pool impact counts unique answers and excludes held and guess-only records', () {
    final entries = [
      _entry(),
      {..._entry(), 'id': 'alias'},
      {..._entry(), 'id': 'guess', 'latin': 'DOOR', 'solutionEligible': false},
    ];
    expect(measurePools(entries)['english:4'], 1);
    final held = applyVocabularyHold(entries.first, {
      'fingerprint': vocabularyFingerprint(entries.first),
    });
    expect(measurePools([held]), isEmpty);
  });
}

Map<String, Object?> _entry() => {
  'id': 'english_book',
  'language': 'english',
  'latin': 'BOOK',
  'gurmukhi': null,
  'definitions': {
    'en': ['a volume of written pages'],
    'pa': <String>[],
  },
  'lengths': {'latin': 4, 'gurmukhi': null},
  'acceptedGuess': true,
  'solutionEligible': true,
  'reviewStatus': 'machineChecked',
  'sources': [oewnLabel],
};
