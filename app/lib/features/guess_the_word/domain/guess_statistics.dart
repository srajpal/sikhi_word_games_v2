import 'language_mode.dart';

class GuessStatistics {
  const GuessStatistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.winDistribution = const {},
  });

  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final Map<int, int> winDistribution;

  int get winPercentage =>
      gamesPlayed == 0 ? 0 : ((gamesWon / gamesPlayed) * 100).round();

  GuessStatistics record({required bool won, required int attempts}) {
    final streak = won ? currentStreak + 1 : 0;
    final distribution = Map<int, int>.of(winDistribution);
    if (won) distribution[attempts] = (distribution[attempts] ?? 0) + 1;
    return GuessStatistics(
      gamesPlayed: gamesPlayed + 1,
      gamesWon: gamesWon + (won ? 1 : 0),
      currentStreak: streak,
      bestStreak: streak > bestStreak ? streak : bestStreak,
      winDistribution: distribution,
    );
  }

  Map<String, Object> toJson() => {
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'winDistribution': {
      for (final entry in winDistribution.entries)
        entry.key.toString(): entry.value,
    },
  };

  factory GuessStatistics.fromJson(Map<String, Object?> json) {
    final rawDistribution = json['winDistribution'];
    if (rawDistribution is! Map<String, Object?>) {
      throw const FormatException('Malformed win distribution.');
    }
    return GuessStatistics(
      gamesPlayed: json['gamesPlayed']! as int,
      gamesWon: json['gamesWon']! as int,
      currentStreak: json['currentStreak']! as int,
      bestStreak: json['bestStreak']! as int,
      winDistribution: {
        for (final entry in rawDistribution.entries)
          int.parse(entry.key): entry.value! as int,
      },
    );
  }
}

class GuessStatisticsBook {
  const GuessStatisticsBook([this.records = const {}]);

  static const currentSchemaVersion = 1;
  final Map<String, GuessStatistics> records;

  static String key(LanguageMode mode, int wordLength) =>
      '${mode.name}:$wordLength';

  GuessStatistics forGame(LanguageMode mode, int wordLength) =>
      records[key(mode, wordLength)] ?? const GuessStatistics();

  GuessStatisticsBook record({
    required LanguageMode mode,
    required int wordLength,
    required bool won,
    required int attempts,
  }) {
    final updated = Map<String, GuessStatistics>.of(records);
    final recordKey = key(mode, wordLength);
    updated[recordKey] = forGame(
      mode,
      wordLength,
    ).record(won: won, attempts: attempts);
    return GuessStatisticsBook(updated);
  }

  Map<String, Object> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'records': {
      for (final entry in records.entries) entry.key: entry.value.toJson(),
    },
  };

  factory GuessStatisticsBook.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != currentSchemaVersion ||
        json['records'] is! Map<String, Object?>) {
      throw const FormatException('Unsupported statistics snapshot.');
    }
    final rawRecords = json['records']! as Map<String, Object?>;
    return GuessStatisticsBook({
      for (final entry in rawRecords.entries)
        entry.key: GuessStatistics.fromJson(
          entry.value! as Map<String, Object?>,
        ),
    });
  }
}
