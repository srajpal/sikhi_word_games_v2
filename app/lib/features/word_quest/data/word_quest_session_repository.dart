import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/word_quest_game.dart';

class WordQuestSession {
  const WordQuestSession({
    required this.mode,
    required this.wordSize,
    required this.game,
  });

  final LanguageMode mode;
  final int wordSize;
  final WordQuestGame game;
}

class WordQuestSessionRepository {
  const WordQuestSessionRepository(this._store);

  static const storageKey = 'wordQuest.activeGame';
  final KeyValueStore _store;

  bool get hasActiveGame => restore() != null;

  Future<void> save({
    required LanguageMode mode,
    required int wordSize,
    required WordQuestGame game,
  }) => _store.setString(
    storageKey,
    jsonEncode({
      'schemaVersion': 1,
      'mode': mode.name,
      'wordSize': wordSize,
      'game': game.toJson(),
    }),
  );

  WordQuestSession? restore() {
    final encoded = _store.getString(storageKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['schemaVersion'] != 1 ||
          json['mode'] is! String ||
          json['wordSize'] is! int ||
          json['game'] is! Map<String, Object?>) {
        return null;
      }
      final mode = LanguageMode.values.firstWhere(
        (value) => value.name == json['mode'],
      );
      final game = WordQuestGame.restore(json['game']! as Map<String, Object?>);
      if (game.isComplete) return null;
      return WordQuestSession(
        mode: mode,
        wordSize: json['wordSize']! as int,
        game: game,
      );
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> clear() => _store.remove(storageKey);
}
