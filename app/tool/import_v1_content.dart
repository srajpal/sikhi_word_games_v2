import 'dart:convert';
import 'dart:io';

import 'package:sikhi_word_games_v2/core/content/v1_vocabulary_importer.dart';

Future<void> main(List<String> arguments) async {
  final appDirectory = Directory.current;
  final workspace = appDirectory.parent;
  final source = Directory(
    '${workspace.path}${Platform.pathSeparator}sikhi_word_games-main'
    '${Platform.pathSeparator}sikhi_word_games-main'
    '${Platform.pathSeparator}assets',
  );
  final output = Directory(
    '${appDirectory.path}${Platform.pathSeparator}assets'
    '${Platform.pathSeparator}content${Platform.pathSeparator}generated',
  );
  final reports = Directory(
    '${workspace.path}${Platform.pathSeparator}reports'
    '${Platform.pathSeparator}content',
  );
  output.createSync(recursive: true);
  reports.createSync(recursive: true);

  final version = File(
    '${source.path}${Platform.pathSeparator}wordlists'
    '${Platform.pathSeparator}version.txt',
  ).readAsStringSync().trim();
  final allIssues = <ImportIssue>[];
  var totalEntries = 0;
  final countsByLanguage = <String, int>{};

  for (final spec in const [
    (name: 'four', length: 4),
    (name: 'five', length: 5),
    (name: 'six', length: 6),
  ]) {
    final words = _readLines(
      File(
        '${source.path}${Platform.pathSeparator}wordlists${Platform.pathSeparator}${spec.name}.txt',
      ),
    );
    final definitions = _readLines(
      File(
        '${source.path}${Platform.pathSeparator}definitions${Platform.pathSeparator}${spec.name}.txt',
      ),
    );
    final result = V1VocabularyImporter.import(
      wordLines: words,
      definitionLines: definitions,
      expectedLatinLength: spec.length,
      sourceVersion: version,
    );
    totalEntries += result.entries.length;
    allIssues.addAll(result.issues);
    for (final entry in result.entries) {
      countsByLanguage.update(
        entry.language.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    const encoder = JsonEncoder.withIndent('  ');
    File(
      '${output.path}${Platform.pathSeparator}vocabulary_${spec.length}.json',
    ).writeAsStringSync(
      encoder.convert(result.entries.map((entry) => entry.toJson()).toList()),
    );
  }

  final issueCounts = <String, int>{};
  for (final issue in allIssues) {
    issueCounts.update(
      issue.type.name,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  final report = StringBuffer()
    ..writeln('# V1 Content Import Report')
    ..writeln()
    ..writeln('- Source version: `$version`')
    ..writeln('- Imported entries: $totalEntries')
    ..writeln('- English entries: ${countsByLanguage['english'] ?? 0}')
    ..writeln('- Panjabi entries: ${countsByLanguage['panjabi'] ?? 0}')
    ..writeln('- Curated solutions: 0 (review required)')
    ..writeln()
    ..writeln('## Issues');
  for (final type in ImportIssueType.values) {
    report.writeln('- ${type.name}: ${issueCounts[type.name] ?? 0}');
  }
  report
    ..writeln()
    ..writeln('## Review queue')
    ..writeln()
    ..writeln('| Type | Entry | Source line | Detail |')
    ..writeln('| --- | --- | ---: | --- |');
  for (final issue in allIssues) {
    final safeMessage = issue.message
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
    report.writeln(
      '| ${issue.type.name} | ${issue.entryId ?? ''} | ${issue.lineNumber ?? ''} | $safeMessage |',
    );
  }
  File('${reports.path}${Platform.pathSeparator}v1_import_report.md')
      .writeAsStringSync(report.toString());

  stdout.writeln('Imported $totalEntries entries.');
  stdout.writeln('Recorded ${allIssues.length} review issues.');
  stdout.writeln('Generated assets: ${output.path}');
  stdout.writeln('Review report: ${reports.path}');
}

List<String> _readLines(File file) => file
    .readAsLinesSync()
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);
