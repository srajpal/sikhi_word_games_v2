import 'package:flutter/material.dart';

import 'game_statistics_repository.dart';

Future<void> showGameStatistics(
  BuildContext context, {
  required String title,
  required GameStatisticsRepository repository,
  required String mode,
  required int? size,
  required String modeLabel,
  bool isQuest = false,
}) {
  final current = repository.forMode(mode, size);
  final total = repository.total;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$title statistics'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$modeLabel · ${size == null ? 'Mixed lengths' : '$size letters'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Finished: ${current.played}'),
            Text('Solved: ${current.won}'),
            if (isQuest) Text('Solved with hints: ${current.hintedWins}'),
            if (!isQuest)
              Text('Words found in finished puzzles: ${current.wordsFound}'),
            const SizedBox(height: 16),
            Text(
              'All settings: ${total.played} finished, ${total.won} solved.',
            ),
            const SizedBox(height: 12),
            Text(
              isQuest
                  ? 'Each finished attempt counts, including retries. Unfinished words do not count.'
                  : 'Only finished puzzles count. Unfinished puzzles do not count.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved on this device. Statistics start with this update.',
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
