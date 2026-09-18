/// Converts the source's pronunciation notation without silently deleting
/// unfamiliar sounds. This is an ASCII spelling aid, not a phonetic standard.
String? romanizeMahanKosh(String? source) {
  if (source == null) return null;
  var text = source.trim().toLowerCase();
  if (text.startsWith('[') && text.endsWith(']')) {
    text = text.substring(1, text.length - 1);
  }
  const sounds = {
    'ə': 'a',
    'ǝ': 'a',
    'ɑ': 'a',
    'ā': 'a',
    'ă': 'a',
    'ı': 'i',
    'ɪ': 'i',
    'ī': 'i',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ū': 'u',
    'ʊ': 'u',
    'ü': 'u',
    'ō': 'o',
    'ö': 'o',
    'ē': 'e',
    'ɛ': 'ai',
    'ɔ': 'au',
    'ṛ': 'r',
    'ṙ': 'r',
    'ṇ': 'n',
    'ņ': 'n',
    'ṅ': 'ng',
    'ŋ': 'ng',
    'ñ': 'ny',
    'ɲ': 'ny',
    'ṭ': 't',
    'ț': 't',
    'ţ': 't',
    'ḍ': 'd',
    'ɖ': 'd',
    'ś': 'sh',
    'ṣ': 'sh',
    'ş': 'sh',
    'ș': 'sh',
    'ʃ': 'sh',
    'ṃ': 'm',
    'ṁ': 'm',
    'ã': 'an',
    'ĩ': 'in',
    'ũ': 'un',
    'ẽ': 'en',
    'õ': 'on',
    '\u0303': 'n',
    '\u0304': '',
    '\u0323': '',
  };
  final result = StringBuffer();
  for (final rune in text.runes) {
    final character = String.fromCharCode(rune);
    if (sounds.containsKey(character)) {
      result.write(sounds[character]);
    } else if (RegExp('[a-z]').hasMatch(character)) {
      result.write(character == 'c' ? 'ch' : character);
    } else {
      // Spaces, alternatives, numbers, corrupt markup and unknown phonemes
      // require an editorial spelling. Joining them manufactures a word.
      return null;
    }
  }
  final latin = result.toString().toUpperCase();
  return RegExp(r'^[A-Z]{2,24}$').hasMatch(latin) ? latin : null;
}

/// A conservative consonant-order check. It tolerates ordinary vowel length,
/// aspiration and v/w conventions, but catches lost or transposed consonants.
/// Failure routes the spelling to editorial review; it does not reject guesses.
bool hasMatchingPunjabiConsonants(String gurmukhi, String latin) {
  const consonants = {
    'ਕ': 'K',
    'ਖ': 'KH',
    'ਗ': 'G',
    'ਘ': 'GH',
    'ਙ': 'N',
    'ਚ': 'CH',
    'ਛ': 'CHH',
    'ਜ': 'J',
    'ਝ': 'JH',
    'ਞ': 'N',
    'ਟ': 'T',
    'ਠ': 'TH',
    'ਡ': 'D',
    'ਢ': 'DH',
    'ਣ': 'N',
    'ਤ': 'T',
    'ਥ': 'TH',
    'ਦ': 'D',
    'ਧ': 'DH',
    'ਨ': 'N',
    'ਪ': 'P',
    'ਫ': 'F',
    'ਬ': 'B',
    'ਭ': 'BH',
    'ਮ': 'M',
    'ਯ': 'Y',
    'ਰ': 'R',
    'ਲ': 'L',
    'ਵ': 'V',
    'ੜ': 'R',
    'ਸ': 'S',
    'ਹ': 'H',
    'ਸ਼': 'SH',
    'ਸ਼': 'SH',
    'ਖ਼': 'KH',
    'ਗ਼': 'GH',
    'ਜ਼': 'Z',
    'ਫ਼': 'F',
    'ਲ਼': 'L',
    'ੰ': 'N',
    'ਂ': 'N',
  };
  String fold(String value) => value
      .toUpperCase()
      .replaceAll('W', 'V')
      .replaceAll('X', 'KH')
      .replaceAll(RegExp('[AEIOUH]'), '')
      .replaceAll('M', 'N')
      .replaceAllMapped(RegExp(r'(.)\1+'), (m) => m.group(1)!);
  final normalized = gurmukhi
      .replaceAll('ਜ਼', 'ਜ਼')
      .replaceAll('ਫ਼', 'ਫ਼')
      .replaceAll('ਖ਼', 'ਖ਼')
      .replaceAll('ਗ਼', 'ਗ਼')
      .replaceAll('ਸ਼', 'ਸ਼');
  final expected = normalized.runes
      .map((r) => consonants[String.fromCharCode(r)] ?? '')
      .join();
  var pronunciation = latin
      .toUpperCase()
      .replaceAll('PH', 'F')
      .replaceAll('IY', 'I');
  if (normalized.contains('ਗਿਆ')) {
    pronunciation = pronunciation.replaceAll('GYA', 'GA');
  }
  return fold(expected) == fold(pronunciation);
}

/// Extracts a whole dictionary sense, without truncating it into a fragment.
/// Quotes, etymologies and grammatical labels stay in the source evidence.
String? cleanMahanKoshSense(String source) {
  var text = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  text = text.replaceFirst(RegExp(r'^\d+[.)]?\s+'), '');
  if (RegExp(
    r'^(?:see|same as|plural of|variant of|short for)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    return null;
  }
  final grammar = RegExp(
    r'^(?:n|adj|adv|v|vt|vi|pron|prep|conj|interj)\.?\s+',
    caseSensitive: false,
  );
  if (RegExp(r'^(?:Skt|Sk|P|A|H|L|E|S|Pr)\s').hasMatch(text)) {
    // Recognize an etymology only when a grammatical label terminates it.
    // Never search arbitrary English prose for an isolated letter n or v.
    final prefix = RegExp(
      r'^(?:Skt|Sk|P|A|H|L|E|S|Pr)\s+(?:[^A-Za-z]*\s+)?(?:n|adj|adv|v|vt|vi|pron|prep|conj|interj)\.?\s+',
    ).firstMatch(text);
    if (prefix == null) return null;
    text = text.substring(prefix.end);
  } else {
    text = text.replaceFirst(grammar, '');
  }
  // A new numbered sense or a source quotation ends the chosen meaning.
  final boundaries = [
    RegExp(r'\s+\d+(?:[.)]?\s+|(?=(?:n|adj|adv)\b))').firstMatch(text)?.start,
    RegExp('[“"‘]').firstMatch(text)?.start,
    RegExp(r'\s+See\s').firstMatch(text)?.start,
  ].whereType<int>();
  if (boundaries.isNotEmpty) {
    final boundary = boundaries.reduce((a, b) => a < b ? a : b);
    final before = text.substring(0, boundary).trim();
    if (!RegExp(r'[.;]$').hasMatch(before) &&
        RegExp('[“"‘]').hasMatch(text[boundary])) {
      return null;
    }
    text = before;
  }
  text = text
      .replaceAll(RegExp(r'\s*[\u2013\u2014]\s*'), ' - ')
      .replaceAll('\u2026', '...')
      .trim();
  text = text.replaceFirst(RegExp(r'[.;:,]+$'), '').trim();
  if (text.isEmpty || text.length > 120) return null;
  if (RegExp(
    r'\b(?:a|an|the|of|to|for|with|and|or|in|on|by|from|called|named|is|are)$',
    caseSensitive: false,
  ).hasMatch(text)) {
    return null;
  }
  // A surviving source label or non-English passage is not a game meaning.
  if (RegExp(r'^(?:Skt|Sk|P|A|H|L|E|S|Pr|vr)\b').hasMatch(text) ||
      RegExp(r'[^\x20-\x7E]').hasMatch(text)) {
    return null;
  }
  return text;
}
