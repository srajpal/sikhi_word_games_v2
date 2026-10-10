import 'package:characters/characters.dart';

final _romanizedCombiningMarks = RegExp(r'[\u0300-\u036F]');
final _nonAscii = RegExp(r'[^\x00-\x7F]');
final _gurmukhiVirama = RegExp(r'\u0A4D');
final _linkedGurmukhiEnding = RegExp(r'\u0A4D[\u200C\u200D]*$');
final _gurmukhiConsonantStart = RegExp(r'^[\u0A15-\u0A39\u0A59-\u0A5E]');

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
  // Already composed and ordinary English text needs none of these replacements.
  if (!_romanizedCombiningMarks.hasMatch(value)) return value;
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

/// A beginner spelling view, not a replacement for the approved source text.
/// Each marked Roman letter becomes its plain base, preserving tile positions.
String simplifyRomanizedPunjabi(String value) {
  if (!_nonAscii.hasMatch(value)) return value;
  var result = normalizeRomanizedInput(value);
  for (final composition in _romanizedCompositions.entries) {
    result = result.replaceAll(composition.value, composition.key[0]);
    result = result.replaceAll(
      composition.value.toUpperCase(),
      composition.key[0].toUpperCase(),
    );
  }
  return result.replaceAll(_romanizedCombiningMarks, '');
}

/// Written tiles: a Latin letter with marks, or a Gurmukhi base with marks
/// and virama-linked subjoined letters. This matches the approved dictionaries.
List<String> wordUnits(String value) {
  // Characters already handles attached marks and emoji. Only Gurmukhi virama
  // links need the additional joining rule below.
  if (!_gurmukhiVirama.hasMatch(value)) return value.characters.toList();
  final units = <String>[];
  for (final cluster in value.characters) {
    if (units.isNotEmpty &&
        _linkedGurmukhiEnding.hasMatch(units.last) &&
        _gurmukhiConsonantStart.hasMatch(cluster)) {
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
