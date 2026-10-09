import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';

import '../../tool/content/approved_release.dart';

Map<String, List<int>> approvedFixture() {
  final files = <String, List<int>>{};
  final counts = <String, Map<String, int>>{};
  final words = {
    'english': 'votary',
    'punjabi/romanized': 'abbā',
    'punjabi/gurmukhi': 'ਅਨ੍ਹੇਰ',
  };
  for (final dataset in approvedDatasets) {
    final word = words[dataset]!;
    final units = wordUnits(word);
    final count = units.length;
    counts[dataset] = {'$count': 1};
    files['$dataset/words.json'] = utf8.encode(
      jsonEncode({
        'metadata': {
          'dictionary': 'Approved fixture',
          'license': 'Original license',
          'review_status': 'automatically screened candidate',
        },
        'word_count': 1,
        'length_counts': counts[dataset],
        'tile_count_range': [count, count],
        'words': [
          {
            'word': word,
            'part_of_speech': 'noun',
            'definition': 'See another entry.',
            'letter_units': units,
            'tile_count': count,
            if (dataset != 'english')
              'source_url': 'https://example.test/$word',
          },
        ],
      }),
    );
    files['$dataset/words.txt'] = utf8.encode('$word\n');
    files['$dataset/definitions.txt'] = utf8.encode(
      '$word\tSee another entry.\n',
    );
  }
  for (final path in approvedNoticePaths) {
    files[path] = utf8.encode('Original $path\r\n');
  }
  files['README.txt'] = utf8.encode('Preserved source review disclaimer.\n');
  files['review_notes.json'] = utf8.encode('{"source_review":"machine"}\n');
  refreshManifest(files, counts: counts);
  return files;
}

void refreshManifest(
  Map<String, List<int>> files, {
  Map<String, Map<String, int>>? counts,
}) {
  final previous = files['manifest.json'];
  final manifest = previous == null
      ? <String, Object?>{
          'format_version': 2,
          'master_files': {
            for (final dataset in approvedDatasets)
              dataset: '$dataset/words.json',
          },
          'counts': counts,
          'totals_by_dataset': {
            for (final dataset in approvedDatasets) dataset: 1,
          },
        }
      : decodeObject(previous, 'manifest');
  manifest['files'] = [
    for (final entry in files.entries)
      if (entry.key != 'manifest.json')
        {
          'path': entry.key,
          'bytes': entry.value.length,
          'sha256': sha256.convert(entry.value).toString(),
        },
  ];
  files['manifest.json'] = utf8.encode(jsonEncode(manifest));
}

void writeFixture(Directory directory, Map<String, List<int>> files) {
  for (final entry in files.entries) {
    final target = File('${directory.path}/${entry.key}');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(entry.value);
  }
}
