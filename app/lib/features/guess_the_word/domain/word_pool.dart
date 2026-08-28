import 'dart:math';

import 'package:characters/characters.dart';

import '../../../core/content/vocabulary_entry.dart';
import 'language_mode.dart';

class WordPool {
  WordPool(Iterable<VocabularyEntry> entries)
    : _entries = List.unmodifiable(entries);

  final List<VocabularyEntry> _entries;

  List<VocabularyEntry> solutions({
    required LanguageMode mode,
    required int wordLength,
  }) => _entries
      .where((entry) => entry.solutionEligible)
      .where((entry) => _supportsLanguage(entry, mode))
      .where((entry) => spelling(entry, mode)?.characters.length == wordLength)
      .toList(growable: false);

  Set<String> acceptedGuesses({
    required LanguageMode mode,
    required int wordLength,
  }) => {
    for (final entry in _entries)
      if (entry.acceptedGuess &&
          _supportsLanguage(entry, mode) &&
          spelling(entry, mode)?.characters.length == wordLength)
        spelling(entry, mode)!.toUpperCase(),
  };

  VocabularyEntry? entryForGuess({
    required LanguageMode mode,
    required String guess,
  }) {
    final normalizedGuess = guess.trim().toUpperCase();
    for (final entry in _entries) {
      if (entry.acceptedGuess &&
          _supportsLanguage(entry, mode) &&
          spelling(entry, mode)?.toUpperCase() == normalizedGuess) {
        return entry;
      }
    }
    return null;
  }

  List<VocabularyEntry> search({
    required LanguageMode mode,
    required String query,
    int limit = 50,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2 || limit <= 0) return const [];
    final matches = <VocabularyEntry>[];
    for (final entry in _entries) {
      if (!_supportsLanguage(entry, mode)) continue;
      final activeSpelling = spelling(entry, mode)?.toLowerCase();
      if (activeSpelling == null) continue;
      if (activeSpelling.contains(normalized)) {
        matches.add(entry);
        if (matches.length == limit) break;
      }
    }
    return List.unmodifiable(matches);
  }

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
