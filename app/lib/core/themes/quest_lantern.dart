import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_ui.dart';

/// A secular paper lantern: one lit fold for each remaining miss allowance.
class QuestLantern extends StatelessWidget {
  const QuestLantern({
    required this.missesLeft,
    required this.maximumMisses,
    required this.won,
    super.key,
  });
  final int missesLeft;
  final int maximumMisses;
  final bool won;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Paper lantern, $missesLeft of $maximumMisses lights remaining',
      child: GamePanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 82,
                height: 84,
                child: CustomPaint(
                  painter: _LanternPainter(
                    colors,
                    missesLeft,
                    maximumMisses,
                    won,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    won ? 'You kept the light!' : 'Keep the light',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A missed letter dims one fold. Correct letters keep it glowing.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ExcludeSemantics(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (var i = 0; i < maximumMisses; i++)
                          Icon(
                            i < missesLeft
                                ? Icons.light_mode
                                : Icons.light_mode_outlined,
                            size: 17,
                            color: i < missesLeft
                                ? colors.secondary
                                : colors.outline,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  const _LanternPainter(this.colors, this.left, this.total, this.won);
  final ColorScheme colors;
  final int left;
  final int total;
  final bool won;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final body = Rect.fromCenter(center: center, width: 64, height: 57);
    canvas.drawOval(
      body.inflate(9),
      Paint()
        ..color = colors.secondary.withValues(
          alpha: won ? .24 : .12 * left / total,
        ),
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, 13),
      Paint()
        ..color = colors.primary
        ..strokeWidth = 2,
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(body, const Radius.circular(24)));
    for (var i = 0; i < total; i++) {
      final fold = Rect.fromLTWH(
        body.left + body.width * i / total,
        body.top,
        body.width / total + 1,
        body.height,
      );
      canvas.drawRect(
        fold,
        Paint()
          ..color = Color.lerp(
            colors.surfaceContainerHighest,
            colors.secondaryContainer,
            i < left || won ? .95 : .1,
          )!,
      );
      canvas.drawLine(
        Offset(fold.left, body.top),
        Offset(fold.left, body.bottom),
        Paint()
          ..color = colors.secondary.withValues(alpha: .35)
          ..strokeWidth = 1,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(24)),
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final y in [body.top, body.bottom]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, y), width: 28, height: 5),
          const Radius.circular(2),
        ),
        Paint()..color = colors.primary,
      );
    }
    if (won) {
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi / 5 - math.pi / 2;
        final r = i.isEven ? 11.0 : 5.0;
        final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) {
          p.moveTo(point.dx, point.dy);
        } else {
          p.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(p..close(), Paint()..color = colors.primary);
    }
    canvas.drawLine(
      Offset(center.dx, body.bottom + 2),
      Offset(center.dx, size.height),
      Paint()
        ..color = colors.secondary
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LanternPainter old) =>
      old.left != left ||
      old.total != total ||
      old.won != won ||
      old.colors != colors;
}
