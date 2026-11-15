import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mission.dart';

/// Dónde se guardan las misiones. Todo queda en el dispositivo: no hay servidor.
abstract class MissionStore {
  /// Las misiones guardadas, o null si no hay ninguna (o no se pueden leer).
  Future<MissionBook?> load();

  Future<void> save(MissionBook book);
}

/// Guarda en memoria; para pruebas.
class MemoryMissionStore implements MissionStore {
  MemoryMissionStore([this.json]);

  String? json;

  @override
  Future<MissionBook?> load() async => json == null ? null : MissionBook.fromJson(jsonDecode(json!) as Map<String, dynamic>);

  @override
  Future<void> save(MissionBook book) async => json = jsonEncode(book.toJson());
}

/// Guarda en las preferencias del dispositivo (`shared_preferences`): en Android, el almacenamiento privado de la app.
class PrefsMissionStore implements MissionStore {
  static const key = 'ares_missions_v1';
  static const corruptKey = 'ares_missions_v1_corrupt';

  @override
  Future<MissionBook?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      try {
        return MissionBook.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Datos ilegibles: se guarda una copia aparte para no perderlos y se empieza de cero.
        await prefs.setString(corruptKey, raw);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(MissionBook book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(book.toJson()));
    } catch (_) {
      // Sin almacenamiento disponible: la app sigue funcionando sin guardar.
    }
  }
}
