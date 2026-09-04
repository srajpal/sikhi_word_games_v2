import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/v1_vocabulary_importer.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';

void main() {
  test('imports aligned English and Punjabi V1 rows', () {
    final result = V1VocabularyImporter.import(
      wordLines: const ['HERO,E', 'BAAG,S'],
      definitionLines: const [
        'HERO;E;An illustrious person',
        'BAAG;S;ਬਾਗ - Orchard',
      ],
      expectedLatinLength: 4,
      sourceVersion: '1',
    );

    expect(result.issues, isEmpty);
    expect(result.entries, hasLength(2));
    expect(result.entries.first.language, VocabularyLanguage.english);
    expect(result.entries.last.gurmukhi, 'ਬਾਗ');
    expect(result.entries.last.gurmukhiLength, 2);
    expect(result.entries.last.englishDefinition, 'Orchard');
    expect(result.entries.last.acceptedGuess, isTrue);
    expect(result.entries.last.solutionEligible, isFalse);
  });

  test('preserves semicolons inside definitions', () {
    final result = V1VocabularyImporter.import(
      wordLines: const ['HERO,E'],
      definitionLines: const ['HERO;E;First clause; second clause'],
      expectedLatinLength: 4,
      sourceVersion: '1',
    );
    expect(
      result.entries.single.englishDefinition,
      'First clause; second clause',
    );
  });

  test('reports key mismatches without importing the row', () {
    final result = V1VocabularyImporter.import(
      wordLines: const ['HERO,E'],
      definitionLines: const ['ZERO;E;A definition'],
      expectedLatinLength: 4,
      sourceVersion: '1',
    );
    expect(result.entries, isEmpty);
    expect(result.issues.single.type, ImportIssueType.keyMismatch);
  });

  test('flags Punjabi rows without a Gurmukhi form for review', () {
    final result = V1VocabularyImporter.import(
      wordLines: const ['TELL,S'],
      definitionLines: const ['TELL;S;das - ten'],
      expectedLatinLength: 4,
      sourceVersion: '1',
    );
    expect(result.entries.single.gurmukhi, isNull);
    expect(
      result.issues.map((issue) => issue.type),
      contains(ImportIssueType.missingGurmukhi),
    );
  });
}
