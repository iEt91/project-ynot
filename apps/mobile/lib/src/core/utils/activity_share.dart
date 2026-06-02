import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/activity.dart';
import 'formatters.dart';

String buildActivityShareText(Activity activity) {
  final title = safeDisplayText(activity.title, fallback: 'Actividad');
  final dateTime = formatTimeRange(activity.startTime, activity.endTime);
  final approxLocation = safeDisplayText(
    activity.zone,
    fallback: 'Ubicación aproximada',
  );

  return [
    'Mira esta actividad en Ynot: $title · $dateTime · $approxLocation',
    'ynot://activity/${activity.id}',
  ].join('\n');
}

Future<bool> shareActivityOrCopyFallback(
  BuildContext context,
  Activity activity,
) async {
  final text = buildActivityShareText(activity);
  try {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    if (result.status == ShareResultStatus.unavailable) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace copiado.')),
        );
      }
      return false;
    }
    return true;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace copiado.')),
      );
    }
    return false;
  }
}
