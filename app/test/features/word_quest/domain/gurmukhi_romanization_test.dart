import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/gurmukhi_romanization.dart';

void main() {
  test('romanizes whole Gurmukhi grapheme tiles', () {
    expect(romanizeGurmukhiGrapheme('ਸਾ'), 'Saa');
    expect(romanizeGurmukhiGrapheme('ਕੀ'), 'Kee');
    expect(romanizeGurmukhiGrapheme('ਗੁ'), 'Gu');
    expect(romanizeGurmukhiGrapheme('ਬੰ'), 'Ban');
  });
}
