import 'dart:math';

import 'package:characters/characters.dart';

class GridPoint {
  const GridPoint(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is GridPoint && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

enum WordSearchDirection {
  east(0, 1),
  west(0, -1),
  south(1, 0),
  north(-1, 0),
  southEast(1, 1),
  southWest(1, -1),
  northEast(-1, 1),
  northWest(-1, -1);

  const WordSearchDirection(this.rowStep, this.columnStep);

  final int rowStep;
  final int columnStep;
}

class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.start,
    required this.direction,
  });

  final String word;
  final GridPoint start;
  final WordSearchDirection direction;

  Map<String, Object> toJson() => {
    'word': word,
    'row': start.row,
    'column': start.column,
    'direction': direction.name,
  };

  static PlacedWord fromJson(Map<String, Object?> json) {
    if (json['word'] is! String ||
        json['row'] is! int ||
        json['column'] is! int ||
        json['direction'] is! String) {
      throw const FormatException('Malformed placed word.');
    }
    final direction = WordSearchDirection.values.firstWhere(
      (value) => value.name == json['direction'],
    );
    return PlacedWord(
      word: json['word']! as String,
      start: GridPoint(json['row']! as int, json['column']! as int),
      direction: direction,
    );
  }

  List<GridPoint> cells() {
    final letters = word.characters.length;
    return [
      for (var index = 0; index < letters; index++)
        GridPoint(
          start.row + direction.rowStep * index,
          start.column + direction.columnStep * index,
        ),
    ];
  }
}

class WordSearchPuzzle {
  const WordSearchPuzzle({required this.cells, required this.words});

  final List<List<String>> cells;
  final List<PlacedWord> words;

  int get size => cells.length;

  Map<String, Object> toJson() => {
    'cells': cells,
    'words': [for (final word in words) word.toJson()],
  };

  static WordSearchPuzzle fromJson(Map<String, Object?> json) {
    if (json['cells'] is! List || json['words'] is! List) {
      throw const FormatException('Malformed word-search puzzle.');
    }
    final cells = <List<String>>[];
    for (final row in json['cells']! as List<Object?>) {
      if (row is! List<Object?> ||
          row.isEmpty ||
          row.any((cell) => cell is! String)) {
        throw const FormatException('Malformed word-search cells.');
      }
      cells.add([for (final cell in row) cell! as String]);
    }
    if (cells.isEmpty || cells.any((row) => row.length != cells.length)) {
      throw const FormatException('Word-search grid must be square.');
    }
    final words = [
      for (final word in json['words']! as List<Object?>)
        if (word is Map<String, Object?>)
          PlacedWord.fromJson(word)
        else
          throw const FormatException('Malformed placed word.'),
    ];
    if (words.isEmpty ||
        words.any(
          (word) => word.cells().any(
            (point) =>
                point.row < 0 ||
                point.column < 0 ||
                point.row >= cells.length ||
                point.column >= cells.length,
          ),
        )) {
      throw const FormatException('Placed word is outside the grid.');
    }
    return WordSearchPuzzle(cells: cells, words: words);
  }

  Set<GridPoint> cellsFor(PlacedWord word) => word.cells().toSet();

  PlacedWord? wordForSelection(List<GridPoint> selection) {
    for (final word in words) {
      final cells = word.cells();
      if (_sameCells(selection, cells) ||
          _sameCells(selection, cells.reversed)) {
        return word;
      }
    }
    return null;
  }

  static List<GridPoint>? lineBetween(GridPoint start, GridPoint end) {
    final rowDelta = end.row - start.row;
    final columnDelta = end.column - start.column;
    final rowDistance = rowDelta.abs();
    final columnDistance = columnDelta.abs();
    if (rowDistance == 0 && columnDistance == 0) return const [];
    if (rowDistance != 0 &&
        columnDistance != 0 &&
        rowDistance != columnDistance) {
      return null;
    }
    final rowStep = rowDelta == 0 ? 0 : rowDelta ~/ rowDistance;
    final columnStep = columnDelta == 0 ? 0 : columnDelta ~/ columnDistance;
    final length = max(rowDistance, columnDistance) + 1;
    return [
      for (var index = 0; index < length; index++)
        GridPoint(
          start.row + rowStep * index,
          start.column + columnStep * index,
        ),
    ];
  }

  static bool _sameCells(Iterable<GridPoint> one, Iterable<GridPoint> two) {
    final first = one.toList(growable: false);
    final second = two.toList(growable: false);
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

class WordSearchGenerator {
  WordSearchGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  WordSearchPuzzle generate({
    required Iterable<String> candidates,
    required List<String> fillerCharacters,
    int size = 10,
    int targetWordCount = 6,
  }) {
    if (size < 4) {
      throw ArgumentError.value(size, 'size', 'Must be at least 4.');
    }
    if (fillerCharacters.isEmpty) {
      throw ArgumentError.value(
        fillerCharacters,
        'fillerCharacters',
        'Cannot be empty.',
      );
    }
    final unique = <String>{};
    final words = <String>[];
    for (final candidate in candidates) {
      final word = candidate.trim().toUpperCase();
      final length = word.characters.length;
      if (length < 3 || length > size || !unique.add(word)) continue;
      words.add(word);
    }
    if (words.isEmpty) throw StateError('No words fit this word-search grid.');
    words.shuffle(_random);

    final cells = List.generate(size, (_) => List<String?>.filled(size, null));
    final placed = <PlacedWord>[];
    for (final word in words) {
      if (placed.length >= targetWordCount) break;
      final placement = _findPlacement(cells, word);
      if (placement == null) continue;
      final letters = word.characters.toList(growable: false);
      for (var index = 0; index < letters.length; index++) {
        cells[placement.start.row +
                placement.direction.rowStep * index][placement.start.column +
                placement.direction.columnStep * index] =
            letters[index];
      }
      placed.add(placement);
    }
    if (placed.isEmpty) throw StateError('Unable to place a word-search word.');
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        cells[row][column] ??=
            fillerCharacters[_random.nextInt(fillerCharacters.length)];
      }
    }
    return WordSearchPuzzle(
      cells: [for (final row in cells) row.cast<String>()],
      words: List.unmodifiable(placed),
    );
  }

  PlacedWord? _findPlacement(List<List<String?>> cells, String word) {
    final starts = [
      for (var row = 0; row < cells.length; row++)
        for (var column = 0; column < cells.length; column++)
          GridPoint(row, column),
    ]..shuffle(_random);
    final directions = WordSearchDirection.values.toList()..shuffle(_random);
    final letters = word.characters.toList(growable: false);
    for (final direction in directions) {
      for (final start in starts) {
        final endRow = start.row + direction.rowStep * (letters.length - 1);
        final endColumn =
            start.column + direction.columnStep * (letters.length - 1);
        if (endRow < 0 ||
            endColumn < 0 ||
            endRow >= cells.length ||
            endColumn >= cells.length) {
          continue;
        }
        var canPlace = true;
        for (var index = 0; index < letters.length; index++) {
          final current =
              cells[start.row + direction.rowStep * index][start.column +
                  direction.columnStep * index];
          if (current != null && current != letters[index]) {
            canPlace = false;
            break;
          }
        }
        if (canPlace) {
          return PlacedWord(word: word, start: start, direction: direction);
        }
      }
    }
    return null;
  }
}
