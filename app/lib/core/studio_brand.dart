import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const studioName = 'Khalsa Game Studio';
const studioDomain = 'khalsagamestudio.com';
final studioUri = Uri.https(studioDomain);

class StudioWebsiteLink extends StatelessWidget {
  const StudioWebsiteLink({this.openUrl, super.key});

  final Future<bool> Function(Uri)? openUrl;

  Future<void> _open(BuildContext context) async {
    try {
      final opened =
          await (openUrl?.call(studioUri) ??
              launchUrl(studioUri, mode: LaunchMode.externalApplication));
      if (opened) return;
    } on Object {
      // Keep the address available when no browser can be opened.
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(studioName),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open this address in your browser to visit the studio.',
            ),
            const SizedBox(height: 12),
            SelectableText(studioUri.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Visit $studioName in your browser',
    child: TextButton(
      onPressed: () => _open(context),
      child: const Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [Text(studioDomain), Icon(Icons.open_in_new, size: 16)],
      ),
    ),
  );
}
