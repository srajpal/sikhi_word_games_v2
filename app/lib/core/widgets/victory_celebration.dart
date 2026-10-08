import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../features/game_library/domain/game_launch_options.dart';
import '../../features/settings/data/app_settings_repository.dart';

/// A route-owned celebration. Games call this only for a newly earned win.
class VictoryCelebration extends StatefulWidget {
  const VictoryCelebration({
    required this.game,
    required this.settings,
    required this.onSettingsChanged,
    required this.child,
    this.playSound,
    super.key,
  });

  final GameKind game;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Widget child;
  // Allows tests to check sound requests without a platform audio device.
  final Future<void> Function()? playSound;

  static void celebrate(BuildContext context) =>
      context.findAncestorStateOfType<_VictoryCelebrationState>()?._celebrate();

  static void showSettings(BuildContext context) => context
      .findAncestorStateOfType<_VictoryCelebrationState>()
      ?._showSettings();

  static void stop(BuildContext context) =>
      context.findAncestorStateOfType<_VictoryCelebrationState>()?._stop();

  @override
  State<VictoryCelebration> createState() => _VictoryCelebrationState();
}

class _VictoryCelebrationState extends State<VictoryCelebration>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  AudioPlayer? _player;
  bool _visible = false;
  int _audioGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visible = false);
      }
    });
  }

  bool get _particlesAllowed =>
      widget.settings.victoryParticlesFor(widget.game) &&
      !MediaQuery.disableAnimationsOf(context);

  void _celebrate() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    if (widget.settings.victorySoundFor(widget.game)) {
      unawaited(_play());
    }
    if (_particlesAllowed) {
      setState(() => _visible = true);
      _animation.forward(from: 0);
    }
  }

  Future<void> _play() async {
    final generation = ++_audioGeneration;
    try {
      if (widget.playSound != null) {
        await widget.playSound!();
        return;
      }
      final player = _player ??= AudioPlayer();
      await player.stop();
      if (!mounted || generation != _audioGeneration) return;
      await player.play(AssetSource('audio/victory.wav'), volume: .55);
    } on Object {
      // Silent devices and browser autoplay restrictions never block a win.
    }
  }

  void _stop() {
    _audioGeneration++;
    _animation.stop();
    if (_visible && mounted) setState(() => _visible = false);
    final player = _player;
    if (player != null) unawaited(player.stop().catchError((Object _) {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void didUpdateWidget(VictoryCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.settings.victorySoundFor(widget.game) ||
        !widget.settings.victoryParticlesFor(widget.game)) {
      _stop();
    }
  }

  Future<void> _showSettings() async {
    _stop();
    var sound = !widget.settings.mutedVictoryGames.contains(widget.game.name);
    var particles = !widget.settings.quietVictoryGames.contains(
      widget.game.name,
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Celebration settings'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose how this game celebrates a win. Home App settings can turn these off for every game.',
              ),
              SwitchListTile(
                title: const Text('Victory sound'),
                value: sound,
                onChanged: (value) => update(() => sound = value),
              ),
              SwitchListTile(
                title: const Text('Victory particles'),
                subtitle: const Text(
                  'Respects Reduce motion and your device settings',
                ),
                value: particles,
                onChanged: (value) => update(() => particles = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      widget.onSettingsChanged(
        widget.settings.withGameVictory(
          widget.game,
          sound: sound,
          particles: particles,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioGeneration++;
    _animation.dispose();
    final player = _player;
    if (player != null) unawaited(player.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible && _particlesAllowed)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('victory-particles'),
                      painter: _VictoryPainter(_animation.value, [
                        colors.primary,
                        colors.tertiary,
                        colors.secondary,
                        colors.primaryContainer,
                        colors.tertiaryContainer,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_visible && _particlesAllowed)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 72,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Center(
                  child: Material(
                    color: colors.primaryContainer,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: colors.onPrimaryContainer,
                            size: 32,
                          ),
                          Text(
                            'You did it!',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: colors.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Three staggered colorful bursts, without flashes or a blocking modal.
class _VictoryPainter extends CustomPainter {
  _VictoryPainter(this.progress, this.colors);
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var burst = 0; burst < 3; burst++) {
      final time = (progress - burst * .13) / .74;
      if (time < 0 || time > 1) continue;
      final origin = Offset(
        size.width * [.25, .75, .5][burst],
        size.height * [.3, .36, .23][burst],
      );
      for (var particle = 0; particle < 36; particle++) {
        final angle = particle * math.pi * 2 / 36 + burst * .47;
        final speed = 70 + (particle * 37 % 110).toDouble();
        final radius = speed * (1 - math.pow(1 - time, 3));
        final center =
            origin +
            Offset(
              math.cos(angle) * radius,
              math.sin(angle) * radius + 120 * time * time,
            );
        paint.color = colors[(particle + burst) % colors.length].withValues(
          alpha: (1 - time) * .95,
        );
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle + time * 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 4 + particle % 3,
              height: 8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_VictoryPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
