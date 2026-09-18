import 'package:flutter/material.dart';

Future<void> showResetAppDataDialog(
  BuildContext context, {
  required Future<void> Function() onReset,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ResetAppDataDialog(onReset: onReset),
);

class _ResetAppDataDialog extends StatefulWidget {
  const _ResetAppDataDialog({required this.onReset});
  final Future<void> Function() onReset;
  @override
  State<_ResetAppDataDialog> createState() => _ResetAppDataDialogState();
}

class _ResetAppDataDialogState extends State<_ResetAppDataDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _reset() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.onReset();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('App data reset. Ready for a fresh start.'),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Reset all app data?'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This deletes all saved games, statistics, word history, game preferences, settings and tutorial progress on this device or browser. This cannot be undone.',
          ),
          const SizedBox(height: 12),
          const Text(
            'The word lists and offline app files stay available. Every game will show its first-launch guide again.',
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(semanticsLabel: 'Resetting app data'),
          ],
          if (_failed) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                'Reset could not finish. Some data may have been cleared. Try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(_failed ? 'Close' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _busy ? null : _reset,
          child: Text(_busy ? 'Resetting...' : 'Reset all data'),
        ),
      ],
    ),
  );
}
