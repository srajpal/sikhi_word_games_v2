import 'dart:convert';
import 'dart:math';

import '../../../core/persistence/key_value_store.dart';
import '../domain/learn_letters_game.dart';

class LearnLettersStatistics {
  const LearnLettersStatistics({
    this.roundsCompleted = 0,
    this.answers = 0,
    this.firstTryCorrect = 0,
  });
  final int roundsCompleted;

  /// All distinct submitted choices, including wrong attempts, in completed rounds.
  final int answers;
  final int firstTryCorrect;
  Map<String, Object?> toJson() => {
    'roundsCompleted': roundsCompleted,
    'answers': answers,
    'firstTryCorrect': firstTryCorrect,
  };
  factory LearnLettersStatistics.fromJson(Map<String, Object?> json) {
    final rounds = json['roundsCompleted'] as int;
    final answers = json['answers'] as int;
    final correct = json['firstTryCorrect'] as int;
    if (rounds < 0 ||
        answers < rounds * 5 ||
        answers > rounds * 15 ||
        correct < 0 ||
        correct > rounds * 5 ||
        answers < rounds * 10 - correct ||
        answers > rounds * 15 - correct * 2) {
      throw const FormatException('Invalid letter statistics');
    }
    return LearnLettersStatistics(
      roundsCompleted: rounds,
      answers: answers,
      firstTryCorrect: correct,
    );
  }
}

/// A single key atomically commits sessions, completion IDs and letter mastery.
class LearnLettersRepository {
  const LearnLettersRepository(this._store);
  static const storageKey = 'learnLetters.state.v1';
  final KeyValueStore _store;

  Map<String, Object?> _load() {
    try {
      final raw = _store.getString(storageKey);
      if (raw == null) return {};
      final state = jsonDecode(raw) as Map<String, Object?>;
      if (state['schemaVersion'] != 1) return {};
      final stats = LearnLettersStatistics.fromJson(
        state['statistics'] as Map<String, Object?>,
      );
      final mastery = (state['mastery'] as Map<String, Object?>)
          .cast<String, int>();
      final completed = (state['completedRoundIds'] as List).cast<String>();
      if (completed.toSet().length != completed.length ||
          completed.length != stats.roundsCompleted ||
          completed.any((id) => id.isEmpty || id.length > 160) ||
          mastery.entries.any(
            (entry) =>
                !learnLettersById.containsKey(entry.key) ||
                entry.value < 0 ||
                entry.value > stats.roundsCompleted,
          ) ||
          mastery.values.fold(0, (sum, value) => sum + value) !=
              stats.firstTryCorrect) {
        return {};
      }
      return state;
    } on Object {
      return {};
    }
  }

  LearnLettersStatistics get statistics {
    final value = _load()['statistics'];
    return value == null
        ? const LearnLettersStatistics()
        : LearnLettersStatistics.fromJson(value as Map<String, Object?>);
  }

  Map<String, int> get mastery => Map.unmodifiable(
    (_load()['mastery'] as Map<String, Object?>? ?? {}).cast<String, int>(),
  );
  bool get hasActiveGame => restore() != null;
  LearnLettersGame newGame({Random? random}) =>
      LearnLettersGame.newRound(mastery: mastery, random: random);

  LearnLettersGame? restore() {
    try {
      final state = _load();
      final game = LearnLettersGame.fromJson(
        state['session'] as Map<String, Object?>,
      );
      if (game.isComplete ||
          (state['completedRoundIds'] as List).contains(game.roundId)) {
        return null;
      }
      return game;
    } on Object {
      return null;
    }
  }

  Future<void> save(LearnLettersGame game) {
    // Capture mutable round data before entering the shared key's write queue.
    final snapshot = game.toJson();
    final frozen = LearnLettersGame.fromJson(snapshot);
    return KeyValueStoreWrites.run(_store, storageKey, () async {
      final state = _load();
      final completed = (state['completedRoundIds'] as List? ?? [])
          .cast<String>()
          .toSet();
      if (completed.contains(frozen.roundId)) return;
      var stats = state['statistics'] == null
          ? const LearnLettersStatistics()
          : LearnLettersStatistics.fromJson(
              state['statistics'] as Map<String, Object?>,
            );
      final mastery = (state['mastery'] as Map<String, Object?>? ?? {})
          .cast<String, int>();
      if (frozen.isComplete) {
        completed.add(frozen.roundId);
        stats = LearnLettersStatistics(
          roundsCompleted: stats.roundsCompleted + 1,
          answers: stats.answers + frozen.attempts,
          firstTryCorrect: stats.firstTryCorrect + frozen.firstTryCorrect,
        );
        for (final id in frozen.firstTryLetterIds) {
          mastery[id] = (mastery[id] ?? 0) + 1;
        }
        final session = state['session'];
        if (session is Map && session['roundId'] == frozen.roundId) {
          state.remove('session');
        }
      } else {
        state['session'] = snapshot;
      }
      state.addAll({
        'schemaVersion': 1,
        'statistics': stats.toJson(),
        'mastery': mastery,
        'completedRoundIds': completed.toList(),
      });
      await _store.setString(storageKey, jsonEncode(state));
    });
  }

  Future<void> resetAll() => KeyValueStoreWrites.remove(_store, storageKey);
}
