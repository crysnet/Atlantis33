// Gale con el alcance de la EVA (24 km, rejilla de 16 m): carga, terreno transitable y cálculo de rutas de largo alcance.
import 'dart:io';

import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/site_registry.dart';
import 'package:ares_path/routing/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SiteData d;
  setUpAll(() async => d = await SiteData.load('site_gale_reach'));

  test('carga con el tamaño, la rejilla y el recorrido real de Curiosity', () {
    expect(d.sizeM, 24000);
    expect(d.grid.cellM, 16);
    expect(d.grid.width, 1500);
    expect(d.curiosity.length, greaterThan(1000));
    expect(d.roverPhotos, isNotEmpty);
    expect(File('assets/site_gale_reach/rover/${d.roverPhotos.values.first.file}').existsSync(), isTrue);
    expect(d.context!.sizeM, greaterThan(d.sizeM));
    expect(d.environment.rad, isNotEmpty, reason: 'es el mismo cráter: RAD y REMS valen');
  });

  test('trae el mapa base de toda la región de Gale', () async {
    expect(d.base!.assetDir, 'base_gale');
    expect(File('assets/base_gale/0/0/0.jpg').existsSync(), isTrue);
    final g4 = await SiteData.load();
    expect(g4.base!.assetDir, 'base_gale', reason: 'el sitio de 4 km usa el mismo mapa base');
  });

  test('el hábitat y los objetivos están en terreno transitable', () {
    expect(d.isBlocked(d.habitatX, d.habitatY), isFalse);
    expect(d.objectives.length, greaterThanOrEqualTo(5));
    for (final o in d.objectives) {
      expect(d.isBlocked(o.xM, o.yM), isFalse, reason: o.id);
    }
  });

  test('las rutas de largo alcance se calculan; el objetivo lejano se alcanza a pie o en vehículo', () {
    final sw = Stopwatch()..start();
    final routes = Planner(d.grid, d.model, d.objectives).allThree();
    final ms = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('Gale 24 km: tres rutas en $ms ms (VM de pruebas, no la tablet)');
    for (final r in routes.values) {
      // ignore: avoid_print
      print('  ${r.profile}: ${r.status}, visita ${r.visited}, ${r.metrics == null ? '' : '${r.metrics!.distanceM.round()} m, ${r.metrics!.totalH.toStringAsFixed(2)} h, O2 ${(r.metrics!.o2RemainingFrac * 100).round()} %'}, omitidos ${r.skipped.where((s) => s['reason'] != 'not_primary').map((s) => '${s['id']}:${s['reason']}').toList()}');
      expect(['ok', 'not_feasible'], contains(r.status), reason: r.profile);
      expect(r.cells, isNotEmpty);
    }
    final far = Planner(d.grid, d.model, d.objectives, byObjective: true).primary('fast');
    expect(far.metrics, isNotNull);
    expect(far.transport, isNotNull);
  });

  test('el registro marca este sitio como de largo alcance', () async {
    final r = await SiteRegistry.load();
    final e = r.byId('gale_reach')!;
    expect(e.reach, isTrue);
    expect(e.indicative, isFalse);
    expect(e.available, isTrue);
  });
}
