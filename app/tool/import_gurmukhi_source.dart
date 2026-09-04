import 'dart:convert';
import 'dart:io';


/// Builds a reviewable candidate queue from a native Gurmukhi dictionary.
///
/// This deliberately does not approve candidates. It separates source
/// ingestion, grapheme counting, and ranking from editorial decisions so a
/// large dictionary cannot silently become a playable answer pool.
Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final core = _readJson(options.corePath) as Map<String, Object?>;
  final english = _readJson(options.englishPath) as Map<String, Object?>;
  final coreEntries = (core['entries']! as List<Object?>)
      .cast<Map<String, Object?>>();

  final bySpelling = <String, _Candidate>{};
  var skippedExcluded = 0;
  var skippedShape = 0;
  var skippedMissingDefinition = 0;
  var skippedLength = 0;
  for (final item in coreEntries) {
    if (item['excluded'] == true) {
      skippedExcluded++;
      continue;
    }
    final id = item['id'] as String?;
    final headword = _normalizeHeadword(item['hw'] as String?);
    if (id == null || headword == null || !_isGurmukhiWord(headword)) {
      skippedShape++;
      continue;
    }
    final length = _gurmukhiVisibleLength(headword);
    if (length != 5 && length != 6) {
      skippedLength++;
      continue;
    }
    final englishEntry = english[id];
    final definitions = englishEntry is Map<String, Object?>
        ? (englishEntry['definitions'] as List<Object?>?)
        : null;
    final definition = definitions == null || definitions.isEmpty
        ? null
        : (definitions.first as String?)?.trim();
    if (definition == null || definition.isEmpty) {
      skippedMissingDefinition++;
      continue;
    }

    final candidate = _Candidate(
      id: id,
      word: headword,
      length: length,
      definition: _cleanDefinition(definition),
      latin: _latinFromTransliteration(item['tr'] as String?),
      volume: (item['vol'] as num?)?.toInt(),
      page: (item['page'] as num?)?.toInt(),
    );
    final key = _key(headword);
    final previous = bySpelling[key];
    if (previous == null || candidate.score > previous.score) {
      bySpelling[key] = candidate;
    }
  }

  final candidates = bySpelling.values.toList()
    ..sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.word.compareTo(b.word);
    });

  final reportDirectory = Directory(
    '${Directory.current.parent.path}${Platform.pathSeparator}reports'
    '${Platform.pathSeparator}content',
  )..createSync(recursive: true);
  final output = <String, Object?>{
    'schemaVersion': 1,
    'source': {
      'name': 'Mahan Kosh multilingual dataset',
      'repository': 'https://github.com/redroyals/mahan-kosh-multilingual',
      'commit': options.commit,
      'license': 'CC BY 4.0',
      'attribution':
          'Mahan Kosh — Bhai Kahan Singh Nabha (1930); English after '
          'Punjabi University Patiala; packaged by Sikhi.io.',
    },
    'policy': {
      'lengthDefinition': 'Unicode extended grapheme clusters',
      'targetLengths': [5, 6],
      'approval': 'Candidates require editorial review; ranking is not approval.',
    },
    'sourceCounts': {
      'coreEntries': coreEntries.length,
      'skippedExcluded': skippedExcluded,
      'skippedShape': skippedShape,
      'skippedLength': skippedLength,
      'skippedMissingDefinition': skippedMissingDefinition,
    },
    'candidateCount': candidates.length,
    'countsByLength': {
      '5': candidates.where((c) => c.length == 5).length,
      '6': candidates.where((c) => c.length == 6).length,
    },
    'candidates': candidates.map((c) => c.toJson()).toList(),
  };
  const encoder = JsonEncoder.withIndent('  ');
  File('${reportDirectory.path}${Platform.pathSeparator}gurmukhi_candidates.json')
      .writeAsStringSync(encoder.convert(output));

  final markdown = StringBuffer()
    ..writeln('# Native Gurmukhi 5/6-Grapheme Candidates')
    ..writeln()
    ..writeln('Source: Mahan Kosh multilingual dataset (`${options.commit}`).')
    ..writeln('License: CC BY 4.0; see `docs/gurmukhi_sources.md`.')
    ..writeln()
    ..writeln('This is a ranked review queue, not an approval list.')
    ..writeln()
    ..writeln('- Core entries read: ${coreEntries.length}')
    ..writeln('- Unique candidates: ${candidates.length}')
    ..writeln('- Five graphemes: ${candidates.where((c) => c.length == 5).length}')
    ..writeln('- Six graphemes: ${candidates.where((c) => c.length == 6).length}')
    ..writeln()
    ..writeln('| Rank | Word | Length | Score | Definition | Flags |')
    ..writeln('| ---: | --- | ---: | ---: | --- | --- |');
  for (var index = 0; index < candidates.length; index++) {
    final candidate = candidates[index];
    final definition = candidate.definition
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
    markdown.writeln(
      '| ${index + 1} | ${candidate.word} | ${candidate.length} | '
      '${candidate.score} | $definition | ${candidate.flags.join(', ')} |',
    );
  }
  File('${reportDirectory.path}${Platform.pathSeparator}gurmukhi_candidates.md')
      .writeAsStringSync(markdown.toString());

  stdout.writeln('Generated ${candidates.length} native Gurmukhi candidates.');
  stdout.writeln(
    'Five graphemes: ${candidates.where((c) => c.length == 5).length}; '
    'six graphemes: ${candidates.where((c) => c.length == 6).length}.',
  );
  stdout.writeln('Reports: ${reportDirectory.path}');
}

Object _readJson(String path) => jsonDecode(File(path).readAsStringSync());

String? _normalizeHeadword(String? value) {
  if (value == null) return null;
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return normalized.isEmpty ? null : normalized;
}

bool _isGurmukhiWord(String value) {
  return RegExp(r'^[\u0A00-\u0A7F]+$').hasMatch(value) &&
      RegExp(r'[\u0A15-\u0A39\u0A59-\u0A5E]').hasMatch(value);
}

String _key(String value) => value;

// Gurmukhi combining marks belong to the preceding visible akhar. This keeps
// the importer independent of Flutter's package cache while matching the
// grapheme policy used by the app for normal Punjabi spellings.
int _gurmukhiVisibleLength(String value) {
  var count = 0;
  for (final rune in value.runes) {
    final isCombiningMark =
        (rune >= 0x0A01 && rune <= 0x0A03) ||
        (rune >= 0x0A3C && rune <= 0x0A4D) ||
        (rune >= 0x0A51 && rune <= 0x0A51) ||
        (rune >= 0x0A70 && rune <= 0x0A71) ||
        rune == 0x0A75;
    if (!isCombiningMark) count++;
  }
  return count;
}

String _cleanDefinition(String value) => value
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'\.{2,}'), '.')
    .trim();

String? _latinFromTransliteration(String? value) {
  if (value == null) return null;
  final mapped = value
      .replaceAll('ə', 'a')
      .replaceAll('Ə', 'A')
      .replaceAll('ı', 'i')
      .replaceAll('ṛ', 'r')
      .replaceAll('ṙ', 'r')
      .replaceAll('ṇ', 'n')
      .replaceAll('ṅ', 'n')
      .replaceAll('ñ', 'n')
      .replaceAll('ṭ', 't')
      .replaceAll('ḍ', 'd')
      .replaceAll('ś', 's')
      .replaceAll('ṣ', 's')
      .replaceAll('ṃ', 'm')
      .replaceAll('ṁ', 'm')
      .replaceAll('ā', 'a')
      .replaceAll('ī', 'i')
      .replaceAll('ū', 'u');
  final cleaned = mapped
      .replaceAll(RegExp(r'[^A-Za-z]'), '')
      .toUpperCase();
  return RegExp(r'^[A-Z]{2,24}$').hasMatch(cleaned) ? cleaned : null;
}

class _Candidate {
  const _Candidate({
    required this.id,
    required this.word,
    required this.length,
    required this.definition,
    required this.latin,
    required this.volume,
    required this.page,
  });

  final String id;
  final String word;
  final int length;
  final String definition;
  final String? latin;
  final int? volume;
  final int? page;

  List<String> get flags {
    final result = <String>[];
    final lower = definition.toLowerCase();
    if (RegExp(r'\b(see|refer|same as|variant|plural|fem(?:inine)?|past tense)\b')
        .hasMatch(lower)) {
      result.add('reference_or_inflection');
    }
    if (RegExp(
      r'\b(name of|proper noun|river|town|village|city|person|king|queen|saint)\b',
    ).hasMatch(lower)) {
      result.add('possible_name_or_place');
    }
    if (definition.length > 180) result.add('long_definition');
    if (latin == null) result.add('missing_clean_romanization');
    return result;
  }

  int get score {
    var value = 100;
    final lower = definition.toLowerCase();
    if (definition.length <= 180) value += 8;
    if (definition.length >= 25) value += 5;
    if (latin != null) value += 3;
    if (RegExp(r'\b(see|refer|same as|variant|plural|fem(?:inine)?|past tense)\b')
        .hasMatch(lower)) {
      value -= 28;
    }
    if (RegExp(
      r'\b(name of|proper noun|river|town|village|city|person|king|queen|saint)\b',
    ).hasMatch(lower)) {
      value -= 35;
    }
    if (definition.length > 220) value -= 18;
    return value;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'gurmukhi': word,
    'romanized': latin,
    'length': length,
    'score': score,
    'flags': flags,
    'definition': definition,
    'source': {
      'volume': volume,
      'page': page,
      'repository': 'https://github.com/redroyals/mahan-kosh-multilingual',
    },
  };
}

class _Options {
  const _Options({
    required this.corePath,
    required this.englishPath,
    required this.commit,
  });

  final String corePath;
  final String englishPath;
  final String commit;

  static _Options parse(List<String> arguments) {
    String? value(String name) {
      final prefix = '--$name=';
      for (final argument in arguments) {
        if (argument.startsWith(prefix)) return argument.substring(prefix.length);
      }
      return null;
    }

    return _Options(
      corePath: value('core') ?? '../mahan-kosh-core.json',
      englishPath: value('english') ?? '../mahan-kosh-en.json',
      commit: value('commit') ?? 'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6',
    );
  }
}
