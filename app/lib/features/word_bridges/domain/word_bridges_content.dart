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
      final seenMeanings = <String>{};
      final candidates = <BridgePair>[];
      for (final entry in byId.values) {
        if (duplicateIds.contains(entry.id) ||
            !entry.acceptedGuess ||
            !entry.solutionEligible ||
            !entry.hasDistributableDefinition ||
            (entry.language == VocabularyLanguage.english) !=
                (mode == LanguageMode.english)) {
          continue;
        }
        final word =
            (mode == LanguageMode.gurmukhi ? entry.gurmukhi ?? '' : entry.latin)
                .trim();
        final meaning = entry.displayDefinition.trim();
        if (word.isEmpty || meaning.length > 180 || meaning.length < 4) {
          continue;
        }
        final spelling = word.toLowerCase();
        final fingerprint = meaning
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();
        if (seenWords.contains(spelling) ||
            seenMeanings.contains(fingerprint)) {
          continue;
        }
        seenWords.add(spelling);
        seenMeanings.add(fingerprint);
        candidates.add(BridgePair(id: entry.id, word: word, meaning: meaning));
        if (mode == LanguageMode.gurmukhi) {
          _romanizedById[entry.id] = entry.latin.trim();
        }
      }
      _pairsByMode[mode] = List.unmodifiable(candidates);
      for (final specification in _decks.entries) {
        final isEnglish = specification.key.startsWith('english_');
        if (isEnglish != (mode == LanguageMode.english)) continue;
        final pairs = <BridgePair>[];
        for (final id in specification.value) {
          final entry = byId[id];
          if (entry == null ||
              duplicateIds.contains(id) ||
              !entry.acceptedGuess ||
              !entry.solutionEligible ||
              !entry.hasDistributableDefinition ||
              entry.language !=
                  (isEnglish
                      ? VocabularyLanguage.english
                      : VocabularyLanguage.panjabi)) {
            break;
          }
          final word =
              (mode == LanguageMode.gurmukhi
                      ? entry.gurmukhi ?? ''
                      : entry.latin)
                  .trim();
          if (word.isEmpty) break;
          pairs.add(
            BridgePair(id: id, word: word, meaning: entry.displayDefinition),
          );
        }
        if (pairs.length != 4 ||
            pairs.map((pair) => pair.word.toLowerCase()).toSet().length != 4 ||
            pairs
                    .map((pair) => pair.meaning.trim().toLowerCase())
                    .toSet()
                    .length !=
                4) {
          continue;
        }
        decks.add(WordBridgesDeck(id: specification.key, pairs: pairs));
        if (mode == LanguageMode.gurmukhi) {
          for (final pair in pairs) {
            final romanized = byId[pair.id]!.latin.trim();
            if (romanized.isNotEmpty) _romanizedById[pair.id] = romanized;
          }
        }
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

  static const _decks = <String, List<String>>{
    'english_everyday': [
      'en_v2_book',
      'en_v2_door',
      'en_v2_chair',
      'en_v2_milk',
    ],
    'english_outdoors_and_food': [
      'en_v2_rain',
      'en_v2_river',
      'en_v2_bread',
      'en_v2_apple',
    ],
    'punjabi_everyday': [
      'panjabi_v2_a15_a3f_a24_a3e_a2c',
      'panjabi_v2_a2a_a3e_a23_a40',
      'panjabi_v2_a30_a4b_a1f_a40',
      'panjabi_v2_a26_a41_a71_a27',
    ],
    'punjabi_connections': [
      'panjabi_v2_a2b_a41_a71_a32',
      'panjabi_v2_a26_a4b_a38_a24',
      'panjabi_v2_a1a_a70_a26',
      'panjabi_v2_a30_a41_a71_a16',
    ],
  };
}
