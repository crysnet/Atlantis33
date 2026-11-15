import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la interfaz que sobreviven a recargar la app: idioma y capas visibles (con su opacidad) de cada sitio.
/// Forma: `{"lang": "es", "layers": {"<sitio>": {"<capa>": [visible, opacidad]}}}`.
abstract class UiPrefsStore {
  Future<Map<String, dynamic>> load();
  Future<void> save(Map<String, dynamic> prefs);
}

class PrefsUiStore implements UiPrefsStore {
  static const key = 'ares_ui_v1';

  @override
  Future<Map<String, dynamic>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return {};
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, dynamic> prefs) async {
    try {
      await (await SharedPreferences.getInstance()).setString(key, jsonEncode(prefs));
    } catch (_) {
      // Sin almacenamiento: la app sigue sin recordar estas preferencias.
    }
  }
}
