import 'package:flutter/material.dart';

import 'app_theme.dart';

enum GameArtworkKind { deduction, search, garden, bridges, letters }

/// A shared family of secular illustrations, independent of puzzle answers.
class GameArtwork extends StatelessWidget {
  const GameArtwork({required this.kind, this.size = 88, super.key});
  final GameArtworkKind kind;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GameArtworkPainter(kind, Theme.of(context))),
    ),
  );
}

class _GameArtworkPainter extends CustomPainter {
  _GameArtworkPainter(this.kind, this.theme);
  final GameArtworkKind kind;
  final ThemeData theme;
  @override
  void paint(Canvas canvas, Size size) {
    final scheme = theme.colorScheme;
    final colors = GameSceneColors(theme);
    final tokens = theme.extension<GameThemeTokens>()!;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    void box(Rect rect, Color color, [double radius = 12]) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
    void line(Offset a, Offset b, Color color, [double width = 4]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    box(const Rect.fromLTWH(0, 0, 100, 100), scheme.primaryContainer, 24);
    canvas.drawCircle(const Offset(80, 19), 12, Paint()..color = colors.sun);
    switch (kind) {
      case GameArtworkKind.letters:
        box(const Rect.fromLTWH(12, 27, 42, 54), scheme.secondaryContainer, 8);
        box(const Rect.fromLTWH(44, 37, 43, 54), scheme.surface, 8);
        for (final entry in [('ਅ', 17.0, 29.0), ('ਕ', 49.0, 39.0)]) {
          final text = TextPainter(
            text: TextSpan(
              text: entry.$1,
              style: TextStyle(
                fontFamily: 'NotoSansGurmukhi',
                fontSize: 35,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(canvas, Offset(entry.$2, entry.$3));
          text.dispose();
        }
      case GameArtworkKind.deduction:
        canvas.save();
        canvas.translate(15, 19);
        canvas.rotate(-.12);
        box(
          const Rect.fromLTWH(0, 0, 64, 64),
          scheme.secondary.withValues(alpha: .25),
        );
        canvas.restore();
        box(const Rect.fromLTWH(22, 24, 64, 64), scheme.surface);
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 2; col++) {
            final r = Rect.fromLTWH(29 + col * 25, 31 + row * 25, 20, 20);
            box(r, row == 1 ? tokens.correct : scheme.secondaryContainer, 5);
            if (row == 1) {
              line(
                r.center + const Offset(-4, 0),
                r.center + const Offset(-1, 3),
                Colors.white,
                2,
              );
              line(
                r.center + const Offset(-1, 3),
                r.center + const Offset(5, -4),
                Colors.white,
                2,
              );
            }
          }
        }
      case GameArtworkKind.search:
        box(const Rect.fromLTWH(12, 20, 60, 62), scheme.surface, 10);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            canvas.drawCircle(
              Offset(24 + col * 17, 33 + row * 17),
              3,
              Paint()
                ..color = row == col ? tokens.correct : scheme.outlineVariant,
            );
          }
        }
        line(
          const Offset(24, 33),
          const Offset(58, 67),
          tokens.correct.withValues(alpha: .4),
          7,
        );
        line(const Offset(70, 66), const Offset(86, 85), scheme.primary, 9);
        canvas.drawCircle(
          const Offset(60, 52),
          22,
          Paint()
            ..color = scheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6,
        );
      case GameArtworkKind.garden:
        final hill = Path()
          ..moveTo(0, 80)
          ..quadraticBezierTo(45, 50, 100, 76)
          ..lineTo(100, 100)
          ..lineTo(0, 100)
          ..close();
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 100, 100),
            const Radius.circular(24),
          ),
        );
        canvas.drawPath(hill, Paint()..color = colors.hill);
        canvas.restore();
        for (final x in [29.0, 63.0]) {
          final y = x == 29 ? 47.0 : 35.0;
          line(Offset(x, 83), Offset(x, y), colors.stem, 4);
          canvas.drawOval(
            Rect.fromLTWH(x - 15, y + 17, 16, 9),
            Paint()..color = colors.leaf,
          );
          canvas.drawOval(
            Rect.fromLTWH(x, y + 9, 16, 9),
            Paint()..color = colors.leaf,
          );
          for (final o in [
            const Offset(-6, 0),
            const Offset(6, 0),
            const Offset(0, -6),
            const Offset(0, 6),
          ]) {
            canvas.drawCircle(
              Offset(x, y) + o,
              6,
              Paint()..color = x == 29 ? scheme.secondary : colors.sun,
            );
          }
          canvas.drawCircle(Offset(x, y), 4, Paint()..color = scheme.surface);
        }
      case GameArtworkKind.bridges:
        for (var i = 0; i < 3; i++) {
          final y = 72.0 + i * 8;
          final water = Path()
            ..moveTo(10, y)
            ..cubicTo(30, y - 8, 62, y + 8, 90, y);
          canvas.drawPath(
            water,
            Paint()
              ..color = scheme.primary.withValues(alpha: .3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        final arch = Path()
          ..moveTo(16, 67)
          ..quadraticBezierTo(50, 7, 84, 67);
        canvas.drawPath(
          arch,
          Paint()
            ..color = scheme.secondary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round,
        );
        for (final x in [20.0, 40.0, 60.0, 80.0]) {
          final y = (x == 20 || x == 80) ? 48.0 : 30.0;
          box(Rect.fromLTWH(x - 6, y, 12, 13), scheme.surface, 3);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GameArtworkPainter old) =>
      old.kind != kind || old.theme != theme;
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
