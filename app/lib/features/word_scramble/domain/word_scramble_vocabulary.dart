import 'dart:math';

import '../../../core/content/answer_eligibility.dart';

import '../../../core/content/romanized_vocabulary_views.dart';
import '../../../core/content/vocabulary_entry.dart';
import '../../../core/language/word_units.dart';
import '../../guess_the_word/domain/language_mode.dart';

class ScrambleWord {
  const ScrambleWord(this.id, this.spelling, this.definition);
  final String id;
  final String spelling;
  final String definition;
}

/// Shared answer hygiene and distinct tiles make each clue-led round playable.
class WordScrambleVocabulary {
  WordScrambleVocabulary(Iterable<VocabularyEntry> entries)
    : _entries = List.unmodifiable(entries);
  final List<VocabularyEntry> _entries;
  final Map<LanguageMode, List<ScrambleWord>> _pools = {};
  WordScrambleVocabulary? _simple;
  WordScrambleVocabulary get simpleRomanized =>
      _simple ??= WordScrambleVocabulary(
        RomanizedVocabularyViews(_entries).entries(simple: true),
      );
  List<LanguageMode> get availableModes =>
      LanguageMode.values.where((mode) => words(mode).isNotEmpty).toList();

  List<ScrambleWord> words(LanguageMode mode) => _pools.putIfAbsent(mode, () {
    final unique = <String, ScrambleWord>{};
    for (final entry in _entries) {
      if (!entry.supportsScript(mode.script) ||
          !entry.acceptedGuess ||
          !entry.solutionEligible ||
          !entry.hasDistributableDefinition ||
          !AnswerEligibility.allows(entry, mode.script)) {
        continue;
      }
      final spelling =
          (mode == LanguageMode.gurmukhi
                  ? entry.gurmukhi ?? ''
                  : entry.latin.toUpperCase())
              .trim();
      final units = wordUnits(spelling);
      if (units.length < 2 || units.toSet().length < 2) continue;
      unique.putIfAbsent(
        spelling,
        () => ScrambleWord(entry.id, spelling, entry.displayDefinition),
      );
    }
    return List.unmodifiable(unique.values);
  });

  bool contains(
    LanguageMode mode, {
    required String id,
    required String spelling,
    required String definition,
  }) => words(mode).any(
    (word) =>
        word.id == id &&
        word.spelling == spelling &&
        word.definition == definition,
  );

  ScrambleWord? choose(
    LanguageMode mode, {
    required Random random,
    Set<String> seen = const {},
    String? previous,
  }) {
    final all = words(mode);
    if (all.isEmpty) return null;
    var candidates = all.where((word) => !seen.contains(word.id)).toList();
    if (candidates.isEmpty) {
      candidates = all.where((word) => word.id != previous).toList();
    }
    if (candidates.isEmpty) candidates = all;
    return candidates[random.nextInt(candidates.length)];
  }
}
