import 'dart:convert';

import 'package:flutter/services.dart';

class SiteEntry {
  const SiteEntry({
    required this.id,
    required this.assetDir,
    required this.available,
    required this.names,
    required this.layers,
    this.quality = 'high',
  });

  final String id;
  final String assetDir;
  final bool available;
  final Map<String, String> names;
  final List<String> layers;
  final String quality;

  bool get indicative => quality == 'indicative';
  bool get reach => quality == 'reach';

  String name(String lang) => names[lang] ?? names['en'] ?? id;

  factory SiteEntry.fromJson(Map<String, dynamic> j) => SiteEntry(
        id: j['id'] as String,
        assetDir: j['asset_dir'] as String,
        available: j['available'] as bool? ?? false,
        names: {
          for (final e in ((j['name'] as Map?) ?? const {}).entries)
            e.key.toString(): e.value.toString(),
        },
        layers: [
          for (final l in (j['layers'] as List? ?? const [])) l.toString(),
        ],
        quality: j['quality'] as String? ?? 'high',
      );
}

class SiteRegistry {
  const SiteRegistry({
    required this.defaultId,
    required this.sites,
  });

  static const SiteRegistry empty = SiteRegistry(defaultId: '', sites: []);

  final String defaultId;
  final List<SiteEntry> sites;

  SiteEntry? byId(String id) {
    for (final s in sites) {
      if (s.id == id) return s;
    }
    return null;
  }

  factory SiteRegistry.fromJson(Map<String, dynamic> j) {
    final defaultId = j['default'] as String? ?? '';
    final sites = [
      for (final s in (j['sites'] as List? ?? const []))
        SiteEntry.fromJson(s as Map<String, dynamic>),
    ];
    final reg = SiteRegistry(defaultId: defaultId, sites: sites);
    final def = reg.byId(defaultId);
    if (def == null || !def.available) {
      throw const FormatException('Default site not available');
    }
    return reg;
  }

  static Future<SiteRegistry> load([String asset = 'assets/sites.json']) async {
    final raw = await rootBundle.loadString(asset);
    return SiteRegistry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
