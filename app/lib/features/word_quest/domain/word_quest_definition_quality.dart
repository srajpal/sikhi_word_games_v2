/// Validates clues before they are shown to children in Word Quest.
class WordQuestDefinitionQuality {
  const WordQuestDefinitionQuality._();

  static const int maximumClueCharacters = 96;

  /// Returns a trimmed, safe clue, or null when the clue is not usable.
  static String? usableClue({required String answer, required String clue}) {
    final sourceText = clue.trim().replaceAll(RegExp(r'\s+'), ' ');
    final text = _conciseSense(sourceText);
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

  static String _conciseSense(String text) {
    if (text.isEmpty) return text;

    // Older dictionary records often append numbered senses after a useful
    // opening sentence. Word Quest needs only that first child-sized clue.
    final numberedSense = RegExp(r'(?<=[.!?;])\s+(?=\d+[.)]?\s)')
        .firstMatch(text);
    var concise = numberedSense == null
        ? text
        : text.substring(0, numberedSense.start);
    if (concise.length <= maximumClueCharacters) return concise.trim();

    final firstSentence = RegExp(r'^(.{4,96}?[.!?;])(?:\s|$)')
        .firstMatch(concise);
    if (firstSentence != null) return firstSentence.group(1)!.trim();

    final prefix = concise.substring(0, maximumClueCharacters - 1);
    final lastSpace = prefix.lastIndexOf(' ');
    concise =
        '${prefix.substring(0, lastSpace > 40 ? lastSpace : prefix.length)}…';
    return concise.trim();
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{N}]+", unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
