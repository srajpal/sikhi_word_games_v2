import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'mahan_kosh_text.dart';

const oewnLabel = 'Open English WordNet 2025 (CC BY 4.0)';
const editorialLabel =
    'Project editorial definition; original text for Sikhi Word Games';

Map<String, Object?> readObject(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

String fileHash(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

String textFileHash(String path) => sha256
    .convert(
      utf8.encode(File(path).readAsStringSync().replaceAll('\r\n', '\n')),
    )
    .toString();

/// Checks the entire pinned source inventory, including missing/extra files.
/// It fails before any report or curation mutation on a corrupt source cache.
Map<String, String> verifySourceLock(
  Map<String, Object?> lock, {
  Directory? root,
}) {
  root ??= Directory.current;
  if (lock['schemaVersion'] != 1) {
    throw StateError('Unknown source lock version.');
  }
  final files = (lock['files']! as Map<String, Object?>).cast<String, String>();
  for (final file in files.entries) {
    final path = '${root.path}/${file.key}';
    if (!File(path).existsSync() || fileHash(path) != file.value) {
      throw StateError(
        'Missing or changed source: ${file.key}. '
        'Run python tool/fetch_vocabulary_sources.py.',
      );
    }
  }
  final actual =
      Directory('${root.path}/.dart_tool/vocabulary_sources/oewn-2025')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map(
            (f) =>
                f.path.substring(root!.path.length + 1).replaceAll('\\', '/'),
          )
          .toSet();
  final expected = files.keys.where((p) => p.contains('/oewn-2025/')).toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw StateError('Unexpected OEWN source inventory.');
  }
  return files;
}

class SourceSense {
  const SourceSense(this.id, this.definition);
  final String id;
  final String definition;
  Map<String, Object?> toJson() => {
    'sourceSenseId': id,
    'definition': definition,
  };
}

class VocabularySources {
  VocabularySources.fromIndexes({
    required Map<String, List<SourceSense>> english,
    required Map<String, Map<String, Object?>> punjabi,
    required this.punjabiEnglish,
  }) {
    this.english.addAll(english);
    this.punjabi.addAll(punjabi);
  }

  VocabularySources.load() {
    final directory = Directory('.dart_tool/vocabulary_sources/oewn-2025');
    final files = directory.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final synsets = <String, List<String>>{};
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('.json') ||
          name.startsWith('entries-') ||
          name == 'frames.json') {
        continue;
      }
      for (final item in readObject(file.path).entries) {
        final value = item.value! as Map<String, Object?>;
        synsets[item.key] = (value['definition']! as List).cast<String>();
      }
    }
    for (final file in files.where(
      (f) => f.uri.pathSegments.last.startsWith('entries-'),
    )) {
      for (final lemma in readObject(file.path).entries) {
        // Case-folding title-cased names into ordinary words changes meaning.
        if (lemma.key != lemma.key.toLowerCase()) continue;
        final senses = english.putIfAbsent(lemma.key, () => []);
        for (final part in (lemma.value! as Map<String, Object?>).values) {
          for (final sense
              in (part! as Map<String, Object?>)['sense']! as List) {
            final id = (sense as Map<String, Object?>)['synset']! as String;
            for (final definition in synsets[id] ?? <String>[]) {
              senses.add(SourceSense(id, definition));
            }
          }
        }
      }
    }
    for (final item
        in readObject(
              '.dart_tool/vocabulary_sources/mahan-kosh-core.json',
            )['entries']!
            as List) {
      final entry = item as Map<String, Object?>;
      if (entry['excluded'] == true) continue;
      punjabi[entry['id']! as String] = entry;
    }
    punjabiEnglish = readObject(
      '.dart_tool/vocabulary_sources/mahan-kosh-en.json',
    );
  }

  final english = <String, List<SourceSense>>{};
  final punjabi = <String, Map<String, Object?>>{};
  late final Map<String, Object?> punjabiEnglish;

  List<SourceSense> englishCandidates(String word) =>
      english[word.toLowerCase()] ?? [];

  /// Exact sense membership, not “this dictionary contains this word”.
  bool matchesEnglish(String word, String definition) =>
      englishCandidates(word).any((s) => s.definition == definition);

  bool matchesPunjabi({
    required String word,
    required String definition,
    required Map<String, Object?>? decision,
    required bool editorial,
  }) {
    if (decision == null) return false;
    final id = decision['sourceId'];
    final source = punjabi[id];
    if (source == null || source['hw'] != word) return false;
    final index = decision['sourceSenseIndex'];
    final senses =
        (punjabiEnglish[id] as Map<String, Object?>?)?['definitions'] as List?;
    if (index is! int ||
        senses == null ||
        index < 0 ||
        index >= senses.length) {
      return false;
    }
    // A paraphrase can only be source-linked mechanically. Its meaning needs
    // sampling; this path never calls it an exact translation or human review.
    if (editorial) {
      return decision['verificationSource'] is String &&
          (decision['verificationSource']! as String).contains(
            'commit fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6;',
          );
    }
    return cleanMahanKoshSense(senses[index] as String) == definition;
  }
}
