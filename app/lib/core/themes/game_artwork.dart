import 'package:flutter/material.dart';

import 'app_theme.dart';

enum GameArtworkKind { deduction, search, garden }

/// Small, decorative game previews. No sacred marks or hidden answer data.
class GameArtwork extends StatelessWidget {
  const GameArtwork({required this.kind, super.key});
  final GameArtworkKind kind;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _GameArtworkPainter(
          kind: kind,
          scheme: Theme.of(context).colorScheme,
          tokens: Theme.of(context).extension<GameThemeTokens>()!,
        ),
      ),
    ),
  );
}

class _GameArtworkPainter extends CustomPainter {
  const _GameArtworkPainter({
    required this.kind,
    required this.scheme,
    required this.tokens,
  });
  final GameArtworkKind kind;
  final ColorScheme scheme;
  final GameThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      Paint()..color = scheme.primary.withValues(alpha: .08),
    );
    if (kind == GameArtworkKind.garden) {
      final line = Paint()
        ..color = scheme.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(38, 55), const Offset(38, 29), line);
      canvas.drawOval(
        const Rect.fromLTWH(23, 35, 16, 9),
        Paint()..color = tokens.correct,
      );
      canvas.drawOval(
        const Rect.fromLTWH(39, 29, 16, 9),
        Paint()..color = tokens.correct,
      );
      canvas.drawCircle(
        const Offset(38, 22),
        7,
        Paint()..color = scheme.secondary,
      );
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(15 + i * 17, 58, 12, 6),
            const Radius.circular(3),
          ),
          Paint()..color = scheme.primary.withValues(alpha: .35),
        );
      }
      return;
    }
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final selected = kind == GameArtworkKind.deduction
            ? row == 2 || row == 1 && col == 1
            : row == col;
        final rect = Rect.fromLTWH(11 + col * 19, 11 + row * 19, 16, 16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = selected ? tokens.correct : scheme.surface,
        );
        if (!selected) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()
              ..color = scheme.outlineVariant
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
        if (selected) {
          final text = TextPainter(
            text: TextSpan(
              text: 'SUN'[col],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(
            canvas,
            rect.center - Offset(text.width / 2, text.height / 2),
          );
        }
      }
    }
    if (kind == GameArtworkKind.search) {
      canvas.drawLine(
        const Offset(19, 19),
        const Offset(57, 57),
        Paint()
          ..color = scheme.secondary.withValues(alpha: .7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameArtworkPainter old) =>
      old.kind != kind || old.scheme != scheme || old.tokens != tokens;
}

/// Theme-aware illustration colors shared by game previews and the word garden.
class GameSceneColors {
  GameSceneColors(ThemeData theme)
    : sky = theme.colorScheme.primaryContainer,
      horizon = theme.colorScheme.secondaryContainer,
      leaf = theme.brightness == Brightness.dark
          ? const Color(0xFF48977F)
          : const Color(0xFF438A62),
      hill = theme.brightness == Brightness.dark
          ? const Color(0xFF234B4D)
          : const Color(0xFFB4D5A7),
      sun = theme.brightness == Brightness.dark
          ? const Color(0xFFFFDC8B)
          : const Color(0xFFE8AD35),
      stem = theme.brightness == Brightness.dark
          ? const Color(0xFF9BC7AE)
          : const Color(0xFF315C44);
  final Color sky;
  final Color horizon;
  final Color leaf;
  final Color hill;
  final Color sun;
  final Color stem;
}
