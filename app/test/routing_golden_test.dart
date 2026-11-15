// Compara el cálculo de rutas en Dart con la referencia de Python (tools/05_rutas.py).
//
// Los archivos de `test/golden/` los escribe `tools/05_rutas.py`; se copian de `data/work/rutas/`.
// Regenerarlos cada vez que cambien `config/params.json`, `config/objectives.json` o los binarios de la rejilla:
//   cd tools && python3 05_rutas.py --cell 4 && cp ../data/work/rutas/rutas_4m.json ../app/test/golden/
//   cd tools && python3 05_rutas.py --cell 4 --modo rover && cp ../data/work/rutas/rutas_4m_rover.json ../app/test/golden/
//   (igual con --modo support, pair y objetivo; este último usa el campo transport de config/objectives.json)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ares_path/routing/routing.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJson(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

RouteGrid _loadGrid(Map<String, dynamic> site, double cellM) {
  final g = site['grid'] as Map<String, dynamic>;
  final h = site['habitat'] as Map<String, dynamic>;
  Uint8List read(String name) => File('assets/site_gale/grid/$name').readAsBytesSync();
  return RouteGrid.fromBytes(
    slopeBytes: read('slope.bin'),
    roughBytes: read('rough.bin'),
    forbiddenBytes: read('forbidden.bin'),
    elevBytes: read('elev.bin'),
    components: g['components'] as Map<String, dynamic>,
    baseWidth: g['width'] as int,
    baseHeight: g['height'] as int,
    baseCellM: (g['cell_m'] as num).toDouble(),
    habitatRow: h['row'] as int,
    habitatCol: h['col'] as int,
    cellM: cellM,
  );
}

void _expectClose(Object? actual, Object? expected, String path) {
  if (expected is num) {
    expect(actual, isA<num>(), reason: path);
    final a = (actual as num).toDouble();
    final e = expected.toDouble();
    expect((a - e).abs(), lessThanOrEqualTo(1e-6 * (e.abs() > 1.0 ? e.abs() : 1.0)), reason: '$path: $a != $e');
  } else if (expected is Map) {
    expect(actual, isA<Map>(), reason: path);
    expect((actual as Map).keys.toSet(), expected.keys.toSet(), reason: '$path: claves');
    for (final k in expected.keys) {
      _expectClose(actual[k], expected[k], '$path.$k');
    }
  } else if (expected is List) {
    expect(actual, isA<List>(), reason: path);
    expect((actual as List).length, expected.length, reason: '$path: largo');
    for (var i = 0; i < expected.length; i++) {
      _expectClose(actual[i], expected[i], '$path[$i]');
    }
  } else {
    expect(actual, expected, reason: path);
  }
}

void main() {
  final site = _readJson('assets/site_gale/site.json');
  final params = _readJson('assets/site_gale/params.json');
  final objectives = [
    for (final o in _readJson('assets/site_gale/objectives.json')['objectives'] as List) Objective.fromJson(o as Map<String, dynamic>),
  ];

  // Cada caso: tamaño de celda, archivo de referencia y modo (foot, rover, support, pair u objetivo).
  for (final (cell, file, mode) in [(4, 'rutas_4m', 'foot'), (4, 'rutas_4m_rover', 'rover'), (4, 'rutas_4m_support', 'support'), (4, 'rutas_4m_pair', 'pair'), (4, 'rutas_4m_objetivo', 'objetivo'), (2, 'rutas_2m', 'foot')]) {
    group('Dart igual que Python a ${cell}m ($mode)', () {
      final golden = _readJson('test/golden/$file.json');
      final grid = _loadGrid(site, cell.toDouble());
      final model = RoutingModel.fromParams(params, cellM: cell.toDouble());
      final planner = Planner(grid, model, objectives, withRover: mode == 'rover', withSupport: mode == 'support', byObjective: mode == 'objetivo');
      final routes = mode == 'pair' ? const <String, RouteResult>{} : planner.allThree();
      final expected = golden['routes'] as Map<String, dynamic>;

      test('misma rejilla', () {
        expect([grid.width, grid.height], golden['grid']);
        final hab = golden['habitat_cell'] as List;
        expect([grid.habitat % grid.width, grid.habitat ~/ grid.width], hab);
      });

      if (mode == 'pair') {
        test('pareja: misma asignación, caminos y resumen', () {
          final pr = planner.pair();
          expect(pr.status, golden['pair_status']);
          final want = golden['routes'] as Map<String, dynamic>;
          for (final name in ['pair1', 'pair2']) {
            final got = pr.routes[name]!.toJson(grid.width);
            expect(got['visited'], (want[name] as Map<String, dynamic>)['visited'], reason: '$name visita');
            expect(got['cells'], (want[name] as Map<String, dynamic>)['cells'], reason: '$name camino celda por celda');
            _expectClose(got, want[name], name);
          }
          _expectClose(pr.summary!.toJson(), golden['pair'], 'pair');
        });
        return;
      }
      for (final name in ['safe', 'fast', 'science']) {
        test('ruta $name', () {
          final got = routes[name]!.toJson(grid.width);
          final want = expected[name] as Map<String, dynamic>;
          expect(got['status'], want['status']);
          expect(got['visited'], want['visited']);
          expect(got['cells'], want['cells'], reason: 'camino celda por celda');
          _expectClose(got, want, name);
        });
      }
    });
  }
}
