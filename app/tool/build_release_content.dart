import 'dart:io';

import 'content/approved_release.dart';

/// Copies the owner's approved masters and notices without changing any bytes.
void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  String? importFrom;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--write' || argument == '--check') continue;
    if (argument == '--import-from' && index + 1 < arguments.length) {
      if (importFrom != null) throw ArgumentError('Repeated --import-from.');
      importFrom = arguments[++index];
      continue;
    }
    throw ArgumentError('Unknown or incomplete argument: $argument');
  }
  if (write && check || importFrom != null && !write) {
    throw ArgumentError(
      'Usage: build_release_content.dart [--write | --check] '
      '[--import-from <approved-release-directory> --write]',
    );
  }
  buildRelease(
    appDirectory: Directory.current,
    write: write,
    check: check,
    importDirectory: importFrom == null ? null : Directory(importFrom),
  );
}

void buildRelease({
  required Directory appDirectory,
  bool write = false,
  bool check = false,
  Directory? importDirectory,
}) {
  if (write && check || importDirectory != null && !write) {
    throw ArgumentError(
      'Import requires --write; --write and --check are exclusive.',
    );
  }
  final authoring = Directory('${appDirectory.path}/$approvedSourceDirectory');
  final snapshot = ApprovedRelease.load(importDirectory ?? authoring);
  // Validate every source file before touching either app-owned destination.
  if (importDirectory != null) {
    writeManagedFiles(authoring, snapshot.files, appDirectory: appDirectory);
  }
  final destination = Directory(
    '${appDirectory.path}/$runtimeContentDirectory',
  );
  final differences = fileDifferences(destination, snapshot.runtimeFiles);
  if (write) {
    writeManagedFiles(
      destination,
      snapshot.runtimeFiles,
      appDirectory: appDirectory,
    );
  }
  stdout.writeln(
    'Approved release: ${snapshot.totalWords} records in three independent '
    'datasets; ${snapshot.runtimeFiles.length} runtime files; '
    '${differences.length} differences${write ? ' written' : ''}.',
  );
  if (check && differences.isNotEmpty) {
    throw StateError(
      'Runtime content differs from the approved snapshot: '
      '${differences.join(', ')}. Run build_release_content.dart --write.',
    );
  }
}
