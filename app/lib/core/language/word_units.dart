import 'package:characters/characters.dart';

const _romanizedCompositions = {
  'a\u0301': 'á',
  'a\u0303': 'ã',
  'n\u0303': 'ñ',
  'o\u0303': 'õ',
  'a\u0304': 'ā',
  'a\u0306': 'ă',
  'e\u0304': 'ē',
  'g\u0307': 'ġ',
  'i\u0303': 'ĩ',
  'i\u0304': 'ī',
  'i\u0306': 'ĭ',
  's\u0301': 'ś',
  'u\u0303': 'ũ',
  'u\u0304': 'ū',
  'd\u0323': 'ḍ',
  'l\u0323': 'ḷ',
  'm\u0323': 'ṃ',
  'n\u0307': 'ṅ',
  'n\u0323': 'ṇ',
  'r\u0323': 'ṛ',
  't\u0323': 'ṭ',
  'e\u0303': 'ẽ',
};

/// Composes equivalent input forms from the approved Romanized alphabet.
///
/// This preserves case and every accent, including marks attached to macron
/// letters (such as ā̃). It leaves text outside that alphabet unchanged.
String normalizeRomanizedInput(String value) {
  var result = value;
  for (final composition in _romanizedCompositions.entries) {
    result = result.replaceAll(composition.key, composition.value);
    result = result.replaceAll(
      composition.key.toUpperCase(),
      composition.value.toUpperCase(),
    );
  }
  return result;
}

/// Written tiles: a Latin letter with marks, or a Gurmukhi base with marks
/// and virama-linked subjoined letters. This matches the approved dictionaries.
List<String> wordUnits(String value) {
  final units = <String>[];
  for (final cluster in value.characters) {
    if (units.isNotEmpty &&
        RegExp(r'\u0A4D[\u200C\u200D]*$').hasMatch(units.last) &&
        RegExp(r'^[\u0A15-\u0A39\u0A59-\u0A5E]').hasMatch(cluster)) {
      units[units.length - 1] += cluster;
    } else {
      units.add(cluster);
    }
  }
  return units;
}

int wordUnitCount(String value) => wordUnits(value).length;

String withoutLastWordUnit(String value) {
  final units = wordUnits(value);
  return units.isEmpty ? '' : units.take(units.length - 1).join();
}
