import 'dart:io';

import 'audit_release_content.dart' as audit;
import 'build_punjabi_dictionary_v2.dart' as punjabi;
import 'build_release_content.dart' as release;

/// One reproducible offline command; no historical imports or blanket approvals.
void main(List<String> arguments) {
  if (arguments.any((a) => !['--write', '--check'].contains(a)) ||
      arguments.contains('--write') && arguments.contains('--check')) {
    throw ArgumentError('Usage: dictionary_v2.dart [--write | --check]');
  }
  final english = Process.runSync(Platform.isWindows ? 'python' : 'python3', [
    'tool/build_english_dictionary_v2.py',
    ...arguments,
  ]);
  stdout.write(english.stdout);
  if (english.exitCode != 0) {
    stderr.write(english.stderr);
    throw StateError('English dictionary v2 build failed.');
  }
  punjabi.main(arguments);
  release.main(arguments);
  if (arguments.contains('--write') || arguments.contains('--check')) {
    audit.main();
  }
}
