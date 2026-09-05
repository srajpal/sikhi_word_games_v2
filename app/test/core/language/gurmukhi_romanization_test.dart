import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/language/gurmukhi_romanization.dart';

void main() {
  test('romanizes standalone and whole Gurmukhi keyboard graphemes', () {
    expect(romanizeGurmukhiGrapheme('ਸਾ'), 'Saa');
    expect(romanizeGurmukhiGrapheme('ਕੀ'), 'Kee');
    expect(romanizeGurmukhiGrapheme('ਗੁ'), 'Gu');
    expect(romanizeGurmukhiGrapheme('ਬੰ'), 'Ban');
    expect(romanizeGurmukhiGrapheme('ੀ'), 'Ee');
  });
}
