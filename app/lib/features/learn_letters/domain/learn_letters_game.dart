import 'dart:math';

import 'letter_entry.dart';
export 'letter_entry.dart';

class LearnLettersGame {
  LearnLettersGame._(
    this._index,
    this._answered, {
    required this.roundId,
    required List<String> questionIds,
    required List<List<String>> choiceIds,
    required List<int> wrongCounts,
    Set<String>? wrongChoiceIds,
  }) : questionIds = List.unmodifiable(questionIds),
       _choiceIds = choiceIds
           .map((row) => List<String>.unmodifiable(row))
           .toList(),
       _wrongCounts = List.of(wrongCounts),
       _wrongChoiceIds = Set.of(wrongChoiceIds ?? {});

  factory LearnLettersGame.newRound({
    Map<String, int> mastery = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    final ranked = [...learnLetters]..shuffle(rng);
    // Explicit tie ranks keep selection random even if sort isn't stable.
    final rank = {for (var i = 0; i < ranked.length; i++) ranked[i].id: i};
    ranked.sort((a, b) {
      final comparison = (mastery[a.id] ?? 0).compareTo(mastery[b.id] ?? 0);
      return comparison != 0 ? comparison : rank[a.id]!.compareTo(rank[b.id]!);
    });
    final questions = ranked.take(5).map((letter) => letter.id).toList()
      ..shuffle(rng);
    final choices = <List<String>>[];
    for (final id in questions) {
      final others = learnLetters.where((letter) => letter.id != id).toList()
        ..shuffle(rng);
      choices.add(
        [id, ...others.take(2).map((letter) => letter.id)]..shuffle(rng),
      );
    }
    return LearnLettersGame._(
      0,
      false,
      roundId:
          '${DateTime.now().microsecondsSinceEpoch}-${rng.nextInt(0x7fffffff)}',
      questionIds: questions,
      choiceIds: choices,
      wrongCounts: List.filled(5, 0),
    );
  }

  final String roundId;
  final List<String> questionIds;
  final List<List<String>> _choiceIds;
  final List<int> _wrongCounts;
  final Set<String> _wrongChoiceIds;
  int _index;
  bool _answered;
  int get index => _index;
  bool get answered => _answered;
  bool get isComplete => _index == questionIds.length - 1 && _answered;
  LetterEntry get currentLetter => learnLettersById[questionIds[_index]]!;
  List<LetterEntry> get choices =>
      List.unmodifiable(_choiceIds[_index].map((id) => learnLettersById[id]!));
  Set<String> get wrongChoiceIds => Set.unmodifiable(_wrongChoiceIds);
  int get answers => _index + (_answered ? 1 : 0);
  int get attempts =>
      answers + _wrongCounts.fold(0, (sum, count) => sum + count);
  int get firstTryCorrect => firstTryLetterIds.length;
  List<String> get firstTryLetterIds => List.unmodifiable([
    for (var i = 0; i < answers; i++)
      if (_wrongCounts[i] == 0) questionIds[i],
  ]);

  bool answer(String id) {
    if (_answered ||
        !_choiceIds[_index].contains(id) ||
        _wrongChoiceIds.contains(id)) {
      return false;
    }
    if (id == currentLetter.id) {
      _answered = true;
      return true;
    }
    _wrongChoiceIds.add(id);
    _wrongCounts[_index]++;
    return false;
  }

  void next() {
    if (!_answered || isComplete) return;
    _index++;
    _answered = false;
    _wrongChoiceIds.clear();
  }

  Map<String, Object?> toJson() => {
    'roundId': roundId,
    'questionIds': [...questionIds],
    'choiceIds': _choiceIds.map((row) => [...row]).toList(),
    'wrongCounts': [..._wrongCounts],
    'index': _index,
    'answered': _answered,
    'wrongChoiceIds': _wrongChoiceIds.toList(),
  };

  factory LearnLettersGame.fromJson(Map<String, Object?> json) {
    final roundId = json['roundId'] as String;
    final questions = (json['questionIds'] as List).cast<String>();
    final choices = (json['choiceIds'] as List)
        .map((row) => (row as List).cast<String>())
        .toList();
    final counts = (json['wrongCounts'] as List).cast<int>();
    final index = json['index'] as int;
    final answered = json['answered'] as bool;
    final wrongList = (json['wrongChoiceIds'] as List).cast<String>();
    final wrong = wrongList.toSet();
    bool known(String id) => learnLettersById.containsKey(id);
    if (roundId.isEmpty ||
        roundId.length > 160 ||
        questions.length != 5 ||
        questions.toSet().length != 5 ||
        !questions.every(known) ||
        choices.length != 5 ||
        counts.length != 5 ||
        index < 0 ||
        index >= 5 ||
        wrong.length != wrongList.length) {
      throw const FormatException('Invalid letter round');
    }
    for (var i = 0; i < 5; i++) {
      if (choices[i].length != 3 ||
          choices[i].toSet().length != 3 ||
          !choices[i].every(known) ||
          !choices[i].contains(questions[i]) ||
          counts[i] < 0 ||
          counts[i] > 2 ||
          (i > index && counts[i] != 0)) {
        throw const FormatException('Invalid letter choices');
      }
    }
    if (wrong.length != counts[index] ||
        wrong.contains(questions[index]) ||
        !wrong.every(choices[index].contains)) {
      throw const FormatException('Invalid letter attempts');
    }
    return LearnLettersGame._(
      index,
      answered,
      roundId: roundId,
      questionIds: questions,
      choiceIds: choices,
      wrongCounts: counts,
      wrongChoiceIds: wrong,
    );
  }
}
