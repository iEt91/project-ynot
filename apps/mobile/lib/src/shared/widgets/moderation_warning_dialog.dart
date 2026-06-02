import 'package:flutter/material.dart';

import '../../app/theme.dart';

Future<bool> showModerationWarningDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: YnotTheme.surface2,
        title: const Text('Revisar antes de continuar'),
        content: const Text(
          'Detectamos palabras sensibles. Puedes continuar, pero este contenido puede ser revisado por moderación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Editar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
