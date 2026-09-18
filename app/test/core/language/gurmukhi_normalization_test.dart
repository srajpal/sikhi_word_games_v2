import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/language/gurmukhi_normalization.dart';

void main() {
  test('canonicalizes every Gurmukhi letter with a nukta decomposition', () {
    expect(normalizeGurmukhi('ਲ਼ਸ਼ਖ਼ਗ਼ਜ਼ੜਫ਼'), 'ਲ਼ਸ਼ਖ਼ਗ਼ਜ਼ਡ਼ਫ਼');
  });

  test('equivalent forms keep the same visible grapheme count', () {
    const precomposed = 'ਖ਼ਬਰ';
    const decomposed = 'ਖ਼ਬਰ';

    expect(normalizeGurmukhi(precomposed), normalizeGurmukhi(decomposed));
    expect(
      normalizeGurmukhi(precomposed).characters.length,
      decomposed.characters.length,
    );
  });
}
