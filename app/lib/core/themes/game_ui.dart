import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'paper_assets.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: PaperTexture()),
        child,
      ],
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
        image: DecorationImage(
          image: const AssetImage(PaperAssets.texture),
          repeat: ImageRepeat.repeat,
          scale: 2,
          colorFilter: ColorFilter.mode(
            color ?? Theme.of(context).colorScheme.surface,
            BlendMode.modulate,
          ),
          opacity: .45,
        ),
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
    this.semanticLabel,
    this.compact = false,
    this.iconTrailing = false,
    super.key,
  });

  final bool compact;
  final bool iconTrailing;
  final String? semanticLabel;
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
        gradient: enabled && prominent
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(theme.colorScheme.primary, Colors.white, .07)!,
                  theme.colorScheme.primary,
                  Color.lerp(theme.colorScheme.primary, Colors.black, .15)!,
                ],
              )
            : null,
        color: !enabled
            ? theme.colorScheme.surfaceContainerHighest
            : !prominent
            ? theme.colorScheme.surface
            : null,
        borderRadius: radius,
        border: Border.all(
          color: enabled
              ? theme.colorScheme.surface.withValues(alpha: .85)
              : theme.colorScheme.outline.withValues(alpha: .35),
          width: 1.5,
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
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 18,
                  vertical: 11,
                ),
                child: IconTheme(
                  data: IconThemeData(color: foreground, size: 19),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null && !iconTrailing) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          semanticsLabel: semanticLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                      ),
                      if (icon != null && iconTrailing) ...[
                        const SizedBox(width: 8),
                        icon!,
                      ],
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

/// Real paper fibers, tinted centrally for the three app themes.
class PaperTexture extends StatelessWidget {
  const PaperTexture({this.panel = false, super.key});
  final bool panel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<GameThemeTokens>()!;
    final tint = panel
        ? theme.colorScheme.surface
        : tokens.backgroundGradient.colors.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        image: DecorationImage(
          image: const AssetImage(PaperAssets.texture),
          repeat: ImageRepeat.repeat,
          scale: 2,
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          opacity: theme.brightness == Brightness.dark
              ? .55
              : panel
              ? .5
              : .7,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Deterministic deckled edges keep labels tactile without animating texture.
class PaperLabel extends StatelessWidget {
  const PaperLabel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => PhysicalShape(
    clipper: const _PaperEdge(),
    color: Theme.of(context).colorScheme.surface,
    shadowColor: const Color(0x33372B1A),
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned.fill(child: PaperTexture(panel: true)),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class _PaperEdge extends CustomClipper<Path> {
  const _PaperEdge();
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(3, 4);
    const offsets = [2.0, 0.0, 3.0, 1.0, 2.5, .5];
    for (var i = 0; i <= 24; i++) {
      path.lineTo(3 + (size.width - 6) * i / 24, offsets[i % offsets.length]);
    }
    for (var i = 0; i <= 16; i++) {
      path.lineTo(
        size.width - offsets[i % offsets.length],
        3 + (size.height - 6) * i / 16,
      );
    }
    for (var i = 24; i >= 0; i--) {
      path.lineTo(
        3 + (size.width - 6) * i / 24,
        size.height - offsets[i % offsets.length],
      );
    }
    for (var i = 16; i >= 0; i--) {
      path.lineTo(offsets[i % offsets.length], 3 + (size.height - 6) * i / 16);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_PaperEdge oldClipper) => false;
}
