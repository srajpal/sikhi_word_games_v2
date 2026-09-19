import 'dart:convert';

import '../../../core/persistence/key_value_store.dart';
import '../../guess_the_word/domain/language_mode.dart';
import '../domain/word_bridges_game.dart';

class WordBridgesSession {
  const WordBridgesSession({required this.mode, required this.game});
  final LanguageMode mode;
  final WordBridgesGame game;
}

class BridgeStatistics {
  const BridgeStatistics({
    this.finishedSets = 0,
    this.pairsMatched = 0,
    this.attempts = 0,
  });
  final int finishedSets;
  final int pairsMatched;
  final int attempts;
  BridgeStatistics plus(BridgeStatistics other) => BridgeStatistics(
    finishedSets: finishedSets + other.finishedSets,
    pairsMatched: pairsMatched + other.pairsMatched,
    attempts: attempts + other.attempts,
  );
  Map<String, Object?> toJson() => {
    'finishedSets': finishedSets,
    'pairsMatched': pairsMatched,
    'attempts': attempts,
  };
  factory BridgeStatistics.fromJson(Map<String, Object?> json) {
    final sets = json['finishedSets'] as int;
    final pairs = json['pairsMatched'] as int;
    final attempts = json['attempts'] as int;
    if (sets < 0 || pairs != sets * 4 || attempts < pairs) {
      throw const FormatException('Invalid statistics');
    }
    return BridgeStatistics(
      finishedSets: sets,
      pairsMatched: pairs,
      attempts: attempts,
    );
  }
}

/// A single persisted value keeps completion, deduplication and progress atomic.
class WordBridgesRepository {
  WordBridgesRepository(this._store);
  static const storageKey = 'wordBridges.state.v1';
  final KeyValueStore _store;

  Map<String, Object?> _load() {
    try {
      final raw = _store.getString(storageKey);
      if (raw == null) return {};
      final state = jsonDecode(raw) as Map<String, Object?>;
      if (state['schemaVersion'] != 1) return {};
      return state;
    } on Object {
      return {};
    }
  }

  Map<String, BridgeStatistics> _buckets(Map<String, Object?> state) {
    try {
      final raw = state['statistics'] as Map<String, Object?>? ?? {};
      final buckets = <String, BridgeStatistics>{};
      for (final entry in raw.entries) {
        if (!LanguageMode.values.any((mode) => mode.name == entry.key)) {
          throw const FormatException('Invalid mode');
        }
        buckets[entry.key] = BridgeStatistics.fromJson(
          entry.value as Map<String, Object?>,
        );
      }
      return buckets;
    } on Object {
      return {};
    }
  }

  BridgeStatistics get total =>
      _buckets(_load()).values
          .fold(const BridgeStatistics(), (sum, value) => sum.plus(value));
  BridgeStatistics forMode(LanguageMode mode) =>
      _buckets(_load())[mode.name] ?? const BridgeStatistics();
  bool get hasActiveGame => restore() != null;

  WordBridgesSession? restore() {
    try {
      final state = _load();
      final raw = state['session'] as Map<String, Object?>;
      final mode = LanguageMode.values.byName(raw['mode'] as String);
      final game = WordBridgesGame.fromJson(
        raw['game'] as Map<String, Object?>,
      );
      if (game.isComplete) return null;
      return WordBridgesSession(mode: mode, game: game);
    } on Object {
      return null;
    }
  }

  Future<void> _update(void Function(Map<String, Object?>) change) {
    return KeyValueStoreWrites.run(_store, storageKey, () async {
      final state = _load();
      state['schemaVersion'] = 1;
      change(state);
      await _store.setString(storageKey, jsonEncode(state));
    });
  }

  Future<void> save({
    required LanguageMode mode,
    required WordBridgesGame game,
  }) {
    if (game.isComplete) return recordCompletion(mode: mode, game: game);
    final snapshot = game.toJson();
    return _update((state) {
      final completed = state['completedRoundIds'];
      if (completed is List && completed.contains(game.roundId)) return;
      state['session'] = {'mode': mode.name, 'game': snapshot};
    });
  }

  /// Remove session, statistics and completion IDs after all pending writes.
  Future<void> resetAll() => KeyValueStoreWrites.remove(_store, storageKey);

  Future<void> clear() => _update((state) {
    state.remove('session');
  });

  Future<void> recordCompletion({
    required LanguageMode mode,
    required WordBridgesGame game,
  }) {
    if (!game.isComplete) {
      throw ArgumentError('Only completed sets can be recorded');
    }
    final attempts = game.attempts;
    return _update((state) {
      final completed = (state['completedRoundIds'] as List? ?? [])
          .whereType<String>()
          .toSet();
      if (completed.add(game.roundId)) {
        final buckets = _buckets(state);
        buckets[mode.name] = (buckets[mode.name] ?? const BridgeStatistics())
            .plus(
              BridgeStatistics(
                finishedSets: 1,
                pairsMatched: 4,
                attempts: attempts,
              ),
            );
        state['statistics'] = buckets.map(
          (key, value) => MapEntry(key, value.toJson()),
        );
        state['completedRoundIds'] = completed.toList();
      }
      final session = state['session'];
      if (session is Map &&
          session['game'] is Map &&
          (session['game'] as Map)['roundId'] == game.roundId) {
        state.remove('session');
      }
    });
  }
}
