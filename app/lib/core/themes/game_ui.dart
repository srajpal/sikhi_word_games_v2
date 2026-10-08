import 'package:flutter/material.dart';

import 'app_theme.dart';

const gameSnackBarDuration = Duration(seconds: 5);

void showGameSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: gameSnackBarDuration,
        // Give screen-reader users time to hear and dismiss feedback.
        persist: MediaQuery.accessibleNavigationOf(context),
      ),
    );
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PaperPainter(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .045),
                  phulkari: tokens.sikhiStyle,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? tokens.panelGradient : null,
        borderRadius: tokens.panelRadius,
        border: Border.all(color: tokens.paperEdge),
        boxShadow: tokens.elevationShadow,
      ),
      child: child,
    );
  }
}

class GameStatusPill extends StatelessWidget {
  const GameStatusPill({required this.child, this.icon, super.key});

  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: tokens.controlRadius,
        border: Border.all(color: tokens.paperEdge),
        boxShadow: tokens.tileShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameGradientButton extends StatelessWidget {
  const GameGradientButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.prominent = true,
    super.key,
  });

  final bool prominent;
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final enabled = onPressed != null;
    final radius = tokens.controlRadius;
    final foreground = enabled
        ? prominent
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: .45);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled
            ? prominent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: enabled
              ? theme.colorScheme.primary.withValues(alpha: .35)
              : theme.colorScheme.outline.withValues(alpha: .35),
        ),
        boxShadow: enabled && prominent ? tokens.tileShadow : null,
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                child: IconTheme(
                  data: IconThemeData(color: foreground, size: 19),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 8)],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({required this.color, required this.phulkari});
  final Color color;
  final bool phulkari;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    // A fixed, sparse print texture. No random noise or animation during play.
    for (double y = 13; y < size.height; y += 27) {
      for (double x = 9; x < size.width; x += 31) {
        canvas.drawLine(Offset(x, y), Offset(x + 2, y + 1), p);
      }
    }
    if (!phulkari) return;
    for (double x = -size.height; x < size.width; x += 72) {
      for (double y = 0; y < size.height; y += 72) {
        final path = Path()
          ..moveTo(x + 18, y)
          ..lineTo(x + 36, y + 18)
          ..lineTo(x + 18, y + 36)
          ..lineTo(x, y + 18)
          ..close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phulkari != phulkari;
}
