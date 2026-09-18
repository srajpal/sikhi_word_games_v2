import 'dart:convert';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_search/domain/word_search_puzzle.dart';

Map<String, Object?> snapshot() => {
  'cells': [
    ['C', 'A', 'T'],
    ['D', 'O', 'G'],
    ['ਕਿ', 'ਤਾ', 'ਬ'],
  ],
  'words': [
    {'word': 'CAT', 'row': 0, 'column': 0, 'direction': 'east'},
  ],
};

void main() {
  for (final corruption in [
    'mismatch',
    'empty word',
    'duplicate word',
    'empty cell',
    'multiple graphemes',
  ]) {
    test('restore rejects $corruption in an otherwise valid grid', () {
      final json = snapshot();
      final cells = json['cells']! as List<List<String>>;
      final words = json['words']! as List<Map<String, Object>>;
      switch (corruption) {
        case 'mismatch':
          cells[0][1] = 'X';
        case 'empty word':
          words[0]['word'] = '';
        case 'duplicate word':
          words.add(Map.of(words.first));
        case 'empty cell':
          cells[2][0] = '';
        case 'multiple graphemes':
          cells[2][0] = 'AB';
      }
      expect(() => WordSearchPuzzle.fromJson(json), throwsFormatException);
    });
  }

  test(
    '200 seeded Latin and Gurmukhi grids preserve every target and save',
    () {
      final directions = <WordSearchDirection>{};
      for (var seed = 0; seed < 200; seed++) {
        final puzzle = WordSearchGenerator(random: Random(seed)).generate(
          candidates: seed.isEven
              ? ['LEVEL', 'LEVER', 'REVEL', 'EVER', ' level ', 'TOOLONGFORGRID']
              : ['ਕਿਤਾਬ', 'ਪਰਿਵਾਰ', 'ਕਿਤਾਬ', 'ਸਿਮਰਨ'],
          fillerCharacters: seed.isEven ? ['A', 'E', 'L'] : ['ਕਿ', 'ਤਾ', 'ਬ'],
          size: 6,
          targetWordCount: 4,
        );
        final restored = WordSearchPuzzle.fromJson(
          jsonDecode(jsonEncode(puzzle.toJson())) as Map<String, Object?>,
        );
        expect(restored.toJson(), puzzle.toJson(), reason: 'seed $seed');
        expect(
          puzzle.words.map((w) => w.word).toSet().length,
          puzzle.words.length,
        );
        expect(
          puzzle.cells.expand((r) => r).every((c) => c.characters.length == 1),
          isTrue,
        );
        for (final word in puzzle.words) {
          directions.add(word.direction);
          final points = word.cells();
          expect(
            points.map((p) => puzzle.cells[p.row][p.column]).join(),
            word.word,
            reason: 'seed $seed',
          );
          expect(puzzle.wordForSelection(points.reversed.toList()), same(word));
          expect(puzzle.wordForSelection([points.first]), isNull);
        }
      }
      expect(directions, containsAll(WordSearchDirection.values));
    },
  );
}
