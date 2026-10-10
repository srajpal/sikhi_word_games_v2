import 'dart:io';

import 'package:sikhi_word_games_v2/core/content/answer_eligibility.dart';

import 'content/approved_release.dart';

void main(List<String> arguments) {
  if (arguments.isNotEmpty &&
      (arguments.length != 2 || arguments.first != '--directory')) {
    throw ArgumentError(
      'Usage: audit_release_content.dart [--directory <runtime-directory>]',
    );
  }
  auditRelease(
    ApprovedRelease.load(Directory(approvedSourceDirectory)),
    directory: arguments.isEmpty ? null : Directory(arguments.last),
  );
}

void auditRelease(ApprovedRelease source, {Directory? directory}) {
  final differences = fileDifferences(
    directory ?? Directory(runtimeContentDirectory),
    source.runtimeFiles,
  );
  if (differences.isNotEmpty) {
    throw StateError(
      'Runtime content must exactly match approved masters and notices: '
      '${differences.join(', ')}',
    );
  }
  for (final dataset in approvedDatasets) {
    final master = decodeObject(
      source.runtimeFiles['$dataset/words.json']!,
      dataset,
    );
    for (final record
        in (master['words'] as List).cast<Map<String, Object?>>()) {
      checkDefinitionText(
        record['definition'] as String,
        identity: '$dataset/${record['word']}',
      );
    }
  }
  for (final dataset in source.counts.entries) {
    stdout.writeln('${dataset.key}: ${dataset.value} tiles');
  }
  stdout.writeln(
    'Release integrity passed: ${source.totalWords} records across three '
    'separate datasets, unchanged definitions, verified tile units, attribution '
    'and licenses. Definition regression guard passed; no records edited or removed.',
  );
}

/// Narrow regression guard, not a claim of complete editorial verification.
const crudeDefinitionTerms = {
  'fuck',
  'fucked',
  'fucking',
  'motherfucker',
  'shit',
  'bullshit',
  'bitch',
  'cunt',
  'asshole',
  'dickhead',
  'your mom',
  'your mum',
};

void checkDefinitionText(String definition, {required String identity}) {
  final text = definition.replaceAll(RegExp(r'\s+'), ' ');
  for (final term in crudeDefinitionTerms) {
    if (AnswerEligibility.containsWholeWord(text, term)) {
      throw FormatException(
        'Crude/vandalized definition regression: $identity (matched "$term").',
      );
    }
  }
}
