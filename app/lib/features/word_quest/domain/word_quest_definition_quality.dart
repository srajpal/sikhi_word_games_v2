/// Validates clues before they are shown to children in Word Quest.
class WordQuestDefinitionQuality {
  const WordQuestDefinitionQuality._();

  /// Returns a trimmed, safe clue, or null when the clue is not usable.
  static String? usableClue({required String answer, required String clue}) {
    final text = clue.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedAnswer = _normalize(answer);
    final normalizedClue = _normalize(text);
    // Short dictionary senses such as "orchard" and "wisdom" are complete,
    // useful clues; reject only fragments too small to communicate a sense.
    if (text.length < 4 || normalizedClue.length < 4) return null;

    // Dictionary cross-references are not clues (e.g. "of ginn", "see X").
    if (RegExp(r'^(?:of|see)\b', caseSensitive: false).hasMatch(text) ||
        RegExp(r'\bsee\s+\w+', caseSensitive: false).hasMatch(text)) {
      return null;
    }
    // Never give away the answer, including a circular definition.
    if (normalizedAnswer.isNotEmpty &&
        (normalizedClue == normalizedAnswer ||
            RegExp('(?:^|\\s)${RegExp.escape(normalizedAnswer)}(?:\\s|\$)')
                .hasMatch(normalizedClue))) {
      return null;
    }
    return text;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{N}]+", unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
