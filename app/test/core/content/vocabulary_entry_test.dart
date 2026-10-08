import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';

void main() {
  test('normalizes typographic punctuation in displayed definitions', () {
    final entry = VocabularyEntry.fromJson({
      'id': 'english_test',
      'language': 'english',
      'latin': 'TEST',
      'gurmukhi': null,
      'definitions': {
        'en': ['A trial—or check…'],
        'pa': <String>[],
      },
      'lengths': {'latin': 4, 'gurmukhi': null},
      'acceptedGuess': true,
      'solutionEligible': true,
      'reviewStatus': 'machineChecked',
      'sources': ['Open English WordNet 2025 (CC BY 4.0)'],
    });

    expect(entry.englishDefinition, 'A trial—or check…');
    expect(entry.displayDefinition, 'A trial - or check...');
    expect(
      entry.copyWith(englishDefinition: 'One–two').displayDefinition,
      'One - two',
    );
  });

  test('hides a definition with unclear distribution rights', () {
    const entry = VocabularyEntry(
      id: 'legacy_test',
      language: VocabularyLanguage.english,
      latin: 'TEST',
      gurmukhi: null,
      englishDefinition: 'Legacy source text',
      latinLength: 4,
      gurmukhiLength: null,
      acceptedGuess: true,
      solutionEligible: false,
      reviewStatus: ReviewStatus.unreviewed,
      source: 'legacy import',
    );

    expect(entry.hasDistributableDefinition, isFalse);
    expect(entry.displayDefinition, 'Definition unavailable for this word.');
  });

  test('round-trips a vocabulary entry through JSON', () {
    const original = VocabularyEntry(
      id: 'panjabi_seva',
      language: VocabularyLanguage.panjabi,
      latin: 'SEVA',
      gurmukhi: 'ਸੇਵਾ',
      englishDefinition: 'Service without thought of reward',
      latinLength: 4,
      gurmukhiLength: 2,
      acceptedGuess: true,
      solutionEligible: false,
      reviewStatus: ReviewStatus.unreviewed,
      source: 'test',
    );
    final restored = VocabularyEntry.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.gurmukhi, original.gurmukhi);
    expect(restored.englishDefinition, original.englishDefinition);
  });
}
