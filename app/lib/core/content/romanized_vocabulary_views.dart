import '../language/word_units.dart';
import 'vocabulary_entry.dart';
import 'answer_eligibility.dart';

/// Source IDs, definitions and language membership stay intact in both views.
/// Game pools deduplicate spellings when several source forms lose their marks.
class RomanizedVocabularyViews {
  RomanizedVocabularyViews(Iterable<VocabularyEntry> entries)
    : original = List.unmodifiable(entries);

  final List<VocabularyEntry> original;
  List<VocabularyEntry>? _simple;

  List<VocabularyEntry> entries({required bool simple}) => !simple
      ? original
      : _simple ??= List.unmodifiable([
          for (final entry in original)
            entry.supportsScript(VocabularyScript.romanizedPunjabi)
                ? entry.copyWith(
                    latin: simplifyRomanizedPunjabi(entry.latin),
                    // A plain view must not hide a leak in the source spelling.
                    solutionEligible:
                        entry.solutionEligible &&
                        AnswerEligibility.allows(
                          entry,
                          VocabularyScript.romanizedPunjabi,
                        ),
                  )
                : entry,
        ]);
}
