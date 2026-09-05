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
        // SnackBar actions default to persistent in Flutter. The game-wide
        // feedback contract keeps the action but still times out.
        persist: false,
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
        children: [
          if (tokens.sikhiStyle)
            Positioned.fill(
              child: CustomPaint(
                painter: _PhulkariPainter(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .07),
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
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<GameThemeTokens>()!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: tokens.panelGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
        ),
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
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: tokens.elevationShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
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
    super.key,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? tokens.panelGradient : null,
        color: enabled ? null : theme.colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: enabled
              ? theme.colorScheme.primary.withValues(alpha: .35)
              : theme.colorScheme.outline.withValues(alpha: .35),
        ),
        boxShadow: enabled
            ? [
                ...tokens.elevationShadow,
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .18),
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: .45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhulkariPainter extends CustomPainter {
  _PhulkariPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
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
  bool shouldRepaint(covariant _PhulkariPainter oldDelegate) =>
      oldDelegate.color != color;
}
