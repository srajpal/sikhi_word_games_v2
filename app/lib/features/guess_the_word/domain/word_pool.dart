import 'dart:math';

import 'package:characters/characters.dart';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/language/gurmukhi_normalization.dart';
import 'language_mode.dart';

class WordPool {
  WordPool(Iterable<VocabularyEntry> entries)
    : _entries = List.unmodifiable(entries);

  final List<VocabularyEntry> _entries;
  final _searchIndexes = <LanguageMode, List<(VocabularyEntry, String)>>{};
  final _previousSearches =
      <LanguageMode, (String, List<(VocabularyEntry, String)>)>{};

  List<VocabularyEntry> solutions({
    required LanguageMode mode,
    required int wordLength,
  }) => _bestBySpelling(
    _entries
        .where((entry) => entry.acceptedGuess && entry.solutionEligible)
        .where((entry) => _supportsLanguage(entry, mode))
        .where(
          (entry) => spelling(entry, mode)?.characters.length == wordLength,
        ),
    mode,
  );

  Set<String> acceptedGuesses({
    required LanguageMode mode,
    required int wordLength,
  }) => {
    for (final entry in _entries)
      if (entry.acceptedGuess &&
          _supportsLanguage(entry, mode) &&
          spelling(entry, mode)?.characters.length == wordLength)
        _normalize(spelling(entry, mode)!),
  };

  VocabularyEntry? entryForGuess({
    required LanguageMode mode,
    required String guess,
  }) {
    final normalizedGuess = _normalize(guess);
    final matches = _entries.where(
      (entry) =>
          entry.acceptedGuess &&
          _supportsLanguage(entry, mode) &&
          _normalizedSpelling(entry, mode) == normalizedGuess,
    );
    return _bestEntry(matches);
  }

  List<VocabularyEntry> search({
    required LanguageMode mode,
    required String query,
    int limit = 50,
  }) {
    final normalized = normalizeGurmukhi(query.trim()).toLowerCase();
    if (normalized.characters.length < 2 || limit <= 0) return const [];
    final index = _searchIndexes.putIfAbsent(
      mode,
      () => [
        for (final entry in _bestBySpelling(
          _entries.where(
            (entry) => entry.acceptedGuess && _supportsLanguage(entry, mode),
          ),
          mode,
        ))
          (entry, normalizeGurmukhi(spelling(entry, mode)!).toLowerCase()),
      ],
    );
    final previous = _previousSearches[mode];
    final candidates = previous != null && normalized.startsWith(previous.$1)
        ? previous.$2
        : index;
    final matches = candidates
        .where((entry) => entry.$2.contains(normalized))
        .toList(growable: false);
    // Keep every match for incremental filtering, not just the displayed 50.
    _previousSearches[mode] = (normalized, matches);
    return List.unmodifiable(matches.take(limit).map((entry) => entry.$1));
  }

  static List<VocabularyEntry> _bestBySpelling(
    Iterable<VocabularyEntry> entries,
    LanguageMode mode,
  ) {
    final best = <String, VocabularyEntry>{};
    for (final entry in entries) {
      final key = _normalizedSpelling(entry, mode);
      if (key == null || key.isEmpty) continue;
      final current = best[key];
      if (current == null || _isBetter(entry, current)) best[key] = entry;
    }
    return List.unmodifiable(best.values);
  }

  static VocabularyEntry? _bestEntry(Iterable<VocabularyEntry> entries) {
    VocabularyEntry? best;
    for (final entry in entries) {
      if (best == null || _isBetter(entry, best)) best = entry;
    }
    return best;
  }

  static bool _isBetter(VocabularyEntry candidate, VocabularyEntry current) {
    final candidateScore = _qualityScore(candidate);
    final currentScore = _qualityScore(current);
    return candidateScore > currentScore;
  }

  static int _qualityScore(VocabularyEntry entry) =>
      (_hasUsableDefinition(entry) ? 2 : 0) + (entry.solutionEligible ? 1 : 0);

  static bool _hasUsableDefinition(VocabularyEntry entry) =>
      entry.hasDistributableDefinition &&
      entry.englishDefinition.trim().isNotEmpty;

  static String? _normalizedSpelling(VocabularyEntry entry, LanguageMode mode) {
    final value = spelling(entry, mode);
    return value == null ? null : _normalize(value);
  }

  static String _normalize(String value) =>
      normalizeGurmukhi(value.trim().toUpperCase());

  static String? spelling(VocabularyEntry entry, LanguageMode mode) =>
      mode == LanguageMode.gurmukhi ? entry.gurmukhi : entry.latin;

  static bool _supportsLanguage(VocabularyEntry entry, LanguageMode mode) =>
      switch (mode) {
        LanguageMode.english => entry.language == VocabularyLanguage.english,
        LanguageMode.romanizedPanjabi ||
        LanguageMode.gurmukhi => entry.language == VocabularyLanguage.panjabi,
        LanguageMode.mixedLatin => true,
      };
}

class NonRepeatingWordSelector {
  NonRepeatingWordSelector({
    Random? random,
    Iterable<String> usedIds = const [],
    this.lastSelectedId,
  }) : _random = random ?? Random.secure(),
       _usedIds = {...usedIds};

  final Random _random;
  final Set<String> _usedIds;
  String? lastSelectedId;

  Set<String> get usedIds => Set.unmodifiable(_usedIds);

  VocabularyEntry select(List<VocabularyEntry> candidates) {
    if (candidates.isEmpty) {
      throw StateError('No eligible solutions are available.');
    }
    var available = candidates
        .where((entry) => !_usedIds.contains(entry.id))
        .toList();
    if (available.isEmpty) {
      final candidateIds = candidates.map((entry) => entry.id).toSet();
      _usedIds.removeAll(candidateIds);
      available = candidates
          .where((entry) => entry.id != lastSelectedId)
          .toList();
      if (available.isEmpty) available = List.of(candidates);
    }
    final selected = available[_random.nextInt(available.length)];
    _usedIds.add(selected.id);
    lastSelectedId = selected.id;
    return selected;
  }

  void markUsed(String id) {
    _usedIds.add(id);
    lastSelectedId = id;
  }
}
