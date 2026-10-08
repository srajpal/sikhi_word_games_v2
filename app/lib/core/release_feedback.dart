import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_version.dart';

const feedbackUrl =
    'https://github.com/srajpal/sikhi_word_games_v2/issues/new/choose';

Future<void> showReleaseFeedback(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Share feedback'),
    scrollable: true,
    content: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tell us what happened, which game you played, and which word or '
          'definition needs a look. Include your browser and device.',
        ),
        SizedBox(height: 12),
        SelectableText(appVersionLabel),
        SizedBox(height: 12),
        Text(
          'Open the link below to post on GitHub. A GitHub account is needed. '
          'You can also leave feedback on the itch.io game page.',
        ),
        SizedBox(height: 8),
        SelectableText(feedbackUrl),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
      TextButton(
        onPressed: () async {
          try {
            await Clipboard.setData(const ClipboardData(text: feedbackUrl));
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            messenger.showSnackBar(
              const SnackBar(content: Text('Feedback link copied.')),
            );
          } on Object {
            if (!context.mounted) return;
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Copy the link manually'),
                content: const Text(
                  'Copying is unavailable in this browser. '
                  'Select the link in the feedback window to copy it.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          }
        },
        child: const Text('Copy feedback link'),
      ),
    ],
  ),
);
