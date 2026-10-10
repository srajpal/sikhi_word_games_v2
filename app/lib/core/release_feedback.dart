import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version.dart' as release;

const feedbackEmail = 'khalsagamestudio.apps@gmail.com';
final feedbackUri = Uri(
  scheme: 'mailto',
  path: feedbackEmail,
  query:
      'subject=${Uri.encodeComponent('Sikhi Word Games feedback (${release.appVersionName}+${release.appBuildNumber})')}'
      '&body=${Uri.encodeComponent('${release.appVersionLabel}\n\nGame:\nLanguage:\nDevice/browser:\n\nFeedback:\n')}',
);

Future<void> showReleaseFeedback(
  BuildContext context, {
  Future<bool> Function(Uri)? openEmail,
}) => showDialog<void>(
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
        SelectableText(release.appVersionLabel),
        SizedBox(height: 12),
        Text(
          'Email the developer. You can open your email app or copy the address.',
        ),
        SizedBox(height: 8),
        SelectableText(feedbackEmail),
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
            await Clipboard.setData(const ClipboardData(text: feedbackEmail));
            if (!context.mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            messenger.showSnackBar(
              const SnackBar(content: Text('Email address copied.')),
            );
          } on Object {
            if (!context.mounted) return;
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Copy the email address manually'),
                content: const Text(
                  'Copying is unavailable in this browser. '
                  'Select the email address in the feedback window to copy it.',
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
        child: const Text('Copy email address'),
      ),
      TextButton.icon(
        onPressed: () async {
          try {
            final opened =
                await (openEmail?.call(feedbackUri) ??
                    launchUrl(
                      feedbackUri,
                      mode: LaunchMode.externalApplication,
                    ));
            if (!context.mounted) return;
            if (opened) {
              Navigator.pop(context);
              return;
            }
          } on Object {
            // The selectable address still works without a registered mail app.
          }
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email app unavailable'),
              scrollable: true,
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copy the address and send feedback from your email app '
                    'or website.',
                  ),
                  SizedBox(height: 12),
                  SelectableText(feedbackEmail),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.email_outlined),
        label: const Text('Email feedback'),
      ),
    ],
  ),
);
