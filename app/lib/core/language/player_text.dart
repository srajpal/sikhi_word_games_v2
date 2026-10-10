/// Shared player-facing count labels, including zero and singular results.
String wordsSolvedLabel(int count) =>
    '$count ${count == 1 ? 'word' : 'words'} solved';
