// Las dos ventanas locales de Meridiani (F4): los assets cargan, el hábitat y los objetivos caen en terreno transitable
// y el cálculo de rutas funciona sobre ellas.
import 'dart:io';

import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/site_registry.dart';
import 'package:ares_path/routing/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (dir, size, baseCell, routeCell, indicative) in [('site_meridiani_endeavour', 4000.0, 2.0, 4.0, false), ('site_meridiani_habitat', 20000.0, 100.0, 100.0, true), ('site_meridiani_regional', 100000.0, 400.0, 400.0, true), ('site_meridiani_endeavour_reach', 22000.0, 16.0, 16.0, false)]) {
    group(dir, () {
      late SiteData d;
      setUpAll(() async => d = await SiteData.load(dir));

      test('carga con el tamaño y la rejilla esperados', () {
        expect(d.sizeM, size);
        expect(((d.site['grid'] as Map<String, dynamic>)['cell_m'] as num).toDouble(), baseCell);
        expect(d.grid.cellM, routeCell);
        expect(d.assetDir, dir);
        // recorrido de Opportunity: todos los sitios de Meridiani lo traen salvo la zona habitable (Opportunity nunca pasó por ahí)
        expect(d.curiosity.isEmpty, dir.endsWith('habitat'));
        expect(d.roverPhotos, isEmpty);
        expect(d.tileCount, dir.endsWith('habitat') ? 3 : (dir.endsWith('regional') ? 4 : 5));
        expect(d.tileSizeM(0), closeTo(d.tileSizeM(1) * 2, 1e-6));
      });

      test('sin mediciones de radiación ni clima, y la interfaz lo sabe', () {
        expect(d.environment.rad, isEmpty);
        expect(d.environment.weather, isEmpty);
        expect(d.environment.radFor(d.environment.referenceSol), isNull);
        expect(d.environment.weatherFor(d.environment.referenceSol), isNull);
      });

      test('el hábitat y los objetivos están en terreno transitable', () {
        expect(d.isBlocked(d.habitatX, d.habitatY), isFalse);
        expect(d.objectives, isNotEmpty);
        for (final o in d.objectives) {
          expect(d.isBlocked(o.xM, o.yM), isFalse, reason: o.id);
          expect(['foot', 'vehicle', 'hybrid'], contains(o.transport));
        }
        expect(d.elevationAt(d.habitatX, d.habitatY), isNotNull);
      });

      test('trae las capas de F5: minerales y zonas en coordenadas locales del sitio', () {
        final v = d.vectors;
        for (final q in v.minerals) {
          final c = d.context!;
          expect(q.x, inInclusiveRange(c.x, c.x + c.sizeM));
          expect(['sulfate', 'phyllosilicate', 'hydrous'], contains(q.cls));
        }
        for (final z in v.zones) {
          expect(z.ring != null || (z.x != null && z.y != null), isTrue, reason: z.type);
        }
        if (!dir.contains('endeavour')) {
          expect(v.zones.where((z) => z.type == 'habitation'), isNotEmpty, reason: 'la zona habitable de EZMars');
        }
        if (dir.endsWith('regional')) expect(v.minerals.length, greaterThan(5));
      });

      test('trae el marco de contexto y los rasgos de F5b', () {
        final c = d.context!;
        expect(c.sizeM, greaterThan(size * 1.5), reason: 'el marco cubre mucho más que la ventana');
        expect(c.x, lessThan(0));
        expect(c.y, lessThan(0));
        expect(c.tileMPerPx.length, c.maxZoom + 1);
        expect(File('assets/$dir/context/0/0/0.jpg').existsSync(), isTrue);
        expect(d.vectors.craters, isNotEmpty);
        expect(d.vectors.areas, isNotEmpty, reason: 'unidades geológicas');
        for (final a in d.vectors.areas) {
          expect(a.rings, isNotEmpty);
        }
      });

      test('trae el mapa base de toda la región, compartido', () {
        final b = d.base!;
        expect(b.assetDir, 'base_meridiani');
        expect(b.sizeM, 327680);
        expect(b.sizeM, greaterThan(d.context!.sizeM));
        expect(File('assets/${b.assetDir}/0/0/0.jpg').existsSync(), isTrue);
        expect(File('assets/${b.assetDir}/4/8/8.jpg').existsSync(), isTrue);
      });

      test('las capas y las teselas existen', () {
        final site = d.site;
        expect((site['quality'] == 'indicative'), indicative);
        for (final z in List.generate(d.tileCount, (i) => i)) {
          expect(d.assetPath('ortho/$z/0/0.jpg'), contains(dir));
        }
      });
    });
  }

  test('zona habitable: las tres rutas se calculan y la de ciencia visita algo', () async {
    final d = await SiteData.load('site_meridiani_habitat');
    final planner = Planner(d.grid, d.model, d.objectives);
    final routes = planner.allThree();
    for (final r in routes.values) {
      expect(['ok', 'not_feasible'], contains(r.status), reason: r.profile);
      expect(r.cells, isNotEmpty);
    }
    expect(routes['science']!.visited, isNotEmpty);
    // el modo por objetivo funciona sobre esta rejilla
    final byObjective = Planner(d.grid, d.model, d.objectives, byObjective: true).science();
    expect(byObjective.transport, isNotNull);
  });

  test('Endeavour: la ruta segura llega al objetivo de mayor prioridad', () async {
    final d = await SiteData.load('site_meridiani_endeavour');
    final r = Planner(d.grid, d.model, d.objectives).primary('safe');
    expect(['ok', 'not_feasible'], contains(r.status));
    expect(r.visited, isNotEmpty);
    expect(r.metrics!.distanceM, greaterThan(500));
  });

  test('el registro marca la zona habitable como indicativa', () async {
    final r = await SiteRegistry.load();
    expect(r.byId('meridiani_habitat')!.indicative, isTrue);
    expect(r.byId('meridiani_endeavour')!.available, isTrue);
  });
}
