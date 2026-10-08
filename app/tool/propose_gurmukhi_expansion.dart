import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

import 'content/mahan_kosh_text.dart';

const _minimumCount = 100;
const _sourceCommit = 'fce213b0120a7cd53ecb11c4e2e96b84ce5d75c6';

final _unsafe = RegExp(
  r'\b(adult|battle|caste|deity|disease|district|enemy|goddess?|king|killer|medicine|mythical|penis|place name|poison|proper name|queen|sect|sexual|slur|surname|town|vagina|village|weapon|wife)\b',
  caseSensitive: false,
);
final _reference = RegExp(
  r'\b(also called|feminine|plural|same as|see |variant)\b',
  caseSensitive: false,
);

// Each row was selected after reading the pinned English sense. The concise
// definition is original project text, not a mechanically substituted keyword.
const _reviewedRows = '''
1-65-10|A garden or planted green space.
2-448-20|A garden or planted green space.
1-129-8|A teacher or instructor.
1-160-6|A teacher or instructor.
4-415-18|A teacher or instructor.
4-445-5|A teacher or instructor.
1-76-14|Love or friendship.
1-417-33|With love or affection.
1-417-34|With love or affection.
4-424-22|A loving person.
1-68-2|Going without food for a time.
1-178-0|Going without food for a time.
1-178-1|A person who does not eat or is fasting.
1-49-10|A group of stars.
1-50-1|Eager to learn or know.
1-62-6|The summer season.
1-183-5|Daily or every day.
3-497-2|The spring season.
1-154-0|A week.
3-519-21|The state of being a guest.
1-200-1|An unpleasant smell.
1-202-8|Spotted with black and white.
1-181-16|Cold or not hot.
3-465-27|To grow or be produced.
1-171-9|A chapter of a book.
1-215-12|A grove of mango trees.
1-180-10|Falsehood or untruth.
1-212-28|Food that cannot be eaten.
1-230-6|Pigeon pea, a type of pulse.
1-217-13|A wrong path or course.
1-260-27|Hopeful or expectant.
1-260-28|Hopeful or expectant.
1-243-24|A diamond.
1-274-13|Warm service and respect for guests.
1-287-4|A drinking cup or bowl.
1-301-15|A cloth worn around the waist.
1-342-16|Help or support.
1-377-16|Help or support.
4-416-3|A helper or assistant.
1-342-17|Today or this day.
1-356-28|Trust or confidence.
3-543-2|To trust or have faith.
3-543-3|Trust or confidence.
1-389-25|Close and loving.
1-411-21|Respect or honour.
1-408-17|Air or wind.
2-325-26|Air or wind.
1-422-5|Night-time.
1-445-1|The top of a door frame.
1-478-19|A person who can read and write.
1-516-23|To teach.
1-545-30|Coolness.
1-525-23|To stand upright.
1-525-24|To take or receive.
1-525-25|To bring or fetch.
1-591-11|To put someone to sleep.
1-538-5|Hair growing on the head.
1-555-16|Good or noble work.
1-556-28|A small oyster shell.
1-556-29|A pearl from an oyster shell.
1-553-10|To clean or wash.
2-356-25|To clean or wash.
2-647-13|To clean or wash.
1-576-12|To hear or listen.
1-608-4|Brave or lion-hearted.
1-560-11|A soft and comfortable seat.
1-601-4|Bravery or courage.
1-598-1|A cook.
4-126-7|A cook.
4-515-3|A cook.
1-619-2|A light yellow jasmine flower.
1-613-7|A farmer.
2-212-16|A farmer.
1-669-23|Health or a sound physical state.
1-669-24|Healthy or in a sound state.
1-651-24|Whole, complete, or full.
1-659-21|Tired from hard work.
1-657-0|A founder or one who establishes something.
2-33-17|Truth or reality.
2-53-19|A cloud.
2-60-3|Movement or activity.
2-45-13|Movement or activity.
2-61-8|To shake or move back and forth.
2-56-13|A green pigeon.
2-43-12|A close friend.
2-70-28|Wise and skilled.
2-135-12|Weak or feeble.
2-116-1|To cut into pieces.
2-140-14|A white gourd.
2-155-0|A close family relationship.
2-173-13|A person who prepares a sweet pudding.
2-195-2|A worker or manager.
2-196-20|A worker.
2-195-6|A workshop.
2-196-21|To arrange for work to be done.
2-176-18|A bronze worker.
2-223-4|A lotus flower.
2-668-2|A lotus flower.
2-246-4|To scrape the ground.
2-214-22|A red dye.
2-215-19|A cry or shriek.
2-225-12|To open or set free.
2-286-0|Kind and merciful.
2-325-6|A prayer.
3-505-18|A dance.
2-358-13|To laugh.
2-360-23|To read or study.
2-389-7|To speak or make a sound.
2-449-5|A flower vase.
2-421-10|Drowsiness or sleepiness.
2-421-12|To knead into a mass.
2-426-2|A type of wooden shoe.
2-458-7|A small owl.
2-455-7|A crossing where four paths meet.
2-508-2|A potter.
2-513-1|A hailstone.
2-593-3|An ember or spark.
2-611-20|A jump or leap.
3-191-33|A jump or leap.
3-733-13|To jump or hop.
2-665-1|A water bird.
2-665-5|An animal that lives in water.
2-665-7|A fish.
2-667-17|A water chestnut.
2-671-1|A stream or river.
2-727-6|Lit or filled with light.
2-708-26|A satchel for book pages.
2-737-7|The study of shapes and measurements.
2-691-27|A person eager to learn.
2-722-5|To search and find.
2-706-20|To search and find.
2-730-15|A gathering or fair.
3-50-9|To drip or trickle.
3-48-10|To walk at an easy pace.
3-32-13|To carry and deliver.
3-33-14|To cook or boil well.
3-546-14|A letter.
3-121-17|A cooked vegetable dish.
3-101-8|A cloth worn below the waist.
3-107-26|A book index or contents list.
3-116-28|Joy or happiness.
3-127-0|To help someone swim or cross a river.
3-178-23|A cotton carding tool.
3-209-29|To achieve or find.
3-240-11|Bright or shining.
3-263-22|To show.
3-303-15|Far away.
3-402-7|Fresh butter.
3-383-16|Engaged in dance.
3-384-18|To come close.
''';

Map<String, String> get _reviewedDefinitions => {
  for (final row in _reviewedRows.trim().split('\n'))
    row.substring(0, row.indexOf('|')): row.substring(row.indexOf('|') + 1),
};

const _latinOverrides = <String, String>{
  '1-260-27': 'ASABANDH',
  '1-260-28': 'ASABANDHU',
  '2-325-26': 'INDRANI',
  '2-358-13': 'KHANDIDAN',
  '2-593-3': 'CHANGIARA',
  '2-611-20': 'CHHALLANG',
  '3-32-13': 'PAHUNCHANA',
  '2-135-12': 'KAMJOR',
  '2-691-27': 'JIGYASU',
  '2-708-26': 'JUJDAN',
  '3-519-21': 'PAHUNAI',
  '3-497-2': 'NAUBAHAR',
};

const _excludedReasons = <String, String>{
  '1-129-8': 'Opaque historical loan; not useful enough for play.',
  '1-160-6': 'Opaque historical loan; not useful enough for play.',
  '4-415-18': 'Opaque historical loan; not useful enough for play.',
  '4-445-5': 'Opaque historical loan; not useful enough for play.',
  '1-49-10': 'Literary star synonym is too opaque for this pool.',
  '1-200-1': 'Archaic loan with limited play value.',
  '1-202-8': 'Specialized colour term with limited play value.',
  '1-181-16': 'Archaic Sanskrit form with limited play value.',
  '1-180-10': 'Archaic Sanskrit form with limited play value.',
  '1-212-28': 'Archaic Sanskrit form with limited play value.',
  '1-217-13': 'Archaic Sanskrit form with limited play value.',
  '1-287-4': 'Historical vessel term is too opaque for this pool.',
  '1-301-15': 'Historical garment term is too opaque for this pool.',
  '1-408-17': 'Literary wind synonym is too opaque for this pool.',
  '2-325-26':
      'Dictionary sense is clear but the headword is an opaque synonym.',
  '1-422-5': 'Archaic loan for night-time.',
  '1-445-1': 'Specialized architectural term.',
  '1-525-23': 'Archaic Persian form.',
  '1-525-24': 'Archaic Persian verb.',
  '1-525-25': 'Archaic Persian verb.',
  '1-538-5': 'Literary Sanskrit synonym for hair.',
  '1-556-28': 'Specialized Sanskrit shell term.',
  '1-556-29': 'Specialized Sanskrit pearl term.',
  '1-553-10': 'Archaic Persian verb.',
  '2-356-25': 'Source spelling is unusual and needs separate review.',
  '2-647-13': 'Archaic Persian verb.',
  '1-576-12': 'Archaic Persian verb.',
  '1-598-1': 'Literary cook synonym is too opaque.',
  '1-613-7': 'Literary farmer synonym is too opaque.',
  '2-53-19': 'Literary cloud synonym is too opaque.',
  '2-140-14': 'Specialized gourd name.',
  '2-173-13': 'Specialized occupational form.',
  '2-176-18': 'Specialized historical occupation.',
  '2-223-4': 'Opaque literary lotus synonym.',
  '2-214-22': 'Specialized dye term.',
  '2-215-19': 'Opaque literary term for a cry.',
  '2-225-12': 'Archaic Persian verb.',
  '2-358-13': 'Archaic Persian verb.',
  '2-360-23': 'Archaic Persian verb.',
  '2-421-10': 'Archaic Persian noun.',
  '2-458-7': 'Unfamiliar bird name needs separate review.',
  '2-508-2': 'Literary occupational synonym is too opaque.',
  '2-513-1': 'Literary hailstone synonym is too opaque.',
  '3-191-33': 'Archaic verb form.',
  '2-722-5': 'Archaic Persian verb.',
  '2-706-20': 'Archaic Persian verb.',
  '3-178-23': 'Source transliteration conflicts with the Gurmukhi consonants.',
  '3-240-11': 'Archaic Persian adjective.',
  '3-383-16': 'Literary dance term is too opaque.',
};

void main(List<String> args) {
  final write = args.contains('--write');
  final root = Directory.current.parent;
  final core = _map(File('${root.path}/mahan-kosh-core.json'));
  final english = _map(File('${root.path}/mahan-kosh-en.json'));
  final existingByGurmukhi = _loadExisting(Directory.current);
  final reviewed = _reviewedDefinitions;

  final candidates = <Map<String, Object?>>[];
  final rejected = <Map<String, String>>[];
  for (final raw in core['entries'] as List<dynamic>) {
    final entry = (raw as Map).cast<String, dynamic>();
    if (entry['excluded'] == true) continue;
    final headword = (entry['hw'] as String? ?? '').trim();
    final sourceTransliteration = (entry['tr'] as String? ?? '').trim();
    if (!reviewed.containsKey(entry['id'])) continue;
    final excludedReason = _excludedReasons[entry['id']];
    if (excludedReason != null) {
      rejected.add({
        'sourceId': entry['id'] as String,
        'reason': excludedReason,
      });
      continue;
    }
    if (!_isWord(headword) || headword.characters.length != 4) {
      rejected.add({
        'sourceId': entry['id'] as String,
        'reason': 'Headword is not exactly four Gurmukhi graphemes.',
      });
      continue;
    }
    final latin =
        _latinOverrides[entry['id']] ??
        romanizeMahanKosh(sourceTransliteration);
    if (latin == null) {
      rejected.add({
        'sourceId': entry['id'] as String,
        'reason':
            'Source transliteration cannot be converted without guessing.',
      });
      continue;
    }
    if (!_latinOverrides.containsKey(entry['id']) &&
        !hasMatchingPunjabiConsonants(headword, latin)) {
      rejected.add({
        'sourceId': entry['id'] as String,
        'reason':
            'Romanization does not preserve the Gurmukhi consonant order.',
      });
      continue;
    }
    final sourceId = entry['id'] as String;
    final definition = reviewed[sourceId];
    if (definition == null) continue;
    final sourceRecord = english[sourceId];
    if (sourceRecord is! Map) continue;
    final definitions = sourceRecord['definitions'];
    if (definitions is! List || definitions.isEmpty) continue;
    final sourceDefinition = definitions.first as String;
    final normalizedSourceDefinition = sourceDefinition
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Keep the full source text as evidence. Some reviewed records begin with
    // non-English etymology labels, so they are not display definitions.
    if (_unsafe.hasMatch(normalizedSourceDefinition) ||
        _reference.hasMatch(normalizedSourceDefinition)) {
      rejected.add({
        'sourceId': sourceId,
        'reason': 'Source evidence triggered the conservative suitability or cross-reference guard.',
      });
      continue;
    }
    final candidate = <String, Object?>{
      'sourceId': sourceId,
      'sourceHeadword': headword,
      'sourceDefinition': sourceDefinition,
      'sourceTransliteration': sourceTransliteration,
      'latin': latin,
      'gurmukhi': headword,
      'definition': definition,
      'reason': _latinOverrides.containsKey(sourceId)
          ? 'Selected after checking the pinned Mahan Kosh sense; the concise definition preserves that specific meaning. Romanization was corrected explicitly to preserve the source-script consonants. Four graphemes verified with package:characters.'
          : 'Selected after checking the pinned Mahan Kosh sense; the concise definition preserves that specific meaning and the four-grapheme count is verified with package:characters.',
      'reviewStatus': 'machineReviewed',
    };
    final existingId = existingByGurmukhi[headword];
    if (existingId != null) candidate['existingId'] = existingId;
    candidates.add(candidate);
  }

  final bySourceId = {
    for (final candidate in candidates) candidate['sourceId']: candidate,
  };
  final selected = reviewed.keys
      .map((sourceId) => bySourceId[sourceId])
      .whereType<Map<String, Object?>>()
      .toList();
  if (selected.length < _minimumCount) {
    stderr.writeln(
      'Only ${selected.length} proposals passed the bounded policy; expected at least $_minimumCount.',
    );
    exitCode = 1;
    return;
  }

  final output = const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'source': {
      'name': 'Mahan Kosh multilingual dataset',
      'commit': _sourceCommit,
      'license': 'CC BY 4.0',
    },
    'policy': {
      'decisionType': 'machine-reviewed proposals',
      'targetGraphemeLength': 4,
      'note': 'Each proposal still requires the normal editorial import decision. Automated lexical checks are not a claim of human review.',
    },
    'entryCount': selected.length,
    'entries': selected,
    'rejectedCount': rejected.length,
    'rejections': rejected,
  });
  final outputFile = File(
    '${root.path}/reports/content/gurmukhi_expansion_proposals.json',
  );
  if (write) {
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync('$output\n');
    stdout.writeln('Wrote ${selected.length} proposals to ${outputFile.path}.');
  } else {
    stdout.writeln(output);
  }
}

Map<String, dynamic> _map(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

bool _isWord(String value) =>
    RegExp(r'^[\u0A00-\u0A7F]+$').hasMatch(value) &&
    RegExp(r'[\u0A15-\u0A39\u0A59-\u0A5E]').hasMatch(value);

Map<String, String> _loadExisting(Directory app) {
  final result = <String, String>{};
  final files = <File>[
    ...Directory('${app.path}/assets/content/generated')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json')),
    File('${app.path}/assets/content/curation/supplemental_entries.json'),
  ];
  for (final file in files) {
    final decoded = jsonDecode(file.readAsStringSync());
    final records = decoded is List
        ? decoded
        : decoded is Map && decoded['entries'] is List
        ? decoded['entries'] as List
        : const [];
    for (final raw in records) {
      if (raw is! Map) continue;
      final entry = raw.cast<String, dynamic>();
      final word =
          entry['gurmukhi'] ??
          (entry['w'] is Map ? (entry['w'] as Map)['pa'] : null);
      final id = entry['id'];
      if (word is String && word.isNotEmpty && id is String) {
        result.putIfAbsent(word, () => id);
      }
    }
  }
  return result;
}
