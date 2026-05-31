import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LocalSessionStore {
  static const _clientUidKey = 'ynot_client_uid';
  static const _phoneKey = 'ynot_client_phone';
  static const _mockSeedDisabledKey = 'ynot_mock_seed_disabled_after_wipe';

  Future<String> getOrCreateClientUid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_clientUidKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _generateUuidV4();
    await prefs.setString(_clientUidKey, created);
    return created;
  }

  Future<void> saveClientSession({
    required String clientUid,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientUidKey, clientUid);
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString(_phoneKey, phone);
    } else {
      await prefs.remove(_phoneKey);
    }
  }

  Future<String?> peekClientUid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_clientUidKey);
    if (existing == null || existing.isEmpty) {
      return null;
    }
    return existing;
  }

  Future<String?> peekPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_phoneKey);
    if (existing == null || existing.isEmpty) {
      return null;
    }
    return existing;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clientUidKey);
    await prefs.remove(_phoneKey);
  }

  Future<void> setMockSeedDisabledAfterWipe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_mockSeedDisabledKey, true);
    } else {
      await prefs.remove(_mockSeedDisabledKey);
    }
  }

  Future<bool> peekMockSeedDisabledAfterWipe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mockSeedDisabledKey) ?? false;
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-${hex.sublist(10, 16).join()}';
  }
}
