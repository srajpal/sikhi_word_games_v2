import 'dart:math';

import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_source.dart';
import '../../guess_the_word/domain/language_mode.dart';
import 'word_bridges_game.dart';

class WordBridgesDeck {
  WordBridgesDeck({required this.id, required Iterable<BridgePair> pairs})
    : pairs = List.unmodifiable(pairs);

  final String id;
  final List<BridgePair> pairs;
}

/// Eligible release words form randomized sets with competing clues filtered.
/// Selection does not grant editorial approval. Definitions and spellings
/// remain owned by the release vocabulary and its curation workflow.
class WordBridgesContent {
  WordBridgesContent(Iterable<VocabularyEntry> entries) {
    final byId = <String, VocabularyEntry>{};
    final duplicateIds = <String>{};
    for (final entry in entries) {
      if (byId.containsKey(entry.id)) duplicateIds.add(entry.id);
      byId[entry.id] = entry;
    }
    for (final mode in const [
      LanguageMode.english,
      LanguageMode.romanizedPanjabi,
      LanguageMode.gurmukhi,
    ]) {
      final decks = <WordBridgesDeck>[];
      final seenWords = <String>{};
      final candidates = <BridgePair>[];
      for (final entry in byId.values) {
        if (duplicateIds.contains(entry.id) ||
            !entry.acceptedGuess ||
            !entry.solutionEligible ||
            !entry.hasDistributableDefinition ||
            !entry.supportsScript(mode.script)) {
          continue;
        }
        final word =
            (mode == LanguageMode.gurmukhi ? entry.gurmukhi ?? '' : entry.latin)
                .trim();
        final meaning = entry.displayDefinition.trim();
        if (word.isEmpty ||
            meaning.isEmpty ||
            (!entry.isOwnerApproved &&
                (meaning.length > 180 || meaning.length < 4))) {
          continue;
        }
        final spelling = word.toLowerCase();
        if (!seenWords.add(spelling)) continue;
        candidates.add(BridgePair(id: entry.id, word: word, meaning: meaning));
        if (mode == LanguageMode.gurmukhi) {
          _romanizedById[entry.id] = entry.latin.trim();
        }
      }
      _pairsByMode[mode] = List.unmodifiable(candidates);
      if (candidates.length >= 4) {
        decks.add(
          WordBridgesDeck(
            id: '${mode.name}_preview',
            pairs: candidates.take(4),
          ),
        );
      }
      _byMode[mode] = List.unmodifiable(decks);
    }
  }

  final Map<LanguageMode, List<WordBridgesDeck>> _byMode = {};
  final Map<LanguageMode, List<BridgePair>> _pairsByMode = {};
  final Map<String, String> _romanizedById = {};

  /// Source spelling for a currently eligible Gurmukhi word.
  /// Resolve by ID for both new and restored pairs; do not persist a second
  /// copy of content in the game session or derive a transliteration here.
  String? romanizedFor(String id) => _romanizedById[id];

  static Future<WordBridgesContent> load(
    VocabularyRepository repository,
  ) async => WordBridgesContent(await repository.load());

  List<LanguageMode> get availableModes => List.unmodifiable(
    _pairsByMode.entries
        .where((entry) => entry.value.length >= 4)
        .map((e) => e.key),
  );

  List<WordBridgesDeck> decksFor(LanguageMode mode) =>
      _byMode[mode] ?? const [];

  List<BridgePair> pairsFor(LanguageMode mode) =>
      _pairsByMode[mode] ?? const [];

  bool containsPair(LanguageMode mode, BridgePair saved) => pairsFor(mode).any(
    (pair) =>
        pair.id == saved.id &&
        pair.word == saved.word &&
        pair.meaning == saved.meaning,
  );

  /// Prefer unused words, then cycle only as needed. Near-identical meanings,
  /// substring clues and words which appear in a competing clue cannot coexist.
  List<BridgePair>? chooseSet(
    LanguageMode mode, {
    required Random random,
    Set<String> usedIds = const {},
    Set<String> previousIds = const {},
  }) {
    final all = [...pairsFor(mode)]..shuffle(random);
    final ranks = {for (var i = 0; i < all.length; i++) all[i].id: i};
    all.sort((a, b) {
      int priority(BridgePair p) => previousIds.contains(p.id)
          ? 2
          : usedIds.contains(p.id)
          ? 1
          : 0;
      final comparison = priority(a).compareTo(priority(b));
      return comparison == 0
          ? ranks[a.id]!.compareTo(ranks[b.id]!)
          : comparison;
    });
    for (var start = 0; start < min(all.length, 64); start++) {
      final selected = <BridgePair>[all[start]];
      for (final candidate in all) {
        if (candidate.id == all[start].id) continue;
        if (selected.every((pair) => !ambiguous(pair, candidate))) {
          selected.add(candidate);
        }
        if (selected.length == 4) return List.unmodifiable(selected);
      }
    }
    return null;
  }

  static bool ambiguous(BridgePair a, BridgePair b) {
    Set<String> tokens(String text) => text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where(
          (word) =>
              word.length > 2 &&
              !const {
                'the',
                'and',
                'for',
                'with',
                'that',
                'from',
                'which',
                'someone',
                'something',
              }.contains(word),
        )
        .toSet();
    final x = tokens(a.meaning), y = tokens(b.meaning);
    final overlap = x.intersection(y).length;
    bool leaks(BridgePair word, BridgePair clue) =>
        tokens(clue.meaning).contains(word.word.toLowerCase());
    return leaks(a, b) ||
        leaks(b, a) ||
        (overlap > 0 && overlap / min(x.length, y.length) >= .6);
  }
}
