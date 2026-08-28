import 'package:flutter/material.dart';

import '../domain/language_mode.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    required this.mode,
    required this.onCharacter,
    required this.onBackspace,
    required this.onEnter,
    required this.enabled,
    required this.disabledCharacters,
    this.compact = false,
    this.enterLabel = 'ENTER',
    super.key,
  });

  final LanguageMode mode;
  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;
  final bool enabled;
  final Set<String> disabledCharacters;
  final bool compact;
  final String enterLabel;

  static const _latinRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static const _gurmukhiRows = [
    ['ਕ', 'ਖ', 'ਗ', 'ਘ', 'ਙ', 'ਚ', 'ਛ', 'ਜ', 'ਝ', 'ਞ'],
    ['ਟ', 'ਠ', 'ਡ', 'ਢ', 'ਣ', 'ਤ', 'ਥ', 'ਦ', 'ਧ', 'ਨ'],
    ['ਪ', 'ਫ', 'ਬ', 'ਭ', 'ਮ', 'ਯ', 'ਰ', 'ਲ', 'ਵ', 'ੜ'],
    ['ਸ', 'ਹ', 'ੳ', 'ਅ', 'ੲ', 'ਸ਼', 'ਖ਼', 'ਗ਼', 'ਜ਼', 'ਫ਼'],
    ['ਾ', 'ਿ', 'ੀ', 'ੁ', 'ੂ', 'ੇ', 'ੈ', 'ੋ', 'ੌ', 'ੰ', 'ਂ', 'ੱ'],
  ];

  @override
  Widget build(BuildContext context) {
    final rows = mode == LanguageMode.gurmukhi ? _gurmukhiRows : _latinRows;
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
                          label: character,
                          semanticLabel: disabledCharacters.contains(character)
                              ? '$character, not in the word'
                              : character,
                          onPressed:
                              enabled && !disabledCharacters.contains(character)
                              ? () => onCharacter(character)
                              : null,
                          height: compact ? 31 : 43,
                        ),
                      ),
                    ),
                  if (rowIndex == rows.length - 1) ...[
                    const SizedBox(width: 3),
                    Expanded(
                      child: _KeyboardButton(
                        key: const ValueKey('key-backspace'),
                        semanticLabel: 'Delete last letter',
                        onPressed: enabled ? onBackspace : null,
                        height: compact ? 31 : 43,
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
              semanticLabel: enterLabel == 'ENTER'
                  ? 'Submit guess'
                  : enterLabel.toLowerCase(),
              onPressed: enabled ? onEnter : null,
              height: compact ? 31 : 43,
            ),
          ),
        ],
      ),
    );
  }

  double _rowInset(int rowIndex, int rowCount) {
    if (mode == LanguageMode.gurmukhi) return 0;
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
    super.key,
  });

  final String? label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final Widget? child;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: Tooltip(
      message: semanticLabel ?? label ?? '',
      child: SizedBox(
        height: height,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          onPressed: onPressed,
          child:
              child ??
              Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  );
}
