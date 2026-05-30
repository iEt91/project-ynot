import '../core/utils/app_logger.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    AppLogger.log('BOOT', 'mode=mock');
  }
}
