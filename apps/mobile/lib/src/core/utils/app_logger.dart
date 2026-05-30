import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void log(String tag, [String? message]) {
    if (!kDebugMode) {
      return;
    }

    final prefix = '[YNOT][$tag]';
    if (message == null || message.isEmpty) {
      debugPrint(prefix);
      return;
    }

    final separator = message.startsWith('=') || message.startsWith(':') || message.startsWith('[') ? '' : ' ';
    debugPrint('$prefix$separator$message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }

    log('ERROR', message);
    if (error != null) {
      debugPrint('[YNOT][ERROR] error=$error');
    }
    if (stackTrace != null) {
      debugPrint('[YNOT][ERROR] stackTrace=$stackTrace');
    }
  }
}
