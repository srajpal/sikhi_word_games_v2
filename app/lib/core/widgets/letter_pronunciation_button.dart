import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'victory_celebration.dart';

/// Explicitly requested preview playback, separate from victory audio settings.
class LetterPronunciationButton extends StatefulWidget {
  const LetterPronunciationButton({
    required this.letterId,
    this.label = 'Hear letter name',
    super.key,
  });
  final String letterId;
  final String label;

  @override
  State<LetterPronunciationButton> createState() =>
      _LetterPronunciationButtonState();
}

class _LetterPronunciationButtonState extends State<LetterPronunciationButton>
    with WidgetsBindingObserver {
  static _LetterPronunciationButtonState? _active;
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  bool _playing = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _stop() async {
    _generation++;
    if (_active == this) _active = null;
    if (mounted && _playing) setState(() => _playing = false);
    try {
      await _player?.stop();
    } on Object {
      /* Playback is optional. */
    }
  }

  Future<void> _play() async {
    if (_playing) {
      await _stop();
      return;
    }
    VictoryCelebration.stop(context);
    final generation = ++_generation;
    setState(() {
      _playing = true;
      _failed = false;
    });
    final previous = _active;
    _active = this;
    if (previous != null && previous != this) await previous._stop();
    if (!mounted || generation != _generation) return;
    try {
      if (_player == null) {
        _player = AudioPlayer();
        _completion = _player!.onPlayerComplete.listen((_) {
          if (_active == this) _active = null;
          if (mounted) setState(() => _playing = false);
        });
      }
      await _player!.play(
        AssetSource('audio/learn_letters/${widget.letterId}.wav'),
      );
    } on Object {
      if (_active == this) _active = null;
      if (mounted && generation == _generation) {
        setState(() {
          _playing = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(LetterPronunciationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letterId != widget.letterId) {
      unawaited(_stop());
      _failed = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    if (_active == this) _active = null;
    unawaited(_completion?.cancel());
    final player = _player;
    if (player != null) unawaited(player.dispose().catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextButton.icon(
        onPressed: _play,
        icon: Icon(
          _playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
        ),
        label: Text(_playing ? 'Stop audio' : widget.label),
      ),
      if (_failed)
        Semantics(
          liveRegion: true,
          child: const Text('Audio could not play. Tap to retry.'),
        ),
    ],
  );
}
