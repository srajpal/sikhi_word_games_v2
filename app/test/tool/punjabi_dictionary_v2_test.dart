import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_punjabi_dictionary_v2.dart' as builder;

void main() {
  late Directory original;
  late Directory fixture;

  setUp(() {
    original = Directory.current;
    fixture = Directory.systemTemp.createTempSync('punjabi-v2-test-');
    Directory.current = Directory('${fixture.path}/app')..createSync();
  });
  tearDown(() {
    Directory.current = original;
    fixture.deleteSync(recursive: true);
  });

  test('source validity alone never promotes an answer', () {
    _source([_row('ਕਿਤਾਬ', 'kitāb', 'book')]);
    builder.main(['--write']);
    final entry = _output().single;
    expect(entry['solutionEligible'], false);
    expect(entry['acceptedGuess'], true);
    expect(entry['reviewStatus'], 'machineChecked');
    expect(entry['sources'].first, contains('CC BY-SA 4.0'));
    expect(entry['sources'].first, contains('#Punjabi'));
    builder.main(['--check']);
  });

  test('unsafe and reference senses never enter the dictionary', () {
    _source([
      _row('ਕਿਤਾਬ', 'kitāb', 'book'),
      _row('ਕਤਲ', 'katal', 'murder'),
      _row('ਕਾਮ', 'kām', 'sexual intercourse'),
      _row('ਗੁਦਾ', 'gudā', 'anus'),
      _row('ਬੀਅਰ', 'bīar', 'beer'),
      _row('ਸਿਗਰਟ', 'sigaraṭ', 'cigarette'),
      _row('ਜੂਆ', 'jūā', 'game of chance, gambling'),
      _row('ਅੰਗਹੀਣ', 'aṅgahīṇ', 'limbless, crippled, disabled'),
      _row('ਲੌਂਡੇਬਾਜ਼', 'lauṇḍebāz', 'sodomite'),
      _row('ਨਸਵਾਰ', 'nasvār', 'snuff'),
      _row('ਮਖਮੂਰ', 'makhmūr', 'intoxicated, enraptured'),
      _row('ਗੱਲ', 'gall', 'inflection of ਗੱਲ', tags: ['form-of']),
      _row('ਭੇਦ', 'bhed', 'secret', tags: ['archaic']),
    ]);
    builder.main(['--write']);
    expect(_output().map((e) => e['gurmukhi']), ['ਕਿਤਾਬ']);
    final report = jsonDecode(
      File('../reports/content/punjabi_dictionary_v2.json').readAsStringSync(),
    ) as Map;
    expect(
      (report['sourceHolds'] as List).any(
        (e) => e['gurmukhi'] == 'ਲੌਂਡੇਬਾਜ਼' && e['runtimeIncluded'] == false,
      ),
      true,
    );
  });

  test('Git checkout line endings do not make identical outputs stale', () {
    _source([_row('ਕਿਤਾਬ', 'kitāb', 'book')]);
    builder.main(['--write']);
    for (final path in [
      'assets/content/curation/punjabi_v2_answers.json',
      'assets/content/generated/punjabi_v2.json',
      '../reports/content/punjabi_dictionary_v2.json',
    ]) {
      final file = File(path);
      file.writeAsStringSync(
        file
            .readAsStringSync()
            .replaceAll('\r\n', '\n')
            .replaceAll('\n', '\r\n'),
      );
    }
    expect(() => builder.main(['--check']), returnsNormally);
  });

  test('a held substance-use sense preserves an ordinary alternate sense', () {
    _source([
      _row('ਅਮਲ', 'amal', 'use of, or addiction to, narcotics'),
      _row('ਅਮਲ', 'amal', 'practice'),
      _row('ਅੰਨ੍ਹਾ', 'annhā', 'blind'),
    ]);
    builder.main(['--write']);
    final entries = _output();
    expect(entries.length, 2);
    expect(
      entries.where((e) => e['gurmukhi'] == 'ਅਮਲ').single['definitions']['en'],
      ['practice'],
    );
    expect(
      entries
          .where((e) => e['gurmukhi'] == 'ਅੰਨ੍ਹਾ')
          .single['definitions']['en'],
      ['blind'],
    );
  });

  test('an exact bounded decision enables an answer without human claims', () {
    _source(
      [_row('ਕਿਤਾਬ', 'kitāb', 'book')],
      decisions: [
        {
          'word': 'ਕਿਤਾਬ',
          'senseId': 'sense-ਕਿਤਾਬ',
          'sourceGloss': 'book',
          'definition': 'Book',
        },
      ],
    );
    builder.main(['--write']);
    final entry = _output().single;
    expect(entry['solutionEligible'], true);
    expect(entry['reviewStatus'], 'machineChecked');
    expect(entry['sources'].last, contains('human Punjabi review pending'));
    expect(entry['lengths'], {'latin': 5, 'gurmukhi': 3});
  });

  test('a changed source sense cannot silently reuse editorial approval', () {
    _source(
      [_row('ਕਿਤਾਬ', 'kitāb', 'volume')],
      decisions: [
        {
          'word': 'ਕਿਤਾਬ',
          'senseId': 'sense-ਕਿਤਾਬ',
          'sourceGloss': 'book',
          'definition': 'Book',
        },
      ],
    );
    expect(() => builder.main(['--write']), throwsStateError);
    expect(
      File('assets/content/generated/punjabi_v2.json').existsSync(),
      false,
    );
  });

  test('snapshot tampering fails before writing outputs', () {
    _source([_row('ਕਿਤਾਬ', 'kitāb', 'book')]);
    File('snapshot.gz').writeAsBytesSync([1, 2, 3]);
    expect(() => builder.main(['--write']), throwsStateError);
    expect(
      File('assets/content/generated/punjabi_v2.json').existsSync(),
      false,
    );
  });

  test('romanization preserves consonants and rejects unfamiliar notation', () {
    expect(builder.romanizeWiktionaryPunjabi('raṅg'), 'RANG');
    expect(builder.romanizeWiktionaryPunjabi('pañjābī'), 'PANJABI');
    expect(builder.romanizeWiktionaryPunjabi('ciṛī'), 'CHIRI');
    expect(builder.romanizeWiktionaryPunjabi('foo/bar'), isNull);
    expect(builder.romanizeWiktionaryPunjabi('foo bar'), isNull);
    expect(builder.romanizeWiktionaryPunjabi('fóo'), isNull);
  });
}

Map<String, Object?> _row(
  String word,
  String roman,
  String gloss, {
  List<String> tags = const [],
}) => {
  'word': word,
  'pos': 'noun',
  'romanizations': [roman],
  'senses': [
    {
      'id': 'sense-$word',
      'glosses': [gloss],
      'tags': tags,
    },
  ],
};

void _source(
  List<Map<String, Object?>> rows, {
  List<Map<String, Object?>> decisions = const [],
}) {
  final bytes = gzip.encode(utf8.encode(rows.map(jsonEncode).join('\n')));
  File('snapshot.gz').writeAsBytesSync(bytes);
  final lock = File('tool/content/punjabi_v2_source_lock.json')
    ..parent.createSync(recursive: true);
  lock.writeAsStringSync(
    jsonEncode({
      'source': {'license': 'CC BY-SA 4.0'},
      'snapshot': {
        'path': 'snapshot.gz',
        'sha256': sha256.convert(bytes).toString(),
      },
    }),
  );
  final curation = File('assets/content/curation/punjabi_v2_answers.json')
    ..parent.createSync(recursive: true);
  curation.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'entries': decisions})}\n',
  );
}

List<dynamic> _output() => jsonDecode(
  File('assets/content/generated/punjabi_v2.json').readAsStringSync(),
) as List<dynamic>;
