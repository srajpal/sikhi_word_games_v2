import 'package:flutter/material.dart';

import '../../features/game_library/domain/game_launch_options.dart';
import 'game_artwork.dart';
import 'game_ui.dart';

/// One naming source for the library, game headers and help screens.
@immutable
class GameIdentity {
  const GameIdentity(this.englishTitle, this.punjabiName, this.artwork);

  final String englishTitle;
  final String punjabiName;
  final GameArtworkKind artwork;

  String get fullName => '$punjabiName: $englishTitle';

  static const bujho = GameIdentity(
    'Guess the Word',
    'Bujho',
    GameArtworkKind.deduction,
  );
  static const khoj = GameIdentity(
    'Word Search',
    'Khoj',
    GameArtworkKind.search,
  );
  static const quest = GameIdentity(
    'Word Quest',
    'Chardi Kala',
    GameArtworkKind.garden,
  );
  static const jodo = GameIdentity(
    'Word Bridges',
    'Jodo',
    GameArtworkKind.bridges,
  );
  static const letters = GameIdentity(
    'Learn Letters',
    'Akhar Pachhaan',
    GameArtworkKind.letters,
  );

  static GameIdentity forGame(GameKind game) => switch (game) {
    GameKind.guessTheWord => bujho,
    GameKind.wordSearch => khoj,
    GameKind.wordQuest => quest,
    GameKind.wordBridges => jodo,
    GameKind.learnLetters => letters,
  };
}

class GameHeading extends StatelessWidget {
  const GameHeading({
    required this.identity,
    this.compact = false,
    this.prominent = false,
    this.subtitle,
    this.titleSize,
    super.key,
  });

  final GameIdentity identity;
  final bool compact;
  final bool prominent;
  final Widget? subtitle;
  final double? titleSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = compact
        ? theme.appBarTheme.foregroundColor
        : theme.colorScheme.onSurface;
    final heading = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          identity.englishTitle,
          textAlign: compact ? TextAlign.center : null,
          style: theme.textTheme.labelMedium?.copyWith(
            color: ink,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 2),
        Semantics(
          header: true,
          child: Text(
            identity.punjabiName,
            textAlign: compact ? TextAlign.center : null,
            style: theme.textTheme.displaySmall?.copyWith(
              color: ink,
              fontSize:
                  titleSize ??
                  (compact
                      ? 20
                      : prominent
                      ? 36
                      : 27),
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
        ),
        if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
      ],
    );
    return compact
        ? PaperLabel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: heading,
          )
        : heading;
  }
}

/// Let titles grow with accessibility text instead of shrinking them to fit.
double gameToolbarHeight(BuildContext context, {bool subtitle = true}) {
  final scale = MediaQuery.textScalerOf(context);
  return scale.scale(20) * 1.25 + scale.scale(12) * (subtitle ? 3 : 1.5) + 24;
}

/// A small paper illustration and instruction, without a duplicate game title.
class GameSectionIntro extends StatelessWidget {
  const GameSectionIntro({
    required this.identity,
    required this.instruction,
    super.key,
  });
  final GameIdentity identity;
  final String instruction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      GameArtwork(kind: identity.artwork, size: 64),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          instruction,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}
