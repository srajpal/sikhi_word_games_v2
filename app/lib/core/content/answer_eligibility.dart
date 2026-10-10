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
  // Entries are immutable. Weak keys reuse mechanical checks across games and
  // lengths without retaining a discarded vocabulary or confusing source/plain
  // entries (copyWith creates a different identity).
  static final _decisions = Expando<Map<VocabularyScript, bool>>();
  static final _romanNumeral = RegExp(
    r'^(?:m{0,4}(?:cm|cd|d?c{0,3})(?:xc|xl|l?x{0,3})(?:ix|iv|v?i{0,3})|ilxx|ilxxx)$',
    caseSensitive: false,
  );

  /// Shared selection/restore gate. Clue games require a distributable meaning;
  /// Bujho preserves its ability to use an answer without a definition.
  static bool isCandidate(
    VocabularyEntry entry,
    VocabularyScript script, {
    bool requireDefinition = true,
  }) =>
      entry.acceptedGuess &&
      entry.solutionEligible &&
      entry.supportsScript(script) &&
      (!requireDefinition || entry.hasDistributableDefinition) &&
      allows(entry, script);

  static bool allows(VocabularyEntry entry, VocabularyScript script) =>
      (_decisions[entry] ??= {}).putIfAbsent(
        script,
        () => _allows(entry, script),
      );

  static bool _allows(VocabularyEntry entry, VocabularyScript script) {
    // Missing frequency metadata is not evidence of the minimum usage count.
    if (script == VocabularyScript.english &&
        (entry.wordNetTagCount ?? 0) < 3) {
      return false;
    }
    final spelling = script == VocabularyScript.gurmukhi
        ? entry.gurmukhi ?? ''
        : entry.latin;
    if (containsWholeWord(entry.englishDefinition, spelling)) return false;
    if (script == VocabularyScript.gurmukhi) {
      final plainDefinition = simplifyRomanizedPunjabi(entry.englishDefinition);
      if ([entry.latin, ...entry.romanizations].any(
        (alias) =>
            containsWholeWord(plainDefinition, simplifyRomanizedPunjabi(alias)),
      )) {
        return false;
      }
    }
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
    var start = haystack.indexOf(needle);
    while (start >= 0) {
      final end = start + needle.length;
      final before = start == 0
          ? null
          : haystack.substring(0, start).runes.last;
      final after = end == haystack.length
          ? null
          : haystack.substring(end).runes.first;
      bool boundary(int? rune) =>
          rune == null || !_wordCharacter.hasMatch(String.fromCharCode(rune));
      if (boundary(before) && boundary(after)) return true;
      // Match the non-overlapping behavior of RegExp.allMatches.
      start = haystack.indexOf(needle, end);
    }
    return false;
  }
}
