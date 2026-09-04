import '../../guess_the_word/domain/language_mode.dart';

enum GameKind { guessTheWord, wordSearch, wordQuest }

class GameLaunchOptions {
  const GameLaunchOptions({
    this.language,
    this.wordSize,
    this.continueGame = false,
  });

  final LanguageMode? language;
  final int? wordSize;
  final bool continueGame;
}
