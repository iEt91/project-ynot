import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  static String _read(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.env[key] ?? '';
  }

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');
  static String get googleMapsApiKey => _read('GOOGLE_MAPS_API_KEY');
  static bool get firebaseEnabled =>
      (_read('FIREBASE_ENABLED').isEmpty ? 'false' : _read('FIREBASE_ENABLED'))
              .toLowerCase() ==
          'true';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;

  static bool get isDemoMode => true;
}
