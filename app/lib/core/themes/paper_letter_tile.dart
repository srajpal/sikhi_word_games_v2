import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../audio/interaction_sounds.dart';

/// Interactive written-unit tiles use the same paper treatment as game boards.
class PaperLetterTile extends StatelessWidget {
  const PaperLetterTile({
    required this.label,
    required this.size,
    this.text,
    this.onPressed,
    this.correct = false,
    this.locked = false,
    super.key,
  });
  final String label;
  final double size;
  final String? text;
  final VoidCallback? onPressed;
  final bool correct, locked;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final fill = correct ? tokens.correct : theme.colorScheme.surface;
    final ink = correct
        ? tokens.foregroundFor(fill)
        : theme.colorScheme.onSurface;
    final action = InteractionSounds.letterAction(context, onPressed);
    return Semantics(
      label: label,
      button: onPressed != null,
      onTap: action,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size + 8,
        child: DecoratedBox(
          decoration: tokens.tileDecoration(
            fill,
            border: locked ? tokens.correct : tokens.paperEdge,
            borderWidth: locked ? 2 : null,
          ),
          child: TextButton(
            onPressed: action,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(4),
              foregroundColor: ink,
              disabledForegroundColor: ink,
              shape: RoundedRectangleBorder(borderRadius: tokens.tileRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text ?? '·',
                  softWrap: false,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: ink,
                  ),
                ),
                if (locked || correct)
                  Icon(
                    correct ? Icons.check : Icons.lock_outline,
                    size: 12,
                    color: ink,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
