import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  static String _read(String key) {
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');
  static String get naverMapClientId =>
      _read('NAVER_MAP_CLIENT_ID');
  static bool get firebaseEnabled =>
      (_read('FIREBASE_ENABLED').isEmpty ? 'false' : _read('FIREBASE_ENABLED'))
              .toLowerCase() ==
          'true';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasNaverMapClientId => naverMapClientId.isNotEmpty;

  static bool get isDemoMode =>
      !hasSupabaseCredentials || !hasNaverMapClientId || !firebaseEnabled;
}
