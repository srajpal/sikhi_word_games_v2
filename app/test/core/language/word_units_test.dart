import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';

void main() {
  test(
    'unlinked units remain grapheme-safe for marks, emoji and line breaks',
    () {
      expect(wordUnits('ਕਾਰੇਲਾ'), ['ਕਾ', 'ਰੇ', 'ਲਾ']);
      expect(wordUnits('a\u0304\u0303👨‍👩‍👧‍👦\r\n'), [
        'a\u0304\u0303',
        '👨‍👩‍👧‍👦',
        '\r\n',
      ]);
      expect(wordUnits(''), isEmpty);
      expect(normalizeRomanizedInput('APPLE\r\n'), 'APPLE\r\n');
      expect(simplifyRomanizedPunjabi('APPLE\r\n'), 'APPLE\r\n');
    },
  );
  test(
    'Gurmukhi written tiles retain subjoined letters and attached marks',
    () {
      expect(wordUnits('ਅਪ੍ਰੈਲ'), ['ਅ', 'ਪ੍ਰੈ', 'ਲ']);
      expect(wordUnits('ਉਪਗ੍ਰਹਿ'), ['ਉ', 'ਪ', 'ਗ੍ਰ', 'ਹਿ']);
      expect(wordUnits('ਪ੍ਰਾਕ੍ਰਿਤਿਕ'), ['ਪ੍ਰਾ', 'ਕ੍ਰਿ', 'ਤਿ', 'ਕ']);
      expect(wordUnitCount('ਪ੍ਰਾਕ੍ਰਿਤਿਕ'), 4);
      expect(withoutLastWordUnit('ਅਪ੍ਰੈ'), 'ਅ');
      expect(withoutLastWordUnit(''), '');
    },
  );

  test(
    'all approved diacritic units accept decomposed forms in both cases',
    () {
      const forms = {
        'á': 'a\u0301',
        'ã': 'a\u0303',
        'ñ': 'n\u0303',
        'õ': 'o\u0303',
        'ā': 'a\u0304',
        'ā́': 'a\u0304\u0301',
        'ā̃': 'a\u0304\u0303',
        'ă': 'a\u0306',
        'ē': 'e\u0304',
        'ē̃': 'e\u0304\u0303',
        'ġ': 'g\u0307',
        'ĩ': 'i\u0303',
        'ī': 'i\u0304',
        'ī̃': 'i\u0304\u0303',
        'ĭ': 'i\u0306',
        'ś': 's\u0301',
        'ũ': 'u\u0303',
        'ū': 'u\u0304',
        'ū̃': 'u\u0304\u0303',
        'ḍ': 'd\u0323',
        'ḷ': 'l\u0323',
        'ṃ': 'm\u0323',
        'ṅ': 'n\u0307',
        'ṇ': 'n\u0323',
        'ṛ': 'r\u0323',
        'ṭ': 't\u0323',
        'ẽ': 'e\u0303',
      };
      expect(forms.length, 27);
      for (final form in forms.entries) {
        for (final uppercase in [false, true]) {
          final composed = uppercase ? form.key.toUpperCase() : form.key;
          final decomposed = uppercase ? form.value.toUpperCase() : form.value;
          expect(normalizeRomanizedInput(decomposed), composed);
          expect(normalizeRomanizedInput(composed), composed);
          expect(wordUnits(composed), [composed]);
        }
      }
      const ascii = 'abcdefghijklmnopqrstuvwxyz';
      expect(normalizeRomanizedInput(ascii), ascii);
      expect(normalizeRomanizedInput(ascii.toUpperCase()), ascii.toUpperCase());
      expect(wordUnitCount(ascii), 26);
    },
  );

  test('normalization preserves source distinctions and unrelated input', () {
    expect(normalizeRomanizedInput('ba\u0304ra\u0303'), 'bārã');
    expect(normalizeRomanizedInput('andar'), 'andar');
    expect(normalizeRomanizedInput('āndar'), 'āndar');
    expect(normalizeRomanizedInput('āndar'), isNot('andar'));
    expect(normalizeRomanizedInput('ਪ੍ਰੈ ਅ\u0304 é'), 'ਪ੍ਰੈ ਅ\u0304 é');
    expect(withoutLastWordUnit('bārā̃'), 'bār');
    expect(wordUnitCount('bārā̃'), 4);
    expect(wordUnits(normalizeRomanizedInput('ba\u0304ra\u0304\u0303')), [
      'b',
      'ā',
      'r',
      'ā̃',
    ]);
  });
}
