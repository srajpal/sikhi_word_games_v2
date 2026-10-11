import 'package:flutter/widgets.dart';

/// Submit the destination's loading frame before a cached Future can resume
/// CPU-heavy preparation in the same build/microtask turn. The event-loop yield
/// also gives the web renderer a chance to present that frame.
Future<void> showGameLoadingFrame() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(Duration.zero);
}
