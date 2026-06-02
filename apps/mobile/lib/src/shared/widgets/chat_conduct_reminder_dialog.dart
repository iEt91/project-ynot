import 'package:flutter/material.dart';

import '../../app/theme.dart';

Future<bool> showChatConductReminderDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: YnotTheme.surface2,
        title: const Text('Cuidemos la buena vibra'),
        content: const Text(
          'Este chat es temporal y existe sólo para coordinar la actividad. Sé amable, evita spam y reporta cualquier situación incómoda.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
