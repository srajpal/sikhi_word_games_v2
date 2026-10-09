import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_release_content.dart' as builder;
import '../../tool/content/approved_release.dart';
import 'approved_release_fixture.dart';

void main() {
  late Directory temporary;
  late Directory app;
  late Directory source;
  setUp(() {
    temporary = Directory.systemTemp.createTempSync('approved-release-build-');
    app = Directory('${temporary.path}/app')..createSync();
    source = Directory('${temporary.path}/source');
    writeFixture(source, approvedFixture());
  });
  tearDown(() => temporary.deleteSync(recursive: true));

  test(
    'imports the full snapshot and copies only exact masters and notices',
    () {
      final expected = ApprovedRelease.load(source);
      final runtime = Directory('${app.path}/$runtimeContentDirectory');
      writeFixture(runtime, {
        'english_v2.json': [1],
        'old-bank.json': [2],
      });

      builder.buildRelease(
        appDirectory: app,
        importDirectory: source,
        write: true,
      );

      expect(
        fileDifferences(
          Directory('${app.path}/$approvedSourceDirectory'),
          expected.files,
        ),
        isEmpty,
      );
      expect(fileDifferences(runtime, expected.runtimeFiles), isEmpty);
      expect(readDirectoryFiles(runtime), hasLength(7));
      expect(fileDifferences(source, expected.files), isEmpty);
      expect(
        () => builder.buildRelease(appDirectory: app, check: true),
        returnsNormally,
      );
    },
  );

  test(
    'rejects a corrupt import before replacing either existing destination',
    () {
      builder.buildRelease(
        appDirectory: app,
        importDirectory: source,
        write: true,
      );
      final authoring = Directory('${app.path}/$approvedSourceDirectory');
      final runtime = Directory('${app.path}/$runtimeContentDirectory');
      final beforeAuthoring = readDirectoryFiles(authoring);
      final beforeRuntime = readDirectoryFiles(runtime);
      File('${source.path}/english/words.json').writeAsStringSync('{}');

      expect(
        () => builder.buildRelease(
          appDirectory: app,
          importDirectory: source,
          write: true,
        ),
        throwsFormatException,
      );
      expect(fileDifferences(authoring, beforeAuthoring), isEmpty);
      expect(fileDifferences(runtime, beforeRuntime), isEmpty);
    },
  );

  test(
    'check rejects changed licenses and stale files; write restores originals',
    () {
      builder.buildRelease(
        appDirectory: app,
        importDirectory: source,
        write: true,
      );
      final runtime = Directory('${app.path}/$runtimeContentDirectory');
      File('${runtime.path}/licenses/WORDNET_LICENSE.txt')
          .writeAsStringSync('changed');
      File('${runtime.path}/old.json').writeAsStringSync('[]');
      expect(
        () => builder.buildRelease(appDirectory: app, check: true),
        throwsStateError,
      );
      builder.buildRelease(appDirectory: app, write: true);
      expect(
        fileDifferences(runtime, ApprovedRelease.load(source).runtimeFiles),
        isEmpty,
      );
    },
  );

  test(
    'managed writes reject outside paths before touching existing files',
    () {
      final original = readDirectoryFiles(source);
      expect(
        () => writeManagedFiles(source, {}, appDirectory: app),
        throwsStateError,
      );
      expect(fileDifferences(source, original), isEmpty);
    },
  );

  test('imports require explicit write and write cannot also check', () {
    expect(
      () => builder.buildRelease(appDirectory: app, importDirectory: source),
      throwsArgumentError,
    );
    expect(
      () => builder.buildRelease(appDirectory: app, write: true, check: true),
      throwsArgumentError,
    );
    expect(() => builder.main(['--unexpected']), throwsArgumentError);
  });
}
