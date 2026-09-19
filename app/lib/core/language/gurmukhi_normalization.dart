/// Returns one stable code-point spelling for canonically equivalent Gurmukhi
/// letters. Source and display strings can keep their original spelling; use
/// this value for comparison, lookup, persistence state, and de-duplication.
String normalizeGurmukhi(String value) {
  const decompositions = {
    0x0A33: '\u0A32\u0A3C', // ਲ਼ -> ਲ਼
    0x0A36: '\u0A38\u0A3C', // ਸ਼ -> ਸ਼
    0x0A59: '\u0A16\u0A3C', // ਖ਼ -> ਖ਼
    0x0A5A: '\u0A17\u0A3C', // ਗ਼ -> ਗ਼
    0x0A5B: '\u0A1C\u0A3C', // ਜ਼ -> ਜ਼
    0x0A5E: '\u0A2B\u0A3C', // ਫ਼ -> ਫ਼
  };
  final result = StringBuffer();
  for (final rune in value.runes) {
    result.write(decompositions[rune] ?? String.fromCharCode(rune));
  }
  return result.toString();
}
