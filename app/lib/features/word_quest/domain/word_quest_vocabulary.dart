import 'dart:math';

import 'package:characters/characters.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../guess_the_word/domain/language_mode.dart';
import 'word_quest_definition_quality.dart';

/// A playable Word Quest answer together with the child-friendly clue data
/// available in the vocabulary record.
class WordQuestWord {
  const WordQuestWord({
    required this.id,
    required this.language,
    required this.spelling,
    required this.definitionHint,
    required this.categoryHint,
    required this.source,
  });

  final String id;
  final VocabularyLanguage language;
  final String spelling;
  final String definitionHint;
  final String categoryHint;
  final String source;

  int get graphemeLength => spelling.characters.length;

  /// Short words are normally easier for younger players to sound out.
  bool get isKidManageable => graphemeLength >= 2 && graphemeLength <= 7;
}

/// Builds language-aware, de-duplicated Word Quest candidates from the
/// curated, solution-eligible vocabulary.
///
/// Word Quest is aimed at children, so ordinary guess-only dictionary entries
/// are never promoted to answers. A word must be explicitly solution eligible
/// and have a standalone clue that passes the child-facing quality gate.
class WordQuestVocabulary {
  WordQuestVocabulary(Iterable<VocabularyEntry> entries)
    : _entries = List.unmodifiable(entries);

  final List<VocabularyEntry> _entries;

  static Future<WordQuestVocabulary> load(
    VocabularyRepository repository,
  ) async => WordQuestVocabulary(await repository.load());

  /// Returns accepted, defined entries in the spelling used by [mode].
  ///
  /// The preferred 3--7-grapheme candidates are returned whenever at least one
  /// is available. If a small vocabulary cannot supply one, longer or shorter
  /// defined entries are a graceful fallback instead of leaving the game empty.
  List<WordQuestWord> words({
    required LanguageMode mode,
    bool preferKidManageable = true,
  }) {
    final all = _deduplicatedWords(mode);
    if (!preferKidManageable) return all;
    final manageable = all
        .where((word) => word.isKidManageable)
        .toList(growable: false);
    return manageable.isEmpty ? all : List.unmodifiable(manageable);
  }

  /// Looks up a playable word by its active-mode spelling.
  WordQuestWord? wordForSpelling({
    required LanguageMode mode,
    required String spelling,
    bool preferKidManageable = false,
  }) {
    final normalized = _normalize(spelling);
    if (normalized.isEmpty) return null;
    for (final word in words(
      mode: mode,
      preferKidManageable: preferKidManageable,
    )) {
      if (_normalize(word.spelling) == normalized) return word;
    }
    return null;
  }

  List<WordQuestWord> _deduplicatedWords(LanguageMode mode) {
    final bestBySpelling = <String, VocabularyEntry>{};
    for (final entry in _entries) {
      if (!entry.acceptedGuess ||
          !entry.solutionEligible ||
          !_supports(entry, mode)) {
        continue;
      }
      final spelling = _spelling(entry, mode)?.trim();
      if (spelling == null || spelling.isEmpty) continue;
      if (WordQuestDefinitionQuality.usableClue(
            answer: spelling,
            clue: entry.englishDefinition,
          ) ==
          null) {
        continue;
      }
      final key = _normalize(spelling);
      final current = bestBySpelling[key];
      if (current == null || _isBetter(entry, current)) {
        bestBySpelling[key] = entry;
      }
    }

    final words =
        bestBySpelling.values
            .map(
              (entry) => WordQuestWord(
                id: entry.id,
                language: entry.language,
                spelling: _visibleSpelling(entry, mode),
                definitionHint: WordQuestDefinitionQuality.usableClue(
                  answer: _spelling(entry, mode)!,
                  clue: entry.englishDefinition,
                )!,
                categoryHint: _categoryFor(entry),
                source: entry.source,
              ),
            )
            .toList()
          ..sort((left, right) => left.spelling.compareTo(right.spelling));
    return List.unmodifiable(words);
  }

  static String? _spelling(VocabularyEntry entry, LanguageMode mode) =>
      mode == LanguageMode.gurmukhi ? entry.gurmukhi : entry.latin;

  static String _visibleSpelling(VocabularyEntry entry, LanguageMode mode) {
    final spelling = _spelling(entry, mode)!.trim();
    return mode == LanguageMode.gurmukhi ? spelling : spelling.toUpperCase();
  }

  static bool _supports(VocabularyEntry entry, LanguageMode mode) =>
      switch (mode) {
        LanguageMode.english => entry.language == VocabularyLanguage.english,
        LanguageMode.romanizedPanjabi ||
        LanguageMode.gurmukhi => entry.language == VocabularyLanguage.panjabi,
        LanguageMode.mixedLatin => true,
      };

  static String _normalize(String spelling) => spelling.trim().toUpperCase();

  static bool _isBetter(VocabularyEntry contender, VocabularyEntry current) {
    final contenderScore = _qualityScore(contender);
    final currentScore = _qualityScore(current);
    if (contenderScore != currentScore) return contenderScore > currentScore;
    return contender.id.compareTo(current.id) < 0;
  }

  static int _qualityScore(VocabularyEntry entry) =>
      (entry.solutionEligible ? 10 : 0) + entry.reviewStatus.index;

  static String _categoryFor(VocabularyEntry entry) {
    final source = entry.source.toLowerCase();
    if (source.contains('mahan kosh')) return 'Sikhi vocabulary';
    return entry.language == VocabularyLanguage.english
        ? 'English word'
        : 'Panjabi word';
  }
}

/// Selects a random candidate and avoids repeats until a candidate set has
/// been exhausted. Supplying [random] makes selections deterministic in tests.
class WordQuestWordSelector {
  WordQuestWordSelector({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final Set<String> _usedIds = <String>{};
  String? _lastSelectedId;

  Set<String> get usedIds => Set.unmodifiable(_usedIds);

  WordQuestWord select(Iterable<WordQuestWord> candidates) {
    final all = candidates.toList(growable: false);
    if (all.isEmpty) {
      throw StateError('No playable Word Quest words are available.');
    }

    var available = all.where((word) => !_usedIds.contains(word.id)).toList();
    if (available.isEmpty) {
      final candidateIds = all.map((word) => word.id).toSet();
      _usedIds.removeAll(candidateIds);
      available = all.where((word) => word.id != _lastSelectedId).toList();
      if (available.isEmpty) available = List.of(all);
    }
    final selected = available[_random.nextInt(available.length)];
    _usedIds.add(selected.id);
    _lastSelectedId = selected.id;
    return selected;
  }
}
