import 'dart:convert';
import 'dart:io';

const maxAppCacheBytes = 96 * 1024 * 1024;
const maxAppCacheFiles = 1000;

const _excludedNames = {
  '.last_build_id',
  'app_cache_manifest.json',
  'app_cache_service_worker.js',
  'flutter_service_worker.js',
};

Future<void> main(List<String> arguments) async {
  final options = <String, String>{};
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (!argument.startsWith('--') || separator < 3) continue;
    options[argument.substring(2, separator)] = argument.substring(
      separator + 1,
    );
  }
  final buildPath = options['build-dir'];
  final version = options['version'];
  if (buildPath == null || version == null) {
    throw ArgumentError(
      'Usage: dart run tool/generate_web_app_cache.dart '
      '--build-dir=build/web --version=1.0.0+1',
    );
  }
  final buildDirectory = Directory(buildPath);
  final manifest = createWebAppCacheManifest(buildDirectory, version);
  final template = File(
    'web${Platform.pathSeparator}app_cache_service_worker.js',
  ).readAsStringSync();
  final worker = createWebAppCacheWorker(template, manifest);
  final output = File(
    '${buildDirectory.path}${Platform.pathSeparator}app_cache_manifest.json',
  );
  final workerOutput = File(
    '${buildDirectory.path}${Platform.pathSeparator}app_cache_service_worker.js',
  );
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  await workerOutput.writeAsString(worker);
  stdout.writeln(
    'App cache manifest: ${manifest['fileCount']} files, '
    '${manifest['totalBytes']} bytes.',
  );
}

Map<String, Object> createWebAppCacheManifest(
  Directory buildDirectory,
  String version,
) {
  if (!RegExp(r'^[0-9A-Za-z][0-9A-Za-z._+-]{0,63}$').hasMatch(version)) {
    throw FormatException('Invalid app cache version: $version');
  }
  if (!buildDirectory.existsSync()) {
    throw FileSystemException(
      'Web build directory does not exist.',
      buildDirectory.path,
    );
  }
  final root = buildDirectory.absolute.path;
  final prefix = '$root${Platform.pathSeparator}';
  final files = <({String path, int bytes, File source})>[];
  for (final entity in buildDirectory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (_excludedNames.contains(name) ||
        name.endsWith('.map') ||
        name.endsWith('.symbols')) {
      continue;
    }
    final absolute = entity.absolute.path;
    if (!absolute.startsWith(prefix)) {
      throw FileSystemException(
        'Cache file escaped the web build directory.',
        absolute,
      );
    }
    files.add((
      path: absolute.substring(prefix.length).replaceAll('\\', '/'),
      bytes: entity.lengthSync(),
      source: entity,
    ));
  }
  files.sort((one, two) => one.path.compareTo(two.path));
  final paths = files.map((file) => file.path).toList(growable: false);
  for (final required in [
    'index.html',
    'flutter_bootstrap.js',
    'main.dart.js',
    'manifest.json',
    'assets/AssetManifest.bin.json',
  ]) {
    if (!paths.contains(required)) {
      throw StateError('Web build is missing required cache file: $required');
    }
  }
  final totalBytes = files.fold<int>(0, (total, file) => total + file.bytes);
  if (files.length > maxAppCacheFiles || totalBytes > maxAppCacheBytes) {
    throw StateError(
      'Web app cache exceeds its limit: ${files.length} files, $totalBytes bytes.',
    );
  }
  return {
    'schemaVersion': 1,
    'version': version,
    'buildId': _buildFingerprint(files, version),
    'fileCount': files.length,
    'totalBytes': totalBytes,
    'files': paths,
  };
}

String createWebAppCacheWorker(String template, Map<String, Object> manifest) {
  const buildMarker = "const BUILD_ID = 'development';";
  const filesMarker = 'const APP_FILES = [];';
  if (!template.contains(buildMarker) || !template.contains(filesMarker)) {
    throw const FormatException(
      'App cache worker template markers are missing.',
    );
  }
  final buildId = manifest['buildId']! as String;
  final files = manifest['files']! as List<String>;
  return template
      .replaceFirst(buildMarker, 'const BUILD_ID = ${jsonEncode(buildId)};')
      .replaceFirst(filesMarker, 'const APP_FILES = ${jsonEncode(files)};');
}

String _buildFingerprint(
  List<({String path, int bytes, File source})> files,
  String version,
) {
  var hash = 0x6c62272e07bb0142;
  const prime = 0x100000001b3;
  const mask = 0x7fffffffffffffff;
  void addBytes(List<int> bytes) {
    for (final byte in bytes) {
      hash = ((hash ^ byte) * prime) & mask;
    }
  }

  addBytes(utf8.encode(version));
  for (final file in files) {
    addBytes(utf8.encode(file.path));
    addBytes(file.source.readAsBytesSync());
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
