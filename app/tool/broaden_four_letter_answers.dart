import 'dart:convert';
import 'dart:io';

/// Promotes a broader, still-fair slice of accepted guesses into answers.
/// Existing rejections and manual decisions are never changed.
void main(List<String> arguments) {
  final shouldWrite = arguments.contains('--write');
  final report = _read('../reports/content/four_letter_candidates.json');
  final file = File('assets/content/curation/four_letter_decisions.json');
  final document = _read(file.path);
  final candidates = <String, Map<String, Object?>>{};
  for (final item in report['candidates']! as List<Object?>) {
    final candidate = item! as Map<String, Object?>;
    candidates[candidate['word']! as String] = candidate;
  }
  final decisions = (document['entries']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .toList();
  final promoted = <String>[];
  for (var index = 0; index < decisions.length; index++) {
    final decision = decisions[index];
    if (decision['decision'] != 'guess_only') continue;
    final candidate = candidates[decision['word']! as String]!;
    if (!_isBroaderAnswer(candidate)) continue;
    decisions[index] = {
      ...decision,
      'decision': 'approve',
      'notes':
          'Promoted in the broader answer rotation: common, '
          'dictionary-confirmed, and family-appropriate.',
      'method': 'automatic_broadened_v1',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    promoted.add(candidate['word']! as String);
  }
  stdout.writeln('Broader answer pass proposes ${promoted.length} promotions.');
  stdout.writeln('Sample: ${promoted.take(70).join(', ')}');
  if (!shouldWrite) {
    stdout.writeln('No decisions changed. Rerun with --write to save.');
    return;
  }
  document['entries'] = decisions;
  _write(file, document);
  stdout.writeln('Saved ${promoted.length} broader answer approvals.');
}

bool _isBroaderAnswer(Map<String, Object?> candidate) {
  final size = candidate['scowlSize'] as int?;
  final frequency = (candidate['zipfFrequency'] as num?)?.toDouble() ?? 0;
  final definition = (candidate['definition']! as String).trim();
  if (size == null || size > 60 || frequency < 2.0) return false;
  return !RegExp(
    r'\b(obscene|vulgar|profan(?:e|ity)|racial slur|ethnic slur|offensive '
    r'term|derogatory|pornograph(?:y|ic)|sexual intercourse|genitals?|'
    r'penis|vagina|feces|excrement|defecat(?:e|ion)|marijuana|narcotic|'
    r'capital city|capital of|city of|town of|given name|first name|'
    r'forename|proper name)\b',
    caseSensitive: false,
  ).hasMatch(definition);
}

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

void _write(File file, Map<String, Object?> document) {
  const encoder = JsonEncoder.withIndent('  ');
  final temporary = File('${file.path}.tmp');
  temporary.writeAsStringSync('${encoder.convert(document)}\n');
  temporary.renameSync(file.path);
}
