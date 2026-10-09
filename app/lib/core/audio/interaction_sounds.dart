import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../features/settings/data/app_settings_repository.dart';

enum InteractionSound { letter, button }

/// App-owned, optional feedback for accepted actions, never raw pointer events.
/// Place above the Navigator so dialogs share the same preferences and players.
class InteractionSounds extends StatefulWidget {
  const InteractionSounds({
    required this.settings,
    required this.child,
    this.playSound,
    super.key,
  });

  final AppSettings settings;
  final Widget child;
  // Tests can observe requests without a platform speaker.
  final Future<void> Function(InteractionSound)? playSound;

  static void letter(BuildContext context) =>
      _request(context, InteractionSound.letter);
  static void button(BuildContext context) =>
      _request(context, InteractionSound.button);

  static void _request(BuildContext context, InteractionSound sound) {
    final state = context.findAncestorStateOfType<_InteractionSoundsState>();
    if (state != null) unawaited(state._play(sound));
  }

  static VoidCallback? buttonAction(
    BuildContext context,
    VoidCallback? action,
  ) => action == null
      ? null
      : () {
          button(context);
          action();
        };

  static VoidCallback? letterAction(
    BuildContext context,
    VoidCallback? action,
  ) => action == null
      ? null
      : () {
          letter(context);
          action();
        };

  static ValueChanged<T>? buttonChange<T>(
    BuildContext context,
    ValueChanged<T>? action,
  ) => action == null
      ? null
      : (value) {
          button(context);
          action(value);
        };

  @override
  State<InteractionSounds> createState() => _InteractionSoundsState();
}

class _InteractionSoundsState extends State<InteractionSounds>
    with WidgetsBindingObserver {
  final _players = <InteractionSound, AudioPlayer>{};
  final _generations = <InteractionSound, int>{};
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool _enabled(InteractionSound sound) => switch (sound) {
    InteractionSound.letter => widget.settings.letterClicks,
    InteractionSound.button => widget.settings.buttonClicks,
  };

  Future<void> _play(InteractionSound sound) async {
    if (!mounted || !_foreground || !_enabled(sound)) return;
    final generation = (_generations[sound] ?? 0) + 1;
    _generations[sound] = generation;
    try {
      if (widget.playSound case final play?) {
        await play(sound);
        return;
      }
      // Dedicated players keep clicks from stopping victory or pronunciation.
      final player = _players.putIfAbsent(sound, AudioPlayer.new);
      await player.stop();
      if (!mounted ||
          !_foreground ||
          !_enabled(sound) ||
          generation != _generations[sound]) {
        return;
      }
      await player.play(
        AssetSource('audio/${sound.name}_click.wav'),
        volume: .35,
        ctx: AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
    } on Object {
      // Muted devices and browser autoplay restrictions cannot block an action.
    }
  }

  void _stop(InteractionSound sound) {
    _generations[sound] = (_generations[sound] ?? 0) + 1;
    final player = _players[sound];
    if (player != null) unawaited(player.stop().catchError((Object _) {}));
  }

  @override
  void didUpdateWidget(InteractionSounds oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final sound in InteractionSound.values) {
      if (!_enabled(sound)) _stop(sound);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      for (final sound in InteractionSound.values) {
        _stop(sound);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final player in _players.values) {
      unawaited(player.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
