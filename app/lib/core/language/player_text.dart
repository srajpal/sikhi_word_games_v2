/// Shared player-facing count labels, including zero and singular results.
String countLabel(int count, String singular, {String? plural}) =>
    '$count ${count == 1 ? singular : plural ?? '${singular}s'}';

String wordsSolvedLabel(int count) => '${countLabel(count, 'word')} solved';
