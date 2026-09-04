import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';

void main() {
  test('generator places requested words and selection recognizes both directions', () {
    final puzzle = WordSearchGenerator(random: Random(7)).generate(
      candidates: const ['SEVA', 'KIRTAN', 'LANGAR', 'NITNEM', 'SIMRAN'],
      fillerCharacters: const ['A', 'B', 'C'],
      size: 10,
      targetWordCount: 5,
    );

    expect(puzzle.words, hasLength(5));
    for (final word in puzzle.words) {
      final cells = word.cells();
      expect(puzzle.wordForSelection(cells), same(word));
      expect(puzzle.wordForSelection(cells.reversed.toList()), same(word));
    }
  });

  test('generator treats a Gurmukhi grapheme cluster as one visible letter', () {
    final puzzle = WordSearchGenerator(random: Random(3)).generate(
      candidates: const ['ਕਿਤਾਬ', 'ਪਰਿਵਾਰ'],
      fillerCharacters: const ['ਕ', 'ਗ', 'ਸ'],
      size: 6,
      targetWordCount: 2,
    );

    expect(puzzle.words, hasLength(2));
    expect(puzzle.words.map((word) => word.word), contains('ਕਿਤਾਬ'));
  });

  test('lineBetween supports straight and diagonal selections only', () {
    expect(
      WordSearchPuzzle.lineBetween(const GridPoint(1, 1), const GridPoint(1, 4)),
      const [
        GridPoint(1, 1),
        GridPoint(1, 2),
        GridPoint(1, 3),
        GridPoint(1, 4),
      ],
    );
    expect(
      WordSearchPuzzle.lineBetween(const GridPoint(0, 0), const GridPoint(3, 3)),
      const [
        GridPoint(0, 0),
        GridPoint(1, 1),
        GridPoint(2, 2),
        GridPoint(3, 3),
      ],
    );
    expect(
      WordSearchPuzzle.lineBetween(const GridPoint(0, 0), const GridPoint(2, 3)),
      isNull,
    );
  });
}
