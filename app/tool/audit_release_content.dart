import 'dart:io';

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
  for (final dataset in source.counts.entries) {
    stdout.writeln('${dataset.key}: ${dataset.value} tiles');
  }
  stdout.writeln(
    'Release integrity passed: ${source.totalWords} records across three '
    'separate datasets, unchanged definitions, verified tile units, attribution '
    'and licenses. No editorial filtering applied.',
  );
}
