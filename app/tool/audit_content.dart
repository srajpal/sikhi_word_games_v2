import 'dart:io';

import 'audit_release_content.dart' as release;
import 'content/approved_release.dart';

void main() {
  final source = ApprovedRelease.load(Directory(approvedSourceDirectory));
  stdout.writeln(
    'Approved authoring snapshot: ${source.files.length} files verified '
    'against the supplied manifest, including original exports and notices.',
  );
  release.auditRelease(source);
}
