import 'package:flutter/material.dart';

import '../../../core/language/gurmukhi_romanization.dart';
import '../../../core/language/word_units.dart';
import '../../../core/language/hardware_input.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/audio/interaction_sounds.dart';
import '../../../core/widgets/gurmukhi_key_label.dart';
import '../domain/language_mode.dart';
import '../domain/guess_evaluator.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    required this.mode,
    required this.onCharacter,
    required this.onBackspace,
    required this.onEnter,
    required this.enabled,
    required this.disabledCharacters,
    this.compact = false,
    this.largeKeys = false,
    this.enterLabel = 'ENTER',
    this.letterResults = const {},
    this.additionalCharacters = const [],
    this.simpleRomanized = false,
    super.key,
  });

  final LanguageMode mode;
  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;
  final bool enabled;
  final Set<String> disabledCharacters;
  final bool compact;
  final bool largeKeys;
  final String enterLabel;
  final Map<String, LetterResult> letterResults;
  final Iterable<String> additionalCharacters;
  final bool simpleRomanized;

  Color? _keyFill(BuildContext context, String character) {
    // Whole-tile clues cannot classify a constituent of another Gurmukhi tile.
    if (mode == LanguageMode.gurmukhi) return null;
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return switch (letterResults[character]) {
      LetterResult.correct => tokens.correct,
      LetterResult.present => tokens.present,
      LetterResult.absent => tokens.absent,
      null => disabledCharacters.contains(character) ? tokens.absent : null,
    };
  }

  String _gurmukhiKeyName(String character) => switch (character) {
    '਼' => 'nukta mark',
    '੍' => 'virama, join the next consonant',
    _ => romanizeGurmukhiGrapheme(character),
  };

  @override
  Widget build(BuildContext context) {
    final keyHeight = largeKeys
        ? (compact ? 44.0 : 52.0)
        : (compact ? 31.0 : 43.0);
    final rows = <List<String>>[
      ...(mode == LanguageMode.gurmukhi
          ? HardwareInput.gurmukhiRows
          : HardwareInput.latinRows),
    ];
    final disabled = mode == LanguageMode.gurmukhi
        ? const <String>{}
        : disabledCharacters;
    if (mode == LanguageMode.romanizedPanjabi && !simpleRomanized) {
      final existing = rows.expand((row) => row).toSet();
      final extra = <String>{
        ...HardwareInput.romanizedLetters.map((letter) => letter.toUpperCase()),
        ...additionalCharacters
            .map(normalizeRomanizedInput)
            .map((letter) => letter.toUpperCase()),
      }.where((letter) => !existing.contains(letter)).toList();
      for (var start = 0; start < extra.length; start += 10) {
        rows.add(extra.skip(start).take(10).toList());
      }
    }
    return Semantics(
      label: mode == LanguageMode.gurmukhi
          ? 'Gurmukhi game keyboard'
          : 'Latin game keyboard',
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
            Padding(
              padding: EdgeInsets.only(
                left: _rowInset(rowIndex, rows.length),
                right: _rowInset(rowIndex, rows.length),
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final character in rows[rowIndex])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _KeyboardButton(
                          key: ValueKey('key-$character'),
                          fill: _keyFill(context, character),
                          stateValue: switch (mode == LanguageMode.gurmukhi
                              ? null
                              : letterResults[character]) {
                            LetterResult.correct => 'correct position',
                            LetterResult.present =>
                              'present in another position',
                            _ => null,
                          },
                          label: mode == LanguageMode.gurmukhi
                              ? null
                              : character,
                          semanticLabel: disabled.contains(character)
                              ? mode == LanguageMode.gurmukhi
                                    ? '$character, ${_gurmukhiKeyName(character)}, not in the word'
                                    : '$character, not in the word'
                              : mode == LanguageMode.gurmukhi
                              ? '$character, ${_gurmukhiKeyName(character)}'
                              : character,
                          onPressed: enabled && !disabled.contains(character)
                              ? InteractionSounds.letterAction(
                                  context,
                                  () => onCharacter(character),
                                )
                              : null,
                          height: keyHeight,
                          fontSize: largeKeys ? (compact ? 20 : 22) : null,
                          child: mode == LanguageMode.gurmukhi
                              ? GurmukhiKeyLabel(
                                  grapheme: character,
                                  color: _keyFill(context, character) == null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                            .extension<GameThemeTokens>()!
                                            .foregroundFor(
                                              _keyFill(context, character)!,
                                            ),
                                  gurmukhiFontSize: largeKeys
                                      ? (compact ? 20 : 24)
                                      : (compact ? 13 : 15),
                                  romanizationFontSize: largeKeys
                                      ? (compact ? 8 : 9)
                                      : (compact ? 6 : 7),
                                )
                              : null,
                        ),
                      ),
                    ),
                  if (rowIndex == rows.length - 1) ...[
                    const SizedBox(width: 3),
                    Expanded(
                      child: _KeyboardButton(
                        key: const ValueKey('key-backspace'),
                        semanticLabel: 'Delete last letter',
                        onPressed: InteractionSounds.buttonAction(
                          context,
                          enabled ? onBackspace : null,
                        ),
                        height: keyHeight,
                        child: const Icon(Icons.backspace_outlined, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: _KeyboardButton(
              key: const ValueKey('key-enter'),
              label: enterLabel,
              fill: Theme.of(context).colorScheme.primary,
              foreground: Theme.of(context).colorScheme.onPrimary,
              semanticLabel: enterLabel == 'ENTER'
                  ? 'Submit guess'
                  : enterLabel.toLowerCase(),
              onPressed: InteractionSounds.buttonAction(
                context,
                enabled ? onEnter : null,
              ),
              height: keyHeight,
            ),
          ),
        ],
      ),
    );
  }

  double _rowInset(int rowIndex, int rowCount) {
    if (mode != LanguageMode.english) return 0;
    if (rowIndex == 1) return 14;
    if (rowIndex == rowCount - 1) return 24;
    return 0;
  }
}

class _KeyboardButton extends StatelessWidget {
  const _KeyboardButton({
    this.label,
    this.semanticLabel,
    this.onPressed,
    this.child,
    required this.height,
    this.fill,
    this.foreground,
    this.stateValue,
    this.fontSize,
    super.key,
  });

  final String? label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final Widget? child;
  final double height;
  final Color? fill;
  final Color? foreground;
  final String? stateValue;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel ?? label,
    value: stateValue,
    excludeSemantics: true,
    onTap: onPressed,
    child: Tooltip(
      message: semanticLabel ?? label ?? '',
      child: SizedBox(
        height: height,
        child: _KeyboardSurface(
          onPressed: onPressed,
          fill: fill,
          foreground: foreground,
          child:
              child ??
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    color:
                        foreground ??
                        (fill == null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                  .extension<GameThemeTokens>()!
                                  .foregroundFor(fill!)),
                  ),
                ),
              ),
        ),
      ),
    ),
  );
}

class _KeyboardSurface extends StatelessWidget {
  const _KeyboardSurface({
    required this.onPressed,
    required this.child,
    this.fill,
    this.foreground,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? fill;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final radius = BorderRadius.circular(9);
    final color = fill ?? theme.colorScheme.surface;
    final ink =
        foreground ??
        (fill == null
            ? theme.colorScheme.onSurface
            : tokens.foregroundFor(color));
    return DecoratedBox(
      decoration: tokens.tileDecoration(color),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: ink,
          disabledForegroundColor: ink,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: child,
      ),
    );
  }
}
