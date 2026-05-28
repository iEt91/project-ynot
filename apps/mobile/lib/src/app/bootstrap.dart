import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../core/config/app_environment.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    if (!AppEnvironment.hasNaverMapClientId) {
      return;
    }

    if (kIsWeb) {
      return;
    }

    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    await FlutterNaverMap().init(
      clientId: AppEnvironment.naverMapClientId,
    );
  }
}
