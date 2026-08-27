import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';

void main() {
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
