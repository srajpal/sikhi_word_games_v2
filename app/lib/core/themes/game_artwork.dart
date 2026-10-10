import 'package:flutter/material.dart';

import 'paper_assets.dart';
export 'paper_assets.dart' show GameArtworkKind;

/// Full scenic artwork, with a quiet ink wash in Dark rather than new palettes.
class GameScene extends StatelessWidget {
  const GameScene({required this.kind, super.key});
  final GameArtworkKind kind;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = Image.asset(
      PaperAssets.scene(kind),
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      color: theme.brightness == Brightness.dark
          ? const Color(0x66304550)
          : null,
      colorBlendMode: BlendMode.srcATop,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
    if (kind != GameArtworkKind.letters) return ExcludeSemantics(child: scene);
    // Native glyphs remain crisp and correct. Their coordinates share the
    // illustration's full canvas, so cover cropping cannot detach the letters.
    return ExcludeSemantics(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 1536,
            height: 1024,
            child: Stack(
              children: [
                Positioned.fill(child: scene),
                for (final letter in [
                  ('ਕ', 1113.0, 384.0),
                  ('ਖ', 964.0, 641.0),
                  ('ਗ', 1261.0, 667.0),
                ])
                  Positioned(
                    left: letter.$2 - 90,
                    top: letter.$3 - 90,
                    width: 180,
                    height: 180,
                    child: Transform.rotate(
                      angle: .03,
                      child: Center(
                        child: Text(
                          letter.$1,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(
                            fontFamily: 'NotoSansGurmukhi',
                            fontSize: 155,
                            fontWeight: FontWeight.w800,
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameArtwork extends StatelessWidget {
  const GameArtwork({required this.kind, this.size = 88, super.key});
  final GameArtworkKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GameScene(kind: kind),
    ),
  );
}
