import 'package:flutter/foundation.dart';

bool canUseGoogleMaps() {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
