import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/audit_release_content.dart';
import '../../tool/content/approved_release.dart';
import 'approved_release_fixture.dart';

void main() {
  late Directory temporary;
  late Directory source;
  setUp(() {
    temporary = Directory.systemTemp.createTempSync('approved-release-audit-');
    source = Directory('${temporary.path}/source');
  });
  tearDown(() => temporary.deleteSync(recursive: true));

  test(
    'approved rare words and original review metadata bypass editorial filters',
    () {
      writeFixture(source, approvedFixture());
      final snapshot = ApprovedRelease.load(source);
      expect(snapshot.totalWords, 3);
      expect(snapshot.counts, {
        'english': {'6': 1},
        'punjabi/romanized': {'4': 1},
        'punjabi/gurmukhi': {'3': 1},
      });
      final master = decodeObject(
        snapshot.runtimeFiles['english/words.json']!,
        'English',
      );
      expect((master['words'] as List).single['word'], 'votary');
      expect(
        (master['words'] as List).single['definition'],
        'See another entry.',
      );
      expect(
        (master['metadata'] as Map)['review_status'],
        'automatically screened candidate',
      );
    },
  );

  test(
    'manifest catches byte tampering, missing files and unexpected files',
    () {
      final files = approvedFixture();
      writeFixture(source, files);
      final notice = File('${source.path}/ATTRIBUTION.txt');
      notice.writeAsStringSync('changed');
      expect(() => ApprovedRelease.load(source), throwsFormatException);
      notice.deleteSync();
      expect(() => ApprovedRelease.load(source), throwsFormatException);
      writeFixture(source, files);
      File('${source.path}/extra.txt').writeAsStringSync('extra');
      expect(() => ApprovedRelease.load(source), throwsFormatException);
    },
  );

  test('manifest rejects path traversal even with a correct digest', () {
    final files = approvedFixture();
    final manifest = decodeObject(files['manifest.json']!, 'manifest');
    (manifest['files'] as List).first['path'] = '../outside.json';
    files['manifest.json'] = utf8.encode(jsonEncode(manifest));
    writeFixture(source, files);
    expect(() => ApprovedRelease.load(source), throwsFormatException);
  });

  test(
    'correct hashes cannot hide tile, count or text-export inconsistencies',
    () {
      for (final field in ['units', 'count', 'export', 'duplicates']) {
        final files = approvedFixture();
        final path = 'punjabi/gurmukhi/words.json';
        final master = decodeObject(files[path]!, path);
        final records = master['words'] as List;
        if (field == 'units') {
          records.first['letter_units'] = ['ਅ', 'ਨ੍ਹ', 'ੇਰ'];
        } else if (field == 'count') {
          master['length_counts'] = {'4': 1};
        } else if (field == 'duplicates') {
          records.add(records.first);
          master['word_count'] = 2;
        } else {
          files['punjabi/gurmukhi/words.txt'] = utf8.encode('something else\n');
        }
        files[path] = utf8.encode(jsonEncode(master));
        refreshManifest(files);
        writeFixture(source, files);
        expect(
          () => ApprovedRelease.load(source),
          throwsFormatException,
          reason: field,
        );
      }
    },
  );

  test(
    'packaged directory audit requires all seven unchanged runtime files',
    () {
      writeFixture(source, approvedFixture());
      final snapshot = ApprovedRelease.load(source);
      final packaged = Directory(
        '${temporary.path}/web/assets/assets/content/release',
      );
      writeFixture(packaged, snapshot.runtimeFiles);
      expect(
        () => auditRelease(snapshot, directory: packaged),
        returnsNormally,
      );
      File('${packaged.path}/licenses/CC_BY_SA_4_0_LICENSE.txt').deleteSync();
      expect(
        () => auditRelease(snapshot, directory: packaged),
        throwsStateError,
      );
    },
  );

  test('checked-in approved release and runtime have exact supplied counts and bytes', () {
    final snapshot = ApprovedRelease.load(Directory(approvedSourceDirectory));
    expect(snapshot.counts, {
      'english': {'4': 2263, '5': 3972, '6': 6292},
      'punjabi/romanized': {'4': 658, '5': 1354, '6': 979},
      'punjabi/gurmukhi': {
        '2': 1515,
        '3': 1865,
        '4': 787,
        '5': 220,
        '6': 33,
        '7': 7,
        '8': 1,
      },
    });
    expect(snapshot.files, hasLength(16));
    expect(snapshot.runtimeFiles, hasLength(7));
    expect(
      fileDifferences(
        Directory(runtimeContentDirectory),
        snapshot.runtimeFiles,
      ),
      isEmpty,
    );
  });
}
