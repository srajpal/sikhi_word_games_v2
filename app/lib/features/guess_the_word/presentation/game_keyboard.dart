import 'package:flutter/material.dart';

import '../domain/language_mode.dart';

class GameKeyboard extends StatelessWidget {
  const GameKeyboard({
    required this.mode,
    required this.onCharacter,
    required this.onBackspace,
    required this.onEnter,
    required this.enabled,
    super.key,
  });

  final LanguageMode mode;
  final ValueChanged<String> onCharacter;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;
  final bool enabled;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final character in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _KeyboardButton(
                          key: ValueKey('key-$character'),
                          label: character,
                          onPressed: enabled
                              ? () => onCharacter(character)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _KeyboardButton(
                  key: const ValueKey('key-backspace'),
                  semanticLabel: 'Delete last letter',
                  onPressed: enabled ? onBackspace : null,
                  child: const Icon(Icons.backspace_outlined, size: 20),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                flex: 3,
                child: _KeyboardButton(
                  key: const ValueKey('key-enter'),
                  label: 'ENTER',
                  semanticLabel: 'Submit guess',
                  onPressed: enabled ? onEnter : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  const _KeyboardButton({
    this.label,
    this.semanticLabel,
    this.onPressed,
    this.child,
    super.key,
  });

  final String? label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel ?? label,
    child: SizedBox(
      height: 43,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        onPressed: onPressed,
        child:
            child ??
            Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ),
  );
}
