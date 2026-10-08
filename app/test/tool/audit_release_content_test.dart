import 'package:flutter_test/flutter_test.dart';

import '../../tool/audit_release_content.dart';

void main() {
  test('pool evidence separates records from unique playable spellings', () {
    final raw = <String, int>{};
    final unique = <String, Set<String>>{};

    for (var index = 0; index < 2; index++) {
      addPlayableSpelling(
        raw,
        unique,
        mode: 'mixed',
        graphemeLength: 4,
        spelling: 'ROTI',
      );
    }

    expect(raw['mixed:4'], 2);
    expect(unique['mixed:4'], {'ROTI'});
  });
}
