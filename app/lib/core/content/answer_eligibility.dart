import '../language/gurmukhi_normalization.dart';
import '../language/word_units.dart';
import 'vocabulary_entry.dart';

/// Mechanical answer-pool exclusions, independent of dictionary approval.
/// Lookup and accepted guesses retain every supplied entry and definition.
abstract final class AnswerEligibility {
  static const sacredGurmukhi = {
    'ਗੁਰਬਾਣੀ',
    'ਅਰਦਾਸ',
    'ਖੰਡਾ',
    'ਗੁਰੂ',
    'ਗ੍ਰੰਥ',
    'ਨਿਸ਼ਾਨ',
  };
  // Plain aliases also cover the scholarly forms after folding their marks.
  static const sacredRomanized = {
    'gurbani',
    'gurubani',
    'gurbaani',
    'ardas',
    'aradas',
    'khanda',
    'guru',
    'granth',
    'nishan',
    'nisan',
  };
  static final _sacredNative = sacredGurmukhi.map(normalizeGurmukhi).toSet();
  static final _wordCharacter = RegExp(r'[\p{L}\p{M}\p{N}_]', unicode: true);
  static final _romanNumeral = RegExp(
    r'^(?:m{0,4}(?:cm|cd|d?c{0,3})(?:xc|xl|l?x{0,3})(?:ix|iv|v?i{0,3})|ilxx|ilxxx)$',
    caseSensitive: false,
  );

  static bool allows(VocabularyEntry entry, VocabularyScript script) {
    // Missing frequency metadata is not evidence of the minimum usage count.
    if (script == VocabularyScript.english &&
        (entry.wordNetTagCount ?? 0) < 3) {
      return false;
    }
    final spelling = script == VocabularyScript.gurmukhi
        ? entry.gurmukhi ?? ''
        : entry.latin;
    if (containsWholeWord(entry.englishDefinition, spelling)) return false;
    if (script == VocabularyScript.english &&
        spelling.trim().isNotEmpty &&
        _romanNumeral.hasMatch(spelling.trim())) {
      return false;
    }
    return !_sacredNative.contains(
          normalizeGurmukhi((entry.gurmukhi ?? '').trim()),
        ) &&
        !sacredRomanized.contains(
          simplifyRomanizedPunjabi(entry.latin.trim()).toLowerCase(),
        );
  }

  /// Unicode letters and attached marks belong to a word; punctuation does not.
  static bool containsWholeWord(String text, String word) {
    String normalize(String value) =>
        normalizeGurmukhi(normalizeRomanizedInput(value.toLowerCase()));
    final needle = normalize(word.trim());
    if (needle.isEmpty) return false;
    final haystack = normalize(text);
    for (final match in RegExp(RegExp.escape(needle)).allMatches(haystack)) {
      final before = match.start == 0
          ? null
          : haystack.substring(0, match.start).runes.last;
      final after = match.end == haystack.length
          ? null
          : haystack.substring(match.end).runes.first;
      bool boundary(int? rune) =>
          rune == null || !_wordCharacter.hasMatch(String.fromCharCode(rune));
      if (boundary(before) && boundary(after)) return true;
    }
    return false;
  }
}
