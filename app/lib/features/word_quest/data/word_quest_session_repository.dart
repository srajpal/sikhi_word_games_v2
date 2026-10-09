import '../../../core/persistence/reset_sections.dart';
import '../../../core/statistics/game_statistics_repository.dart';

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

  GameStatisticsRepository get statistics =>
      GameStatisticsRepository(_store, 'wordQuest');

  bool get hasActiveGame => restore() != null;

  Future<void> save({
    required LanguageMode mode,
    required int wordSize,
    required WordQuestGame game,
  }) => KeyValueStoreWrites.setString(
    _store,
    storageKey,
    jsonEncode({
      'schemaVersion':
          game.maximumTries ==
              WordQuestGame.recommendedMaximumTriesForSolution(game.solution) +
                  2
          ? 1
          : 2,
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
      if (!const [1, 2].contains(json['schemaVersion']) ||
          json['mode'] is! String ||
          json['wordSize'] is! int ||
          !const [4, 5, 6].contains(json['wordSize']) ||
          json['game'] is! Map<String, Object?>) {
        return null;
      }
      final mode = LanguageMode.values.firstWhere(
        (value) => value.name == json['mode'],
      );
      final game = WordQuestGame.restore(json['game']! as Map<String, Object?>);
      final budget = json['schemaVersion'] == 1
          ? WordQuestGame.recommendedMaximumTriesForSolution(game.solution) + 2
          : WordQuestGame.recommendedMaximumTriesForSolution(game.solution);
      if (game.isComplete ||
          game.maximumTries != budget ||
          game.solutionGraphemes.length != json['wordSize']) {
        return null;
      }
      return WordQuestSession(
        mode: mode,
        wordSize: json['wordSize']! as int,
        game: game,
      );
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> resetAll() => resetSections({
    'Saved game': () => clear(),
    'Statistics': statistics.resetAll,
  });

  Future<void> clear({Future<void>? after}) =>
      KeyValueStoreWrites.remove(_store, storageKey, after: after);
}
