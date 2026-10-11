import '../../guess_the_word/domain/language_mode.dart';
import '../../learn_letters/domain/learn_letters_game.dart';

enum GameKind {
  guessTheWord,
  wordSearch,
  wordQuest,
  wordBridges,
  learnLetters,
  wordScramble,
}

class GameLaunchOptions {
  const GameLaunchOptions({
    this.language,
    this.wordSize,
    this.continueGame = false,
    this.letterPracticeMode = LetterPracticeMode.listening,
  });

  final LanguageMode? language;
  final int? wordSize;
  final bool continueGame;
  final LetterPracticeMode letterPracticeMode;
}
