import 'package:flutter/material.dart';

enum GameArtworkKind { deduction, search, garden, bridges, letters }

/// Hand-drawn paper objects share the theme palette, never puzzle answers.
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
    final ink = scheme.primary;
    final paper = scheme.surface;
    final accent = scheme.secondaryContainer;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    void line(Offset a, Offset b, Color color, [double width = 1.5]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = color
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    void box(Rect rect, Color color, [double radius = 3]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(2, 3)),
          Radius.circular(radius),
        ),
        Paint()..color = scheme.onSurface.withValues(alpha: .15),
      );
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.drawRRect(
        shape,
        Paint()
          ..color = scheme.onSurface.withValues(alpha: .24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }

    void text(
      String value,
      Offset at,
      double fontSize,
      Color color, {
      bool gurmukhi = false,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: gurmukhi ? 'NotoSansGurmukhi' : 'NotoSans',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, at);
      painter.dispose();
    }

    void book(double x, double y, double width, Color cover) {
      box(Rect.fromLTWH(x, y, width, 12), cover, 2);
      box(Rect.fromLTWH(x + 3, y + 2, width - 6, 7), paper, 1);
      line(
        Offset(x + 7, y + 5),
        Offset(x + width - 6, y + 5),
        scheme.outlineVariant,
        .7,
      );
    }

    // Cut-paper oval and a restrained sprig give each object a common stage.
    canvas.drawOval(
      const Rect.fromLTWH(5, 10, 90, 82),
      Paint()..color = accent.withValues(alpha: .7),
    );
    line(const Offset(84, 81), const Offset(90, 30), colors.stem, 1.7);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(87 + i * .7, 67 - i * 10);
      canvas.rotate(i.isEven ? -.6 : .65);
      canvas.drawOval(
        const Rect.fromLTWH(-1, -7, 11, 7),
        Paint()..color = colors.leaf,
      );
      canvas.restore();
    }
    switch (kind) {
      case GameArtworkKind.deduction:
        book(18, 78, 62, ink);
        book(11, 65, 64, scheme.secondary);
        book(22, 52, 58, colors.sun);
        canvas.save();
        canvas.translate(13, 24);
        canvas.rotate(-.12);
        for (var i = 0; i < 4; i++) {
          box(Rect.fromLTWH(i * 19.0, 0, 17, 24), paper);
          text('BOOK'[i], Offset(i * 19.0 + 3, 3), 15, ink);
        }
        canvas.restore();
      case GameArtworkKind.search:
        canvas.save();
        canvas.translate(12, 15);
        canvas.rotate(-.08);
        box(const Rect.fromLTWH(0, 0, 60, 66), paper);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            if (row == 1) {
              box(Rect.fromLTWH(6 + col * 17.0, 24, 15, 17), accent, 2);
            }
            text(
              'KHOJPLAYA'[row * 3 + col],
              Offset(8 + col * 17.0, 8 + row * 18.0),
              11,
              ink,
            );
          }
        }
        canvas.restore();
        line(const Offset(65, 68), const Offset(82, 87), scheme.secondary, 7);
        canvas.drawCircle(
          const Offset(57, 56),
          18,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        canvas.drawCircle(
          const Offset(57, 56),
          14,
          Paint()..color = paper.withValues(alpha: .25),
        );
      case GameArtworkKind.garden:
        book(13, 78, 68, ink);
        box(const Rect.fromLTWH(15, 25, 36, 43), paper);
        text('?', const Offset(25, 27), 27, ink);
        for (final at in [const Offset(64, 27), const Offset(45, 48)]) {
          line(Offset(at.dx, 78), at, colors.stem, 2);
          canvas.drawOval(
            Rect.fromLTWH(at.dx - 15, at.dy + 15, 15, 7),
            Paint()..color = colors.leaf,
          );
          for (final offset in [
            const Offset(-5, 0),
            const Offset(5, 0),
            const Offset(0, -5),
            const Offset(0, 5),
          ]) {
            canvas.drawCircle(at + offset, 5, Paint()..color = colors.sun);
          }
          canvas.drawCircle(at, 3, Paint()..color = scheme.secondary);
        }
      case GameArtworkKind.bridges:
        box(const Rect.fromLTWH(8, 17, 74, 66), paper);
        for (var i = 0; i < 3; i++) {
          final y = 27 + i * 18.0;
          line(
            Offset(31, y + 5),
            Offset(57, 68 - i * 18.0),
            i == 1 ? scheme.secondary : ink,
            2,
          );
          box(Rect.fromLTWH(15, y, 20, 11), accent, 2);
          box(Rect.fromLTWH(56, y, 20, 11), scheme.primaryContainer, 2);
          line(Offset(19, y + 5), Offset(30, y + 5), ink, 1);
          line(Offset(60, y + 5), Offset(71, y + 5), ink, 1);
        }
      case GameArtworkKind.letters:
        book(13, 78, 67, ink);
        canvas.save();
        canvas.translate(13, 20);
        canvas.rotate(-.12);
        box(const Rect.fromLTWH(0, 0, 38, 52), accent);
        text('ਅ', const Offset(5, 6), 29, ink, gurmukhi: true);
        canvas.restore();
        canvas.save();
        canvas.translate(46, 30);
        canvas.rotate(.12);
        box(const Rect.fromLTWH(0, 0, 38, 52), paper);
        text('ਕ', const Offset(5, 6), 29, ink, gurmukhi: true);
        canvas.restore();
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
    : sky = theme.colorScheme.surface,
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
