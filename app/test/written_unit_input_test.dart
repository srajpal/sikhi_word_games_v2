import 'package:sikhi_word_games_v2/core/language/hardware_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_entry.dart';
import 'package:sikhi_word_games_v2/core/content/vocabulary_repository.dart';
import 'package:sikhi_word_games_v2/core/language/word_units.dart';
import 'package:sikhi_word_games_v2/core/persistence/key_value_store.dart';
import 'package:sikhi_word_games_v2/core/themes/app_theme.dart';
import 'package:sikhi_word_games_v2/features/dictionary/presentation/dictionary_page.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_game_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/guess_statistics_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/data/solution_history_repository.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/language_mode.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/domain/guess_game.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/game_keyboard.dart';
import 'package:sikhi_word_games_v2/features/guess_the_word/presentation/guess_the_word_page.dart';
import 'package:sikhi_word_games_v2/features/settings/data/app_settings_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/data/word_quest_session_repository.dart';
import 'package:sikhi_word_games_v2/features/word_quest/domain/word_quest_game.dart';
import 'package:sikhi_word_games_v2/features/word_quest/presentation/word_quest_page.dart';

void main() {
  testWidgets(
    'absent whole Gurmukhi tile cannot disable a needed conjunct constituent',
    (tester) async {
      final store = MemoryKeyValueStore();
      final repository = GuessGameRepository(store);
      await repository.save(
        mode: LanguageMode.gurmukhi,
        game: GuessGame(
          solution: 'ਪ੍ਰਾਕ੍ਰਿਤਿਕ',
          acceptedGuesses: {'ਪ੍ਰਾਕ੍ਰਿਤਿਕ', 'ਉਪਗ੍ਰਹਿ'},
        ),
      );
      await tester.pumpWidget(
        _app(
          GuessTheWordPage(
            vocabularyRepository: MemoryVocabularyRepository([
              _entry(
                'target_conjunct',
                'ਪ੍ਰਾਕ੍ਰਿਤਿਕ',
                VocabularyScript.gurmukhi,
              ),
              _entry('other_conjunct', 'ਉਪਗ੍ਰਹਿ', VocabularyScript.gurmukhi),
            ]),
            statisticsRepository: GuessStatisticsRepository(store),
            gameRepository: repository,
            solutionHistoryRepository: SolutionHistoryRepository(store),
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final character in ['ਉ', 'ਪ', 'ਗ', '੍', 'ਰ', 'ਹ', 'ਿ']) {
        await _tapKey(tester, character);
      }
      await _tapKey(tester, 'enter');
      await tester.pumpAndSettle();
      // Bare ਪ was absent, but remains available to compose the distinct ਪ੍ਰਾ tile.
      for (final character in [
        'ਪ',
        '੍',
        'ਰ',
        'ਾ',
        'ਕ',
        '੍',
        'ਰ',
        'ਿ',
        'ਤ',
        'ਿ',
        'ਕ',
      ]) {
        await _tapKey(tester, character);
      }
      expect(_text(tester, 'guess-value'), 'ਪ੍ਰਾਕ੍ਰਿਤਿਕ');
      await _tapKey(tester, 'enter');
      await tester.pumpAndSettle();
      expect(find.text('You found it!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final mode in [LanguageMode.romanizedPanjabi, LanguageMode.gurmukhi]) {
    testWidgets(
      '${mode.name} keyboard remains reachable at 320px and 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_guessApp(mode, textScale: 2));
        await tester.pumpAndSettle();
        final unit = mode == LanguageMode.gurmukhi ? 'ਆ' : 'Ā̃';
        final key = find.byKey(ValueKey('key-$unit'));
        await tester.ensureVisible(key);
        expect(key.hitTestable(), findsOneWidget);
        await tester.tap(key);
        await tester.pump();
        expect(_text(tester, 'guess-value'), unit);
        await tester.ensureVisible(find.byKey(const ValueKey('key-backspace')));
        await tester.tap(find.byKey(const ValueKey('key-backspace')));
        await tester.pump();
        expect(_text(tester, 'guess-value'), ' ');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Roman keyboard exposes distinct approved accented whole keys', (
    tester,
  ) async {
    final typed = <String>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: GameKeyboard(
            mode: LanguageMode.romanizedPanjabi,
            enabled: true,
            disabledCharacters: const {},
            additionalCharacters: const ['a\u0304', 'Ā', 'ā̃'],
            onCharacter: typed.add,
            onBackspace: () {},
            onEnter: () {},
          ),
        ),
      ),
    );
    for (final key in ['A', 'Ā', 'Ā̃', 'Ī̃', 'Ū̃', 'Ē̃', 'Ā́', 'Ṇ']) {
      expect(find.byKey(ValueKey('key-$key')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('key-$key')));
    }
    expect(typed, ['A', 'Ā', 'Ā̃', 'Ī̃', 'Ū̃', 'Ē̃', 'Ā́', 'Ṇ']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Gurmukhi keyboard includes independent vowels and conjunct signs',
    (tester) async {
      final typed = <String>[];
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: GameKeyboard(
              mode: LanguageMode.gurmukhi,
              enabled: true,
              disabledCharacters: const {},
              onCharacter: typed.add,
              onBackspace: () {},
              onEnter: () {},
            ),
          ),
        ),
      );
      for (final key in [
        'ਆ',
        'ਇ',
        'ਈ',
        'ਉ',
        'ਊ',
        'ਏ',
        'ਐ',
        'ਓ',
        'ਔ',
        '਼',
        '੍',
      ]) {
        await tester.tap(find.byKey(ValueKey('key-$key')));
      }
      expect(typed, ['ਆ', 'ਇ', 'ਈ', 'ਉ', 'ਊ', 'ਏ', 'ਐ', 'ਓ', 'ਔ', '਼', '੍']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bujho permits attached Roman marks at the tile cap and deletes the whole unit',
    (tester) async {
      await tester.pumpWidget(_guessApp(LanguageMode.romanizedPanjabi));
      await tester.pumpAndSettle();
      for (final character in ['A', 'B', 'B', 'A', '\u0304', '\u0303']) {
        await _type(tester, character);
      }
      expect(_text(tester, 'guess-value'), 'ABBĀ̃');
      await _type(tester, 'B');
      expect(_text(tester, 'guess-value'), 'ABBĀ̃');
      await tester.ensureVisible(find.byKey(const ValueKey('key-backspace')));
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      await tester.pump();
      expect(_text(tester, 'guess-value'), 'ABB');
      await tester.ensureVisible(find.byKey(const ValueKey('key-Ā̃')));
      await tester.tap(find.byKey(const ValueKey('key-Ā̃')));
      await tester.pump();
      expect(_text(tester, 'guess-value'), 'ABBĀ̃');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bujho composes a Gurmukhi conjunct at the tile cap and deletes it whole',
    (tester) async {
      await tester.pumpWidget(_guessApp(LanguageMode.gurmukhi));
      await tester.pumpAndSettle();
      for (final character in ['ਕ', 'ਲ', 'ਮ', 'ਪ', '੍', 'ਰ', 'ਿ']) {
        await _type(tester, character);
      }
      expect(_text(tester, 'guess-value'), 'ਕਲਮਪ੍ਰਿ');
      expect(wordUnitCount(_text(tester, 'guess-value')), 4);
      await _type(tester, 'ਆ');
      expect(_text(tester, 'guess-value'), 'ਕਲਮਪ੍ਰਿ');
      await tester.ensureVisible(find.byKey(const ValueKey('key-backspace')));
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      await tester.pump();
      expect(_text(tester, 'guess-value'), 'ਕਲਮ');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Dictionary preserves hardware accents and permits attached marks at 32 tiles',
    (tester) async {
      await tester.pumpWidget(
        _app(DictionaryPage(vocabularyRepository: _vocabulary)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<LanguageMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LanguageMode.romanizedPanjabi.label).last);
      await tester.pumpAndSettle();
      for (var i = 0; i < 32; i++) {
        await _type(tester, 'A');
      }
      await _type(tester, '\u0304');
      await _type(tester, '\u0303');
      final query = _text(tester, 'dictionary-query');
      expect(query, '${'A' * 31}Ā̃');
      expect(wordUnitCount(query), 32);
      await _type(tester, 'B');
      expect(_text(tester, 'dictionary-query'), query);
      await tester.ensureVisible(find.byKey(const ValueKey('key-backspace')));
      await tester.tap(find.byKey(const ValueKey('key-backspace')));
      await tester.pump();
      expect(_text(tester, 'dictionary-query'), 'A' * 31);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Quest full Roman bank retains accented distractors and accepts a canonical hardware unit',
    (tester) async {
      final repository = WordQuestSessionRepository(MemoryKeyValueStore());
      await repository.save(
        mode: LanguageMode.romanizedPanjabi,
        wordSize: 4,
        game: WordQuestGame(solution: 'ABBĀ̃'),
      );
      await tester.pumpWidget(
        _app(
          WordQuestPage(
            vocabularyRepository: _vocabulary,
            hapticLevel: HapticFeedbackLevel.off,
            reducedMotion: true,
            sessionRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('word-quest-keyboard-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('word-quest-key-Ī̃')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-quest-key-Ā̃')), findsOneWidget);
      await _type(tester, 'A\u0304\u0303');
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.guessedGraphemes, contains('Ā̃'));
      expect(repository.restore()!.game.incorrectGuesses, 0);
      await _type(tester, '\u0304');
      await tester.pumpAndSettle();
      expect(repository.restore()!.game.incorrectGuesses, 0);
      expect(
        repository.restore()!.game.guessedGraphemes,
        isNot(contains('\u0304')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('hardware validation preserves approved accents and excludes unrelated input', () {
    for (final unit in [
      'ā̃',
      'ī̃',
      'ū̃',
      'ē̃',
      'ā́',
      'A\u0304\u0303',
      '\u0304',
    ]) {
      expect(
        HardwareInput.acceptsCharacter(
          LanguageMode.romanizedPanjabi.script,
          unit,
        ),
        isTrue,
      );
    }
    expect(
      HardwareInput.acceptsCharacter(LanguageMode.gurmukhi.script, 'ਪ੍ਰਿ'),
      isTrue,
    );
    for (final unrelated in ['1', ' ', '🙂']) {
      expect(
        HardwareInput.acceptsCharacter(
          LanguageMode.romanizedPanjabi.script,
          unrelated,
        ),
        isFalse,
      );
    }
    expect(
      HardwareInput.acceptsCharacter(LanguageMode.english.script, 'Ā'),
      isFalse,
    );
  });
}

Future<void> _type(WidgetTester tester, String character) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: character);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, String character) async {
  final key = find.byKey(ValueKey('key-$character'));
  await tester.ensureVisible(key);
  await tester.tap(key);
  await tester.pump();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

Widget _app(Widget page, {double textScale = 1}) => MaterialApp(
  theme: AppThemes.forChoice(AppThemeChoice.modern),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: page,
);

Widget _guessApp(LanguageMode mode, {double textScale = 1}) {
  final store = MemoryKeyValueStore();
  return _app(
    GuessTheWordPage(
      vocabularyRepository: _vocabulary,
      statisticsRepository: GuessStatisticsRepository(store),
      gameRepository: GuessGameRepository(store),
      solutionHistoryRepository: SolutionHistoryRepository(store),
      hapticLevel: HapticFeedbackLevel.off,
      reducedMotion: true,
      initialMode: mode,
      initialWordLength: 4,
      startFresh: true,
    ),
    textScale: textScale,
  );
}

final _vocabulary = MemoryVocabularyRepository([
  _entry('roman', 'abbā̃', VocabularyScript.romanizedPunjabi),
  _entry('roman_extra', 'ī̃xyā́', VocabularyScript.romanizedPunjabi),
  _entry('gurmukhi', 'ਕਲਮਪ੍ਰਿ', VocabularyScript.gurmukhi),
]);

VocabularyEntry _entry(
  String id,
  String word,
  VocabularyScript script,
) => VocabularyEntry(
  id: id,
  language: VocabularyLanguage.panjabi,
  script: script,
  latin: script == VocabularyScript.gurmukhi ? 'counterpart' : word,
  gurmukhi: script == VocabularyScript.gurmukhi ? word : null,
  englishDefinition: 'A small plant with green leaves.',
  latinLength: script == VocabularyScript.gurmukhi ? 11 : wordUnitCount(word),
  gurmukhiLength: script == VocabularyScript.gurmukhi
      ? wordUnitCount(word)
      : null,
  acceptedGuess: true,
  solutionEligible: true,
  reviewStatus: ReviewStatus.editorApproved,
  source: 'Project editorial definition; original text for Sikhi Word Games',
);
