import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/generate_web_app_cache.dart';

void main() {
  late Directory build;

  setUp(() {
    build = Directory.systemTemp.createTempSync('sikhi_app_cache_test_');
    for (final path in [
      'index.html',
      'flutter_bootstrap.js',
      'main.dart.js',
      'manifest.json',
      'assets/AssetManifest.bin.json',
      'assets/words.json',
      'canvaskit/canvaskit.wasm',
    ]) {
      final file = File(
        '${build.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(path);
    }
    File('${build.path}${Platform.pathSeparator}.last_build_id')
        .writeAsStringSync('local');
    File('${build.path}${Platform.pathSeparator}flutter_service_worker.js')
        .writeAsStringSync('deprecated');
    File('${build.path}${Platform.pathSeparator}main.dart.js.map')
        .writeAsStringSync('source map');
  });

  tearDown(() => build.deleteSync(recursive: true));

  test('creates a sorted bounded manifest of distributable build files', () {
    final manifest = createWebAppCacheManifest(build, '1.3.0+5');
    final files = (manifest['files']! as List<Object?>).cast<String>();

    expect(manifest['version'], '1.3.0+5');
    expect(manifest['buildId'], matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(manifest['fileCount'], files.length);
    expect(manifest['totalBytes'], greaterThan(0));
    expect(files, orderedEquals([...files]..sort()));
    expect(files, contains('canvaskit/canvaskit.wasm'));
    expect(files, isNot(contains('.last_build_id')));
    expect(files, isNot(contains('flutter_service_worker.js')));
    expect(files, isNot(contains('main.dart.js.map')));
  });

  test('content changes produce a new worker and cache identity', () {
    final first = createWebAppCacheManifest(build, '1.3.0+5');
    final index = File('${build.path}${Platform.pathSeparator}index.html');
    index.writeAsStringSync('INDEX.HTML');
    final second = createWebAppCacheManifest(build, '1.3.0+5');

    expect(second['buildId'], isNot(first['buildId']));
    final template = File('web/app_cache_service_worker.js').readAsStringSync();
    final worker = createWebAppCacheWorker(template, second);
    expect(worker, contains('const BUILD_ID = "${second['buildId']}";'));
    expect(worker, isNot(contains("const BUILD_ID = 'development';")));
    expect(worker, isNot(contains('const APP_FILES = [];')));
  });

  test('rejects unsafe cache versions and incomplete builds', () {
    expect(
      () => createWebAppCacheManifest(build, '../shared-cache'),
      throwsFormatException,
    );
    File('${build.path}${Platform.pathSeparator}index.html').deleteSync();
    expect(() => createWebAppCacheManifest(build, '1.3.0+5'), throwsStateError);
  });

  test('service worker cleanup and fetch handling stay app-scoped', () {
    final worker = File('web/app_cache_service_worker.js').readAsStringSync();

    expect(worker, contains('encodeURIComponent(self.registration.scope)'));
    expect(worker, contains('`sikhi-word-games-app-\${SCOPE_ID}-`'));
    expect(worker, contains('name.startsWith(CACHE_PREFIX)'));
    expect(worker, contains('url.origin !== scope.origin'));
    expect(worker, contains('!url.pathname.startsWith(scope.pathname)'));
    expect(worker, contains("request.method !== 'GET'"));
    expect(worker, contains('if (!APP_URLS.has(cacheUrl)) return'));
    expect(worker, contains('if (!IS_CONFIGURED)'));
    expect(worker, isNot(contains('skipWaiting')));
    expect(worker, isNot(contains('clients.claim')));
  });
}
