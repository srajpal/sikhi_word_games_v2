import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';

const approvedSourceDirectory = 'content/approved_release';
const runtimeContentDirectory = 'assets/content/release';
const approvedDatasets = ['english', 'punjabi/romanized', 'punjabi/gurmukhi'];
const approvedNoticePaths = [
  'ATTRIBUTION.txt',
  'licenses/WORDNET_LICENSE.txt',
  'licenses/CC_BY_SA_4_0_LICENSE.txt',
  'licenses/FILTER_CC_BY_4_0_LICENSE.txt',
];

/// Technical validation of an externally approved release. Definitions, source
/// metadata and review notes remain data, never editorial instructions.
class ApprovedRelease {
  ApprovedRelease._(this.files, this.counts);

  final Map<String, List<int>> files;
  final Map<String, Map<String, int>> counts;

  int get totalWords => counts.values
      .expand((lengths) => lengths.values)
      .fold(0, (total, count) => total + count);

  Map<String, List<int>> get runtimeFiles => {
    for (final dataset in approvedDatasets)
      '$dataset/words.json': files['$dataset/words.json']!,
    for (final path in approvedNoticePaths) path: files[path]!,
  };

  static ApprovedRelease load(Directory directory) {
    final files = readDirectoryFiles(directory);
    final manifestBytes = files['manifest.json'];
    if (manifestBytes == null) {
      throw const FormatException('Approved release has no manifest.json.');
    }
    final manifest = decodeObject(manifestBytes, 'manifest.json');
    if (manifest['format_version'] != 2) {
      throw const FormatException('Unsupported approved manifest format.');
    }
    final declared = manifest['files'];
    if (declared is! List) {
      throw const FormatException('Manifest files must be a list.');
    }
    final expectedPaths = <String>{'manifest.json'};
    for (final item in declared) {
      if (item is! Map<String, Object?> || item['path'] is! String) {
        throw const FormatException('Malformed manifest file record.');
      }
      final path = checkedRelativePath(item['path']! as String);
      if (!expectedPaths.add(path)) {
        throw FormatException('Duplicate manifest path: $path');
      }
      final bytes = files[path];
      if (bytes == null ||
          item['bytes'] != bytes.length ||
          item['sha256'] != sha256.convert(bytes).toString()) {
        throw FormatException('Manifest size/hash mismatch: $path');
      }
    }
    if (files.keys.toSet().difference(expectedPaths).isNotEmpty) {
      throw const FormatException('Unlisted files in approved release.');
    }
    for (final notice in approvedNoticePaths) {
      if (files[notice]?.isNotEmpty != true) {
        throw FormatException('Missing approved attribution/license: $notice');
      }
    }
    final masterFiles = manifest['master_files'];
    final manifestCounts = manifest['counts'];
    final totals = manifest['totals_by_dataset'];
    if (masterFiles is! Map ||
        manifestCounts is! Map ||
        totals is! Map ||
        masterFiles.length != approvedDatasets.length ||
        manifestCounts.length != approvedDatasets.length ||
        totals.length != approvedDatasets.length) {
      throw const FormatException('Manifest must describe three datasets.');
    }
    final counts = <String, Map<String, int>>{};
    for (final dataset in approvedDatasets) {
      final path = '$dataset/words.json';
      if (masterFiles[dataset] != path || files[path] == null) {
        throw FormatException('Incorrect or missing master for $dataset.');
      }
      final master = decodeObject(files[path]!, path);
      final actual = validateMaster(master, dataset);
      if (!sameCounts(actual, manifestCounts[dataset]) ||
          totals[dataset] != master['word_count']) {
        throw FormatException('Manifest counts disagree with $dataset.');
      }
      final words = (master['words']! as List).cast<Map<String, Object?>>();
      for (final (name, expectedLines) in [
        ('words.txt', [for (final word in words) word['word']! as String]),
        (
          'definitions.txt',
          [for (final word in words) '${word['word']}\t${word['definition']}'],
        ),
      ]) {
        final exportPath = '$dataset/$name';
        final bytes = files[exportPath];
        final lines = bytes == null
            ? <String>[]
            : const LineSplitter().convert(utf8.decode(bytes));
        if (!sameStrings(lines, expectedLines)) {
          throw FormatException(
            'Text export disagrees with master: $exportPath',
          );
        }
      }
      counts[dataset] = actual;
    }
    return ApprovedRelease._(files, counts);
  }
}

Map<String, int> validateMaster(Map<String, Object?> master, String dataset) {
  final words = master['words'];
  final metadata = master['metadata'];
  if (words is! List ||
      words.isEmpty ||
      metadata is! Map ||
      metadata['dictionary'] is! String ||
      metadata['license'] is! String ||
      master['word_count'] != words.length) {
    throw FormatException('Malformed approved master: $dataset');
  }
  final range = master['tile_count_range'];
  if (range is! List ||
      range.length != 2 ||
      range.any((value) => value is! int) ||
      (range.first as int) < 1 ||
      (range.first as int) > (range.last as int)) {
    throw FormatException('Invalid tile range: $dataset');
  }
  final counts = <String, int>{};
  String? previous;
  for (final record in words) {
    if (record is! Map<String, Object?> ||
        record['word'] is! String ||
        record['definition'] is! String ||
        (record['definition']! as String).trim().isEmpty ||
        record['part_of_speech'] is! String) {
      throw FormatException('Malformed word record in $dataset.');
    }
    final word = record['word']! as String;
    final units = record['letter_units'];
    if (word.isEmpty || previous != null && previous.compareTo(word) >= 0) {
      throw FormatException('Duplicate or unsorted word in $dataset: $word');
    }
    previous = word;
    if (units is! List ||
        units.any((value) => value is! String || value.isEmpty)) {
      throw FormatException('Invalid letter units for $dataset/$word');
    }
    final letters = units.cast<String>();
    if (!sameStrings(letters, wordUnits(word)) ||
        letters.join() != word ||
        record['tile_count'] != letters.length ||
        letters.length < (range.first as int) ||
        letters.length > (range.last as int)) {
      throw FormatException('Tile units/count mismatch for $dataset/$word');
    }
    counts.update('${letters.length}', (count) => count + 1, ifAbsent: () => 1);
  }
  if (!sameCounts(counts, master['length_counts'])) {
    throw FormatException('Length counts disagree with $dataset records.');
  }
  return counts;
}

bool sameCounts(Map<String, int> expected, Object? actual) =>
    actual is Map &&
    actual.length == expected.length &&
    expected.entries.every((entry) => actual[entry.key] == entry.value);

bool sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

Map<String, Object?> decodeObject(List<int> bytes, String path) {
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Expected JSON object in $path');
  }
  return decoded;
}

String checkedRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains('\\') ||
      path.contains(':') ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw FormatException('Unsafe approved-release path: $path');
  }
  return path;
}

Map<String, List<int>> readDirectoryFiles(Directory directory) {
  if (!directory.existsSync()) {
    throw FileSystemException(
      'Approved release directory does not exist',
      directory.path,
    );
  }
  final root = normalizedPath(directory.absolute.path);
  final files = <String, List<int>>{};
  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is Link) {
      throw FormatException('Linked content is not supported: ${entity.path}');
    }
    if (entity is! File) continue;
    final path = entity.absolute.path
        .replaceAll('\\', '/')
        .substring(root.length + 1);
    files[checkedRelativePath(path)] = entity.readAsBytesSync();
  }
  return files;
}

List<String> fileDifferences(
  Directory directory,
  Map<String, List<int>> expected,
) {
  final actual = directory.existsSync()
      ? readDirectoryFiles(directory)
      : <String, List<int>>{};
  final paths = {...actual.keys, ...expected.keys}.toList()..sort();
  return [
    for (final path in paths)
      if (actual[path] == null ||
          expected[path] == null ||
          sha256.convert(actual[path]!) != sha256.convert(expected[path]!))
        path,
  ];
}

/// Replace only app-owned content after validating the complete input snapshot.
void writeManagedFiles(
  Directory directory,
  Map<String, List<int>> files, {
  Directory? appDirectory,
}) {
  for (final path in files.keys) {
    checkedRelativePath(path);
  }
  final app = appDirectory ?? Directory.current;
  final root = normalizedPath(app.resolveSymbolicLinksSync());
  final destination = normalizedPath(directory.absolute.path);
  final allowed = [
    normalizedPath(
      Directory('${app.path}/$approvedSourceDirectory').absolute.path,
    ),
    normalizedPath(
      Directory('${app.path}/$runtimeContentDirectory').absolute.path,
    ),
  ];
  if (!destination.startsWith('$root/') || !allowed.contains(destination)) {
    throw StateError(
      'Refusing to replace a directory outside managed app content.',
    );
  }
  var ancestor = directory.absolute;
  while (!ancestor.existsSync()) {
    ancestor = ancestor.parent;
  }
  if (normalizedPath(ancestor.resolveSymbolicLinksSync()) !=
      normalizedPath(ancestor.path)) {
    throw StateError('Managed content destination cannot traverse a link.');
  }
  if (directory.existsSync()) {
    readDirectoryFiles(
      directory,
    ); // Reject nested links before recursive removal.
    directory.deleteSync(recursive: true);
  }
  for (final entry in files.entries) {
    final target = File('${directory.path}/${checkedRelativePath(entry.key)}');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(entry.value, flush: true);
  }
}

String normalizedPath(String path) {
  final normalized = path
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'/+$'), '');
  return Platform.isWindows ? normalized.toLowerCase() : normalized;
}
