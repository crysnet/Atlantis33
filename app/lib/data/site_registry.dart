import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Un sitio del registro (`assets/sites.json`).
class SiteEntry {
  const SiteEntry({required this.id, required this.assetDir, required this.available, required this.names, required this.layers, this.quality = 'high'});

  factory SiteEntry.fromJson(Map<String, dynamic> j) => SiteEntry(
        id: j['id'] as String,
        assetDir: j['asset_dir'] as String,
        available: (j['available'] as bool?) ?? false,
        names: {for (final e in (j['name'] as Map<String, dynamic>).entries) e.key: e.value as String},
        layers: [for (final l in (j['layers'] as List? ?? const [])) l as String],
        quality: (j['quality'] as String?) ?? 'high',
      );

  final String id;

  /// Carpeta dentro de `assets/`.
  final String assetDir;

  /// Falso mientras los datos del sitio no están preparados.
  final bool available;

  /// Nombre por idioma (`en`, `es`).
  final Map<String, String> names;

  /// Ids de capa del panel para este sitio; vacío = todas las de `kLayers`.
  final List<String> layers;

  /// `high`, `indicative` (relieve grueso: rutas solo indicativas) o `reach` (largo alcance, rejilla de 16 m).
  final String quality;

  bool get indicative => quality == 'indicative';

  /// Sitio de largo alcance: rejilla de 16 m sobre un relieve real; no ve obstáculos pequeños.
  bool get reach => quality == 'reach';

  /// Nombre en el idioma dado; si falta, el inglés y, si no, el id.
  String name(String languageCode) => names[languageCode] ?? names['en'] ?? id;
}

/// Lista de sitios y sitio por defecto.
class SiteRegistry {
  const SiteRegistry({required this.defaultId, required this.sites});

  factory SiteRegistry.fromJson(Map<String, dynamic> j) {
    final sites = [for (final s in j['sites'] as List) SiteEntry.fromJson(s as Map<String, dynamic>)];
    final def = j['default'] as String;
    if (!sites.any((s) => s.id == def && s.available)) {
      throw FormatException('El sitio por defecto "$def" no existe o no está disponible en sites.json');
    }
    return SiteRegistry(defaultId: def, sites: sites);
  }

  static Future<SiteRegistry> load() async =>
      SiteRegistry.fromJson(jsonDecode(await rootBundle.loadString('assets/sites.json')) as Map<String, dynamic>);

  /// Registro con un solo sitio, para pruebas o si no hay `sites.json`.
  static const SiteRegistry empty = SiteRegistry(defaultId: '', sites: []);

  final String defaultId;
  final List<SiteEntry> sites;

  SiteEntry? byId(String id) {
    for (final s in sites) {
      if (s.id == id) return s;
    }
    return null;
  }
}
