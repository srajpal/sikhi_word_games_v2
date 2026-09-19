import 'package:flutter/material.dart';

import '../../../core/statistics/game_statistics_repository.dart';
import '../../guess_the_word/domain/guess_statistics.dart';
import '../../word_bridges/data/word_bridges_repository.dart';
import '../../learn_letters/data/learn_letters_repository.dart';

Future<void> showLibraryStatistics(
  BuildContext context, {
  required GuessStatisticsBook bujho,
  required GameStatistics khoj,
  required GameStatistics quest,
  BridgeStatistics? bridges,
  LearnLettersStatistics? letters,
}) {
  final bujhoPlayed = bujho.records.values.fold(
    0,
    (sum, record) => sum + record.gamesPlayed,
  );
  final bujhoWon = bujho.records.values.fold(
    0,
    (sum, record) => sum + record.gamesWon,
  );
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your statistics'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bujhoPlayed + khoj.played + quest.played + (bridges?.finishedSets ?? 0) + (letters?.roundsCompleted ?? 0)} rounds finished',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${bujhoWon + khoj.wordsFound + quest.won + (bridges?.pairsMatched ?? 0)} words solved',
            ),
            const SizedBox(height: 16),
            _Summary(
              title: 'Bujho',
              detail: '$bujhoPlayed finished, $bujhoWon won',
            ),
            _Summary(
              title: 'Khoj',
              detail:
                  '${khoj.played} puzzles finished, ${khoj.wordsFound} words found',
            ),
            _Summary(
              title: 'Word Quest',
              detail: '${quest.played} finished, ${quest.won} won',
            ),
            const SizedBox(height: 8),
            _Summary(
              title: 'Jodo: Word Bridges',
              detail:
                  '${bridges?.finishedSets ?? 0} sets finished, ${bridges?.pairsMatched ?? 0} pairs matched',
            ),
            const Text(
              'Open Statistics in each game for its own results. Counts include repeat words and finished retries. Unfinished rounds are not counted. Khoj words are counted when the puzzle is finished.',
            ),
            const SizedBox(height: 12),
            _Summary(
              title: 'Akhar Pachhaan: Learn Letters',
              detail:
                  '${letters?.roundsCompleted ?? 0} rounds finished, ${letters?.firstTryCorrect ?? 0} first-try answers. Letters are counted separately from words.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Saved only on this device or browser. Earlier results are kept. Each game starts counting from the update that added its statistics.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(detail),
        ],
      ),
    ),
  );
}
