import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sikhi_word_games_v2/core/themes/paper_assets.dart';

/// Captures must wait for image IO as well as scheduled animation frames.
Future<void> loadPaperAssets() async {
  for (final path in [
    PaperAssets.texture,
    ...GameArtworkKind.values.map(PaperAssets.scene),
  ]) {
    final stream = AssetImage(path).resolve(const ImageConfiguration());
    final loaded = Completer<void>();
    final listener = ImageStreamListener(
      (image, synchronous) => loaded.complete(),
      onError: (Object error, StackTrace? stack) =>
          loaded.completeError(error, stack),
    );
    stream.addListener(listener);
    await loaded.future;
    stream.removeListener(listener);
  }
}
