import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mission.dart';

abstract class MissionStore {
  Future<MissionBook?> load();
  Future<void> save(MissionBook book);
}

class MemoryMissionStore implements MissionStore {
  String? _raw;

  @override
  Future<MissionBook?> load() async {
    if (_raw == null) return null;
    return MissionBook.fromJson(jsonDecode(_raw!) as Map<String, dynamic>);
  }

  @override
  Future<void> save(MissionBook book) async {
    _raw = jsonEncode(book.toJson());
  }
}

class PrefsMissionStore implements MissionStore {
  static const String key = 'ares_missions_v1';
  static const String corruptKey = 'ares_missions_v1_corrupt';

  @override
  Future<MissionBook?> load() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('MissionBook root is not a JSON object');
      }
      return MissionBook.fromJson(decoded);
    } catch (_) {
      await prefs.setString(corruptKey, raw);
      await prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> save(MissionBook book) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(book.toJson()));
    } catch (_) {}
  }
}
