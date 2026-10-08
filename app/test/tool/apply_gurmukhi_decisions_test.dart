import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/apply_gurmukhi_decisions.dart';
import '../../tool/review_punjabi_content.dart'
    show editorialSource, sourceCommit;

void main() {
  test(
    'applies current decisions and skips retired blanket approvals',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'gurmukhi-decisions',
      );
      addTearDown(() => directory.delete(recursive: true));
      final report = File('${directory.path}/report.json');
      final decisions = File('${directory.path}/decisions.json');
      final supplements = File('${directory.path}/supplements.json');
      final overrides = File('${directory.path}/overrides.json');
      _write(report, {
        'source': {'commit': sourceCommit},
        'candidates': [
          _candidate('1', 'ਬਾਗ', 'BAAG', 'An orchard'),
          _candidate('2', 'ਘਰ', 'GHAR', 'A house'),
          _candidate('3', 'ਹਵਾ', 'ZZZ', 'Air'),
          _candidate('4', 'ਪਾਣੀ', 'PANI', 'Water'),
          _candidate('5', 'ਗਲਤ', 'BAD', 'Invalid'),
        ],
      });
      _write(decisions, {
        'entries': [
          _decision(
            '1',
            'approve',
            definition: 'A place where fruit trees grow',
          ),
          _decision('2', 'guess_only'),
          _decision('3', 'reject'),
          {
            ..._decision('4', 'approve'),
            'reviewMethod': null,
            'notes': 'Bulk approval requested by project owner.',
          },
          _decision('5', 'reject'),
        ],
      });
      _write(supplements, {
        'schemaVersion': 1,
        'entries': [
          _supplement('gurmukhi_mahan_kosh_2', 'GHAR', 'ਘਰ'),
          _supplement('gurmukhi_mahan_kosh_3', 'HAWA', 'ਹਵਾ'),
        ],
      });
      _write(overrides, {
        'schemaVersion': 1,
        'entries': [
          {
            'id': 'gurmukhi_mahan_kosh_2',
            'solutionEligible': true,
            'note': 'older decision',
          },
        ],
      });

      await applyGurmukhiDecisions(
        reportFile: report,
        decisionsFile: decisions,
        supplementalFile: supplements,
        overridesFile: overrides,
      );

      final savedSupplements = _byId(supplements);
      expect(
        savedSupplements['gurmukhi_mahan_kosh_1']!['reviewStatus'],
        'machineChecked',
      );
      expect(
        savedSupplements['gurmukhi_mahan_kosh_2']!['solutionEligible'],
        isFalse,
      );
      expect(
        savedSupplements['gurmukhi_mahan_kosh_3']!['acceptedGuess'],
        isFalse,
      );
      expect(savedSupplements, isNot(contains('gurmukhi_mahan_kosh_4')));
      final savedOverrides = _byId(overrides);
      expect(
        savedOverrides['gurmukhi_mahan_kosh_2']!['solutionEligible'],
        isFalse,
      );
      expect(
        savedOverrides['gurmukhi_mahan_kosh_3']!['acceptedGuess'],
        isFalse,
      );
      expect(savedOverrides, isNot(contains('gurmukhi_mahan_kosh_5')));
      expect(
        savedOverrides['gurmukhi_mahan_kosh_1']!['source'],
        editorialSource,
      );
    },
  );

  test('rejects a report from any unpinned source before writing', () async {
    final directory = await Directory.systemTemp.createTemp('gurmukhi-source');
    addTearDown(() => directory.delete(recursive: true));
    final files = [
      for (final name in ['r', 'd', 's', 'o'])
        File('${directory.path}/$name.json'),
    ];
    _write(files[0], {
      'source': {'commit': 'moving-target'},
      'candidates': [],
    });
    for (final file in files.skip(1)) {
      _write(file, {'entries': []});
    }
    expect(
      () => applyGurmukhiDecisions(
        reportFile: files[0],
        decisionsFile: files[1],
        supplementalFile: files[2],
        overridesFile: files[3],
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate manual decisions before writing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'gurmukhi-duplicate',
    );
    addTearDown(() => directory.delete(recursive: true));
    final files = [
      for (final name in ['r', 'd', 's', 'o'])
        File('${directory.path}/$name.json'),
    ];
    _write(files[0], {
      'source': {'commit': sourceCommit},
      'candidates': [_candidate('1', 'ਬਾਗ', 'BAAG', 'An orchard')],
    });
    _write(files[1], {
      'entries': [_decision('1', 'guess_only'), _decision('1', 'approve')],
    });
    _write(files[2], {'entries': []});
    _write(files[3], {'entries': []});

    expect(
      () => applyGurmukhiDecisions(
        reportFile: files[0],
        decisionsFile: files[1],
        supplementalFile: files[2],
        overridesFile: files[3],
      ),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _candidate(
  String id,
  String gurmukhi,
  String latin,
  String definition,
) => {
  'id': id,
  'gurmukhi': gurmukhi,
  'romanized': latin,
  'length': 2,
  'definition': definition,
  'source': {'volume': 1, 'page': 2},
};

Map<String, Object?> _decision(
  String id,
  String decision, {
  String? definition,
}) => {
  'id': 'gurmukhi_mahan_kosh_$id',
  'decision': decision,
  'definition': ?definition,
  'reviewMethod': 'manual-review-v1',
  'verificationSource': 'Pinned Mahan Kosh entry',
  'notes': 'Reviewed source and spelling.',
};

Map<String, Object?> _supplement(String id, String latin, String gurmukhi) => {
  'id': id,
  'language': 'panjabi',
  'latin': latin,
  'gurmukhi': gurmukhi,
  'definitions': {
    'en': ['Old clue'],
    'pa': <String>[],
  },
  'lengths': {'latin': latin.length, 'gurmukhi': 2},
  'acceptedGuess': true,
  'solutionEligible': true,
  'reviewStatus': 'machineChecked',
  'sources': ['old'],
};

Map<String, Map<String, dynamic>> _byId(File file) {
  final document = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final item in document['entries'] as List)
      (item as Map)['id'] as String: Map<String, dynamic>.from(item),
  };
}

void _write(File file, Map<String, Object?> value) =>
    file.writeAsStringSync(jsonEncode(value));
