import 'package:flutter_test/flutter_test.dart';

import '../../tool/content/mahan_kosh_text.dart';

void main() {
  test('checks consonant order without inventing missing sounds', () {
    expect(hasMatchingPunjabiConsonants('ਅਦਰਕ', 'ADKAR'), isFalse);
    expect(hasMatchingPunjabiConsonants('ਅਦਰਕ', 'ADRAK'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਕੇਸ', 'CASE'), isFalse);
    expect(hasMatchingPunjabiConsonants('ਪੰਜਾਬੀ', 'PAJABI'), isFalse);
    expect(hasMatchingPunjabiConsonants('ਪੰਜਾਬੀ', 'PANJABI'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਨਿਹਕਲੰਕ', 'NIHKALANK'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਜੁਲਫ', 'JULF'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਜੁਲਫ', 'JULPH'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਪਹੁੰਚਾਣਾ', 'PAHUNCHANA'), isTrue);
    expect(hasMatchingPunjabiConsonants('ਪਹੁੰਚਾਣਾ', 'FAUNCHANA'), isFalse);
    expect(hasMatchingPunjabiConsonants('ਪਿਆਰ', 'PIYAR'), isTrue);
  });
  test('preserves source vowels and nasal sounds previously deleted', () {
    expect(romanizeMahanKosh('[avǝsyǝk]'), 'AVASYAK');
    expect(romanizeMahanKosh('[nɪhkəlãk]'), 'NIHKALANK');
    expect(romanizeMahanKosh('[Ĩdranuj]'), 'INDRANUJ');
    expect(romanizeMahanKosh('[kıtab]'), 'KITAB');
    expect(romanizeMahanKosh('[şanti]'), 'SHANTI');
    expect(romanizeMahanKosh('[kə?tab]'), isNull);
    expect(romanizeMahanKosh('[kitab 2]'), isNull);
    expect(romanizeMahanKosh('[do shabad]'), isNull);
  });
  test('extracts a complete meaning and leaves citations behind', () {
    expect(cleanMahanKoshSense('Skt ਅਦਰਕ n ginger.'), 'ginger');
    expect(
      cleanMahanKoshSense('n house, place of residence. “ghər...”'),
      'house, place of residence',
    );
    expect(
      cleanMahanKoshSense('adj uncommon, exceptional. 2 another sense.'),
      'uncommon, exceptional',
    );
    expect(cleanMahanKoshSense('See ਕਿਤਾਬ.'), isNull);
    expect(cleanMahanKoshSense('a saying "come here"'), isNull);
    expect(
      cleanMahanKoshSense('a letter n in the alphabet'),
      'a letter n in the alphabet',
    );
    expect(cleanMahanKoshSense('Skt ਅ. something.'), isNull);
    expect(
      cleanMahanKoshSense('n day and night, a period of. 2 a full day.'),
      isNull,
    );
    expect(cleanMahanKoshSense('a ${'long description ' * 15}'), isNull);
  });
}
