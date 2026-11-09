import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Saves the whole ledger as one JSON string in private app storage on the device.
class LedgerStore {
  static const _key = 'ledger_state';

  Future<LedgerState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LedgerState.initial();
    try {
      return LedgerState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return LedgerState.initial();
    }
  }

  Future<void> save(LedgerState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
