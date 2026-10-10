import '../content/vocabulary_entry.dart';
import 'gurmukhi_normalization.dart';
import 'word_units.dart';

/// Shared input alphabet and validation, independent of Flutter presentation.
abstract final class HardwareInput {
  static const latinRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  // The approved Roman alphabet preserves scholarly marks as whole keys.
  static const romanizedLetters = [
    'á',
    'ã',
    'ñ',
    'õ',
    'ā',
    'ā́',
    'ā̃',
    'ă',
    'ē',
    'ē̃',
    'ġ',
    'ĩ',
    'ī',
    'ī̃',
    'ĭ',
    'ś',
    'ũ',
    'ū',
    'ū̃',
    'ḍ',
    'ḷ',
    'ṃ',
    'ṅ',
    'ṇ',
    'ṛ',
    'ṭ',
    'ẽ',
  ];

  static bool acceptsCharacter(VocabularyScript script, String character) {
    if (character.isEmpty) return false;
    if (script == VocabularyScript.english) {
      return RegExp(r'^[A-Za-z]+$').hasMatch(character);
    }
    if (script == VocabularyScript.romanizedPunjabi) {
      final normalized = normalizeRomanizedInput(character).toUpperCase();
      final allowed = {
        ...latinRows.expand((row) => row),
        ...romanizedLetters.map((letter) => letter.toUpperCase()),
      };
      return wordUnits(normalized).every(
        (unit) =>
            allowed.contains(unit) ||
            RegExp(r'^[\u0300-\u036F]+$').hasMatch(unit),
      );
    }
    final allowed = gurmukhiRows.expand((row) => row).join().runes.toSet();
    return normalizeGurmukhi(character).runes.every(allowed.contains);
  }

  static const gurmukhiRows = [
    ['ਕ', 'ਖ', 'ਗ', 'ਘ', 'ਙ', 'ਚ', 'ਛ', 'ਜ', 'ਝ', 'ਞ'],
    ['ਟ', 'ਠ', 'ਡ', 'ਢ', 'ਣ', 'ਤ', 'ਥ', 'ਦ', 'ਧ', 'ਨ'],
    ['ਪ', 'ਫ', 'ਬ', 'ਭ', 'ਮ', 'ਯ', 'ਰ', 'ਲ', 'ਵ', 'ੜ'],
    ['ਸ', 'ਹ', 'ੳ', 'ਅ', 'ੲ', 'ਸ਼', 'ਖ਼', 'ਗ਼', 'ਜ਼', 'ਫ਼'],
    ['ਆ', 'ਇ', 'ਈ', 'ਉ', 'ਊ', 'ਏ', 'ਐ', 'ਓ', 'ਔ'],
    ['ਾ', 'ਿ', 'ੀ', 'ੁ', 'ੂ', 'ੇ', 'ੈ', 'ੋ'],
    ['ੌ', 'ੰ', 'ਂ', 'ੱ', '਼', '੍'],
  ];

  /// Quest guesses one unit, rather than composing a word like Bujho/Dictionary.
  static bool acceptsQuestCharacter(VocabularyScript script, String value) {
    if (!acceptsCharacter(script, value)) return false;
    if (script == VocabularyScript.gurmukhi) {
      return value.runes.length == 1 &&
          RegExp(r'^[\u0A05-\u0A39\u0A59-\u0A5E\u0A72\u0A73]$').hasMatch(value);
    }
    final normalized = normalizeRomanizedInput(value);
    return wordUnitCount(normalized) == 1 &&
        RegExp(r'^[A-Za-z\u00C0-\u024F\u1E00-\u1EFF]').hasMatch(normalized);
  }
}
