import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_definition_quality.dart';

void main() {
  test('keeps only the concise first numbered dictionary sense', () {
    const source =
        'the jujube tree that is related to the Gurus. 2 jujube tree on the '
        'bank of river Bein in Sultanpur, under which Guru Nanak Dev used to '
        'sit for sometime after taking off his clothes before having his bath.';

    expect(
      WordQuestDefinitionQuality.usableClue(answer: 'BER', clue: source),
      'the jujube tree that is related to the Gurus.',
    );
  });

  test('caps a long single-sentence clue at a word boundary', () {
    final clue = List.filled(30, 'helpful').join(' ');
    final result = WordQuestDefinitionQuality.usableClue(
      answer: 'WORD',
      clue: clue,
    );

    expect(result, isNotNull);
    expect(result!.length, lessThanOrEqualTo(96));
    expect(result, endsWith('…'));
  });

  test('still rejects cross references and answer-revealing clues', () {
    expect(
      WordQuestDefinitionQuality.usableClue(
        answer: 'GARDEN',
        clue: 'See orchard',
      ),
      isNull,
    );
    expect(
      WordQuestDefinitionQuality.usableClue(
        answer: 'GARDEN',
        clue: 'A garden for children',
      ),
      isNull,
    );
  });
}
