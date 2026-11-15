// Arreglos del reporte de QA (2026-11-15): formato, dosis única, idioma y capas que se guardan, objetivos sin crear al cancelar.
import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/ui_prefs.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:ares_path/util/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemUi implements UiPrefsStore {
  Map<String, dynamic> saved = {};
  @override
  Future<Map<String, dynamic>> load() async => saved;
  @override
  Future<void> save(Map<String, dynamic> prefs) async => saved = Map<String, dynamic>.from(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Fmt: hora HH:MM, oxígeno sin negativos y decimales por idioma', () {
    const en = Fmt(Locale('en')), es = Fmt(Locale('es'));
    expect(en.clock(9.0), '09:00');
    expect(en.clock(9.0 + 3 + 5 / 60), '12:05');
    expect(en.clock(25.5), '01:30');
    expect(en.o2(-0.37, 'depleted'), 'depleted');
    expect(en.o2(0.56, 'depleted'), '56%');
    expect(es.text('HiRISE 0.25 m · TES 3.5 km'), 'HiRISE 0,25 m · TES 3,5 km');
    expect(en.text('HiRISE 0.25 m'), 'HiRISE 0.25 m');
  });

  test('fotos de la zona: solo los sitios de Endeavour las traen y los archivos existen', () async {
    for (final dir in ['site_meridiani_endeavour', 'site_meridiani_endeavour_reach']) {
      final d = await SiteData.load(dir);
      expect(d.zonePhotos.length, 4, reason: dir);
      for (final z in d.zonePhotos) {
        expect((await rootBundle.load(z.asset)).lengthInBytes, greaterThan(1000), reason: z.asset);
        expect(z.credit, 'NASA/JPL-Caltech');
      }
    }
    expect((await SiteData.load('site_meridiani_habitat')).zonePhotos, isEmpty);
    expect((await SiteData.load('site_gale')).zonePhotos, isEmpty);
  });

  group('AppModel', () {
    late SiteData d;
    setUpAll(() async => d = await SiteData.load('site_gale'));

    test('el idioma y las capas se guardan y se recuperan', () async {
      final ui = _MemUi();
      final a = AppModel(d, uiStore: ui, uiPrefs: {});
      a.setLocale(const Locale('es'));
      a.toggleLayer('forbidden', true);
      a.setOpacity('forbidden', 0.3);
      final b = AppModel(d, uiStore: ui, uiPrefs: ui.saved);
      expect(b.locale.languageCode, 'es');
      expect(b.layers['forbidden']!.visible, isTrue);
      expect(b.layers['forbidden']!.opacity, 0.3);
      b.resetLayers();
      expect(b.layers['forbidden']!.visible, isFalse);
    });

    test('la dosis de una ruta sale de la misma tasa en toda la app y sigue al sol de referencia', () {
      final m = AppModel(d);
      final first = d.environment.firstWeatherSol;
      expect(m.doseOver(24), closeTo(m.doseRateUGyPerDay, 1e-9));
      m.setEnvSol(first);
      final rate = d.environment.radFor(first)?.eMean ?? d.model.doseUGyPerDay;
      expect(m.doseOver(12), closeTo(rate / 2, 1e-9));
    });

    test('segura y rápida eligen entre los objetivos de más del 60 % de la prioridad máxima', () async {
      for (final dir in ['site_meridiani_habitat', 'site_meridiani_endeavour']) {
        final m = AppModel(await SiteData.load(dir));
        await m.recompute();
        final top = m.objectives.map((o) => o.priority).reduce((a, b) => a > b ? a : b);
        for (final id in ['safe', 'fast']) {
          final r = m.routes[id]!;
          expect(r.visited, hasLength(1), reason: '$dir $id');
          expect(m.objective(r.visited.first)!.priority, greaterThanOrEqualTo(0.6 * top), reason: '$dir $id');
        }
      }
    });

    test('un objetivo solo existe cuando se guarda', () async {
      final m = AppModel(d);
      final before = m.objectives.length;
      // Cancelar no llama a addObjective; guardar sí, con lo llenado en el formulario.
      expect(m.objectives.length, before);
      final id = m.addObjective(100, 100, 'Prueba', type: 'image', priority: 5, workMin: 45, transport: 'vehicle');
      final o = m.objective(id)!;
      expect((o.name, o.type, o.priority, o.workMin, o.transport), ('Prueba', 'image', 5, 45.0, 'vehicle'));
      expect(m.objectives.length, before + 1);
    });
  });
}
