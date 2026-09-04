import 'dart:convert';
import 'dart:io';

void main() {
  final appDirectory = Directory.current;
  final generated = Directory(
    '${appDirectory.path}${Platform.pathSeparator}assets'
    '${Platform.pathSeparator}content${Platform.pathSeparator}generated',
  );
  final reportDirectory = Directory(
    '${appDirectory.parent.path}${Platform.pathSeparator}reports'
    '${Platform.pathSeparator}content',
  )..createSync(recursive: true);

  final entries = <Map<String, Object?>>[];
  for (final length in const [4, 5, 6]) {
    final decoded = jsonDecode(
      File('${generated.path}${Platform.pathSeparator}vocabulary_$length.json')
          .readAsStringSync(),
    ) as List<Object?>;
    entries.addAll(decoded.cast<Map<String, Object?>>());
  }
  final supplementalDocument = jsonDecode(
    File(
      '${appDirectory.path}${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}content${Platform.pathSeparator}curation'
      '${Platform.pathSeparator}supplemental_entries.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  entries.addAll(
    (supplementalDocument['entries']! as List<Object?>)
        .cast<Map<String, Object?>>(),
  );
  final overridesDocument = jsonDecode(
    File(
      '${appDirectory.path}${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}content${Platform.pathSeparator}curation'
      '${Platform.pathSeparator}editorial_overrides.json',
    ).readAsStringSync(),
  ) as Map<String, Object?>;
  final entriesById = {
    for (final entry in entries) entry['id']! as String: entry,
  };
  for (final item in overridesDocument['entries']! as List<Object?>) {
    final override = item! as Map<String, Object?>;
    final entry = entriesById[override['id']];
    if (entry == null) {
      throw FormatException('Unknown override ID: ${override['id']}');
    }
    final definition = override['englishDefinition'] as String?;
    if (definition != null) {
      (entry['definitions']! as Map<String, Object?>)['en'] = [definition];
    }
    if (override['gurmukhi'] is String) {
      entry['gurmukhi'] = override['gurmukhi'];
    }
  }

  final spellingGroups = <String, List<String>>{};
  for (final entry in entries) {
    final key = '${entry['language']}:${entry['latin']}';
    spellingGroups.putIfAbsent(key, () => []).add(entry['id']! as String);
  }

  final queue = <Map<String, Object?>>[];
  final counts = <String, int>{};
  void flag(Map<String, Object?> entry, String issue, String detail) {
    counts.update(issue, (value) => value + 1, ifAbsent: () => 1);
    queue.add({
      'id': entry['id'],
      'language': entry['language'],
      'latin': entry['latin'],
      'gurmukhi': entry['gurmukhi'],
      'definition':
          ((entry['definitions']! as Map<String, Object?>)['en']! as List)
              .first,
      'issue': issue,
      'detail': detail,
    });
  }

  for (final entry in entries) {
    final definition =
        ((entry['definitions']! as Map<String, Object?>)['en']! as List).first
            as String;
    final latin = entry['latin']! as String;
    final language = entry['language']! as String;
    final gurmukhi = entry['gurmukhi'] as String?;
    final duplicateIds = spellingGroups['$language:$latin']!;
    if (definition.trim().isEmpty) {
      flag(entry, 'missing_definition', 'Definition is empty.');
    } else if (definition.length > 220) {
      flag(
        entry,
        'long_definition',
        'Definition has ${definition.length} characters.',
      );
    }
    if (RegExp(
      r'^(plural|past tense|present participle|alternative spelling|see)\b',
      caseSensitive: false,
    ).hasMatch(definition.trim())) {
      flag(
        entry,
        'reference_definition',
        'Definition depends on another entry.',
      );
    }
    if (duplicateIds.length > 1) {
      flag(
        entry,
        'duplicate_spelling',
        'Same language and spelling: ${duplicateIds.join(', ')}',
      );
    }
    if (!RegExp(r'^[A-Z]+$').hasMatch(latin)) {
      flag(
        entry,
        'latin_script_anomaly',
        'Latin spelling contains other symbols.',
      );
    }
    if (language == 'panjabi') {
      if (gurmukhi == null || gurmukhi.isEmpty) {
        flag(entry, 'missing_gurmukhi', 'Panjabi entry has no Gurmukhi form.');
      } else if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(gurmukhi)) {
        flag(
          entry,
          'gujarati_in_gurmukhi',
          'Gurmukhi field contains Gujarati.',
        );
      }
    }
  }

  queue.sort((a, b) {
    final issueOrder = (a['issue']! as String).compareTo(b['issue']! as String);
    return issueOrder != 0
        ? issueOrder
        : (a['id']! as String).compareTo(b['id']! as String);
  });
  const pretty = JsonEncoder.withIndent('  ');
  File('${reportDirectory.path}${Platform.pathSeparator}dictionary_audit.json')
      .writeAsStringSync(
        pretty.convert({
          'schemaVersion': 1,
          'entryCount': entries.length,
          'issueCount': queue.length,
          'counts': counts,
          'reviewQueue': queue,
        }),
      );

  final markdown = StringBuffer()
    ..writeln('# Dictionary Audit')
    ..writeln()
    ..writeln('- Records audited: ${entries.length}')
    ..writeln('- Flags raised: ${queue.length}')
    ..writeln()
    ..writeln('## Flag counts')
    ..writeln();
  for (final issue in counts.keys.toList()..sort()) {
    markdown.writeln('- $issue: ${counts[issue]}');
  }
  markdown
    ..writeln()
    ..writeln('## Workflow')
    ..writeln()
    ..writeln(
      'Review flags in `dictionary_audit.json` and record decisions in '
      '`app/assets/content/curation/editorial_overrides.json`. Do not edit '
      'generated vocabulary assets.',
    );
  File('${reportDirectory.path}${Platform.pathSeparator}dictionary_audit.md')
      .writeAsStringSync(markdown.toString());
  stdout.writeln(
    'Audited ${entries.length} records; raised ${queue.length} flags.',
  );
}
