import 'dart:convert';

import '../persistence/key_value_store.dart';

/// Finished attempts only. Leaving a game never creates a loss.
class GameStatistics {
  const GameStatistics({
    this.played = 0,
    this.won = 0,
    this.hintedWins = 0,
    this.wordsFound = 0,
  });
  final int played;
  final int won;
  final int hintedWins;
  final int wordsFound;

  GameStatistics plus(GameStatistics other) => GameStatistics(
    played: played + other.played,
    won: won + other.won,
    hintedWins: hintedWins + other.hintedWins,
    wordsFound: wordsFound + other.wordsFound,
  );
  Map<String, int> toJson() => {
    'played': played,
    'won': won,
    'hintedWins': hintedWins,
    'wordsFound': wordsFound,
  };
  factory GameStatistics.fromJson(Map<String, Object?> json) {
    int read(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw const FormatException('Invalid count');
      }
      return value;
    }

    final result = GameStatistics(
      played: read('played'),
      won: read('won'),
      hintedWins: read('hintedWins'),
      wordsFound: read('wordsFound'),
    );
    if (result.won > result.played || result.hintedWins > result.won) {
      throw const FormatException('Invalid results');
    }
    return result;
  }
}

class GameStatisticsRepository {
  const GameStatisticsRepository(this._store, this.gameId);
  final KeyValueStore _store;
  final String gameId;
  String get storageKey => '$gameId.statistics.v1';

  Map<String, GameStatistics> load() {
    try {
      final raw = _store.getString(storageKey);
      if (raw == null) return {};
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['schemaVersion'] != 1) return {};
      final buckets = json['buckets'] as Map<String, dynamic>;
      return buckets.map(
        (key, value) => MapEntry(
          key,
          GameStatistics.fromJson(value as Map<String, dynamic>),
        ),
      );
    } on Object catch (_) {
      return {};
    }
  }

  GameStatistics get total => load().values.fold(
    const GameStatistics(),
    (sum, value) => sum.plus(value),
  );
  GameStatistics forMode(String mode, int? size) =>
      load()['$mode:${size ?? 'mixed'}'] ?? const GameStatistics();

  Future<void> record({
    required String mode,
    required int? size,
    required bool won,
    int hintsUsed = 0,
    int wordsFound = 0,
  }) {
    if (hintsUsed < 0 || wordsFound < 0) {
      throw ArgumentError('Counts must be nonnegative');
    }
    return KeyValueStoreWrites.run(_store, storageKey, () async {
      final buckets = load();
      final key = '$mode:${size ?? 'mixed'}';
      buckets[key] = (buckets[key] ?? const GameStatistics()).plus(
        GameStatistics(
          played: 1,
          won: won ? 1 : 0,
          hintedWins: won && hintsUsed > 0 ? 1 : 0,
          wordsFound: wordsFound,
        ),
      );
      return _store.setString(
        storageKey,
        jsonEncode({
          'schemaVersion': 1,
          'buckets': buckets.map((key, value) => MapEntry(key, value.toJson())),
        }),
      );
    });
  }

  Future<void> resetAll() => KeyValueStoreWrites.remove(_store, storageKey);
}
