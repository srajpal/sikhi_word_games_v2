/// Returns a short, readable pronunciation for one Gurmukhi grapheme.
///
/// This is a shared learning aid for keyboard and answer tiles, not a
/// replacement for curated whole-word romanization in the vocabulary.
String romanizeGurmukhiGrapheme(String grapheme) {
  if (grapheme.isEmpty) return '';
  const independentVowels = {
    'ੳ': 'u',
    'ਅ': 'a',
    'ੲ': 'i',
    'ਆ': 'aa',
    'ਇ': 'i',
    'ਈ': 'ee',
    'ਉ': 'u',
    'ਊ': 'oo',
    'ਏ': 'e',
    'ਐ': 'ai',
    'ਓ': 'o',
    'ਔ': 'au',
  };
  const consonants = {
    'ਕ': 'k',
    'ਖ': 'kh',
    'ਗ': 'g',
    'ਘ': 'gh',
    'ਙ': 'ng',
    'ਚ': 'ch',
    'ਛ': 'chh',
    'ਜ': 'j',
    'ਝ': 'jh',
    'ਞ': 'ny',
    'ਟ': 't',
    'ਠ': 'th',
    'ਡ': 'd',
    'ਢ': 'dh',
    'ਣ': 'n',
    'ਤ': 't',
    'ਥ': 'th',
    'ਦ': 'd',
    'ਧ': 'dh',
    'ਨ': 'n',
    'ਪ': 'p',
    'ਫ': 'ph',
    'ਬ': 'b',
    'ਭ': 'bh',
    'ਮ': 'm',
    'ਯ': 'y',
    'ਰ': 'r',
    'ਲ': 'l',
    'ਵ': 'v',
    'ੜ': 'r',
    'ਸ': 's',
    'ਹ': 'h',
    'ਸ਼': 'sh',
    'ਖ਼': 'kh',
    'ਗ਼': 'gh',
    'ਜ਼': 'z',
    'ਫ਼': 'f',
    'ਲ਼': 'l',
  };
  const vowelSigns = {
    'ਾ': 'aa',
    'ਿ': 'i',
    'ੀ': 'ee',
    'ੁ': 'u',
    'ੂ': 'oo',
    'ੇ': 'e',
    'ੈ': 'ai',
    'ੋ': 'o',
    'ੌ': 'au',
  };

  var onset = '';
  String? vowel;
  var ending = '';
  for (final rune in grapheme.runes) {
    final character = String.fromCharCode(rune);
    if (independentVowels.containsKey(character)) {
      vowel = independentVowels[character];
    } else if (consonants.containsKey(character)) {
      onset += consonants[character]!;
    } else if (vowelSigns.containsKey(character)) {
      vowel = vowelSigns[character];
    } else if (character == '੍') {
      vowel = '';
    } else if (character == 'ੰ' || character == 'ਂ') {
      ending += 'n';
    }
  }
  final value = '$onset${vowel ?? (onset.isEmpty ? '' : 'a')}$ending';
  if (value.isEmpty) return grapheme;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
