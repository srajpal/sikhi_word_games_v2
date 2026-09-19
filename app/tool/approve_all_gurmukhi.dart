import 'dart:io';

import 'review_punjabi_content.dart' as review;

/// Compatibility entry point for the retired blanket-approval command.
///
/// Punjabi content now passes source, spelling, and clue-quality review. The
/// default remains a dry run; writing still requires an explicit `--write`.
void main(List<String> args) {
  stdout.writeln(
    'Blanket Gurmukhi approval has been retired. Running the Punjabi content '
    'review pipeline instead.',
  );
  review.main(args);
}
