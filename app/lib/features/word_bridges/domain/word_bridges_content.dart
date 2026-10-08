import '../../../core/content/vocabulary_entry.dart';
import '../../../core/content/vocabulary_repository.dart';
import '../../guess_the_word/domain/language_mode.dart';
import 'word_bridges_game.dart';

class WordBridgesDeck {
  WordBridgesDeck({required this.id, required Iterable<BridgePair> pairs})
    : pairs = List.unmodifiable(pairs);

  final String id;
  final List<BridgePair> pairs;
}

/// Small fixed sets checked by an agent against the shipped definitions.
/// This selection does not grant human editorial approval. Definitions and
/// spellings remain owned by the release vocabulary and its curation workflow.
/// Fixed groups avoid introducing arbitrary synonyms as competing answers.
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
  final Map<String, String> _romanizedById = {};

  /// Source spelling for a word in a currently valid Gurmukhi deck.
  /// Resolve by ID for both new and restored pairs; do not persist a second
  /// copy of content in the game session or derive a transliteration here.
  String? romanizedFor(String id) => _romanizedById[id];

  static Future<WordBridgesContent> load(
    VocabularyRepository repository,
  ) async => WordBridgesContent(await repository.load());

  List<LanguageMode> get availableModes => List.unmodifiable(
    _byMode.entries.where((entry) => entry.value.isNotEmpty).map((e) => e.key),
  );

  List<WordBridgesDeck> decksFor(LanguageMode mode) =>
      _byMode[mode] ?? const [];

  static const _decks = <String, List<String>>{
    'english_everyday': [
      'english_book',
      'english_door',
      'english_chair',
      'english_milk',
    ],
    'english_outdoors_and_food': [
      'english_rain',
      'english_river',
      'english_bread',
      'english_apple',
    ],
    'punjabi_everyday': [
      'panjabi_ghar',
      'panjabi_pani',
      'panjabi_kitab',
      'panjabi_yaar',
    ],
    'punjabi_connections': [
      'panjabi_phull',
      'panjabi_seva',
      'panjabi_yaad',
      'panjabi_door',
    ],
  };
}
