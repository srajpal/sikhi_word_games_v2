import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/word_search_puzzle.dart';

class WordSearchSession {
  const WordSearchSession({
    required this.mode,
    required this.wordSize,
    required this.puzzle,
    required this.foundWords,
  });

  final LanguageMode mode;
  final int? wordSize;
  final WordSearchPuzzle puzzle;
  final Set<String> foundWords;
}

class WordSearchSessionRepository {
  const WordSearchSessionRepository(this._store);

  static const storageKey = 'wordSearch.activeGame';
  final KeyValueStore _store;

  bool get hasActiveGame => restore() != null;

  Future<void> save({
    required LanguageMode mode,
    required int? wordSize,
    required WordSearchPuzzle puzzle,
    required Set<String> foundWords,
  }) => _store.setString(
    storageKey,
    jsonEncode({
      'schemaVersion': 1,
      'mode': mode.name,
      'wordSize': wordSize,
      'puzzle': puzzle.toJson(),
      'foundWords': foundWords.toList(growable: false),
    }),
  );

  WordSearchSession? restore() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['schemaVersion'] != 1 ||
          json['mode'] is! String ||
          json['puzzle'] is! Map<String, Object?> ||
          json['foundWords'] is! List) {
        return null;
      }
      final mode = LanguageMode.values.firstWhere(
        (value) => value.name == json['mode'],
      );
      final wordSize = json['wordSize'];
      if (wordSize != null && wordSize is! int) return null;
      final puzzle = WordSearchPuzzle.fromJson(
        json['puzzle']! as Map<String, Object?>,
      );
      final foundWords = <String>{};
      for (final value in json['foundWords']! as List<Object?>) {
        if (value is! String ||
            !puzzle.words.any((word) => word.word == value) ||
            !foundWords.add(value)) {
          return null;
        }
      }
      if (foundWords.length == puzzle.words.length) return null;
      return WordSearchSession(
        mode: mode,
        wordSize: wordSize as int?,
        puzzle: puzzle,
        foundWords: foundWords,
      );
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> clear() => _store.remove(storageKey);
}
