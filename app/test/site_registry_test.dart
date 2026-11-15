// Registro de sitios (`assets/sites.json`) y cambio de sitio en el modelo.
import 'dart:convert';
import 'dart:io';

import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/site_registry.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SiteRegistry _readRegistry() =>
    SiteRegistry.fromJson(jsonDecode(File('assets/sites.json').readAsStringSync()) as Map<String, dynamic>);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el registro es válido: el sitio por defecto existe y su carpeta tiene los datos', () {
    final r = _readRegistry();
    final def = r.byId(r.defaultId)!;
    expect(def.available, isTrue);
    for (final s in r.sites.where((s) => s.available)) {
      for (final f in ['site.json', 'params.json', 'objectives.json', 'grid/slope.bin']) {
        expect(File('assets/${s.assetDir}/$f').existsSync(), isTrue, reason: '${s.id} sin $f');
      }
    }
    // Los ids de capa del registro existen en el catálogo de la app.
    final known = kLayers.map((l) => l.id).toSet();
    for (final s in r.sites) {
      expect(known.containsAll(s.layers), isTrue, reason: 'capas desconocidas en ${s.id}');
    }
    expect(r.sites.map((s) => s.id).toSet().length, r.sites.length, reason: 'ids repetidos');
  });

  test('el nombre cae al inglés y luego al id', () {
    const s = SiteEntry(id: 'x', assetDir: 'site_x', available: false, names: {'en': 'Site X'}, layers: []);
    expect(s.name('es'), 'Site X');
    expect(s.name('en'), 'Site X');
    const t = SiteEntry(id: 'y', assetDir: 'site_y', available: false, names: {}, layers: []);
    expect(t.name('es'), 'y');
  });

  test('un registro con el sitio por defecto no disponible se rechaza', () {
    expect(
      () => SiteRegistry.fromJson({
        'default': 'a',
        'sites': [
          {'id': 'a', 'asset_dir': 'site_a', 'available': false, 'name': {'en': 'A'}},
        ],
      }),
      throwsFormatException,
    );
  });

  test('cambiar de sitio: los no disponibles o desconocidos se rechazan y el actual se queda', () async {
    final registry = _readRegistry();
    final data = await SiteData.load(registry.byId(registry.defaultId)!.assetDir);
    final m = AppModel(data, registry: registry, siteId: registry.defaultId);
    expect(m.siteId, registry.defaultId);
    expect(m.siteLabel, 'Gale · Boxwork ridges');
    m.setLocale(const Locale('es'));
    expect(m.siteLabel, 'Gale · Crestas boxwork');
    expect(m.layerDefs.map((l) => l.id), registry.byId(registry.defaultId)!.layers);

    final conPendiente = SiteRegistry.fromJson({
      'default': registry.defaultId,
      'sites': [
        ...[for (final s in registry.sites) {'id': s.id, 'asset_dir': s.assetDir, 'available': s.available, 'name': s.names, 'layers': s.layers}],
        {'id': 'sin_datos', 'asset_dir': 'site_sin_datos', 'available': false, 'name': {'en': 'Pending'}},
      ],
    });
    final m2 = AppModel(data, registry: conPendiente, siteId: registry.defaultId);
    expect(await m2.switchSite('sin_datos'), isFalse);
    expect(m2.siteId, registry.defaultId);
    m2.dispose();
    final pending = registry.sites.firstWhere((s) => s.id == 'meridiani_habitat');
    expect(pending.indicative, isTrue);
    expect(registry.byId('meridiani_endeavour')!.indicative, isFalse);
    expect(await m.switchSite('no_existe'), isFalse);
    expect(m.siteId, registry.defaultId);
    expect(identical(m.data, data), isTrue);
    expect(m.switchingSite, isFalse);

    // Abrir el sitio ya abierto no recarga nada.
    expect(await m.switchSite(registry.defaultId), isTrue);
    expect(identical(m.data, data), isTrue);
  });

  test('sin registro, el modelo muestra todas las capas', () async {
    final m = AppModel(await SiteData.load());
    expect(m.layerDefs.length, kLayers.length);
    expect(m.siteLabel, isNull);
  });
}
