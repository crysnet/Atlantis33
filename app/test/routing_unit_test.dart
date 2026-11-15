// Pruebas unitarias del cálculo de rutas con terreno sintético. Reflejan tools/test_routing.py.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ares_path/routing/routing.dart';
import 'package:flutter_test/flutter_test.dart';

Float64List _flat(int w, int h, [double v = 0.0]) => Float64List(w * h)..fillRange(0, w * h, v);

void main() {
  final params = jsonDecode(File('assets/site_gale/params.json').readAsStringSync()) as Map<String, dynamic>;
  final model = RoutingModel.fromParams(params);
  final fast = model.profiles['fast']!;
  final safe = model.profiles['safe']!;

  test('en llano plano el camino es la diagonal', () {
    final grid = RouteGrid.synthetic(width: 20, height: 20, slope: _flat(20, 20));
    final r = astar(grid, model, fast, 0, 19 * 20 + 19)!;
    expect(r.cells.length, 20);
    final factor = 1.0 + fast.wTime * (model.maxSpeedFactor / model.speedFactor(0.0) - 1.0);
    expect(r.cost, closeTo(19 * 2.0 * math.sqrt(2.0) * factor, 1e-6));
  });

  test('rodea las celdas prohibidas', () {
    final s = _flat(15, 15);
    for (var r = 0; r < 12; r++) {
      s[r * 15 + 7] = 40.0;
    }
    final grid = RouteGrid.synthetic(width: 15, height: 15, slope: s);
    for (final name in ['safe', 'fast', 'science']) {
      final r = astar(grid, model, model.profiles[name]!, 0, 14);
      expect(r, isNotNull, reason: name);
      expect(r!.cells.every((c) => grid.blocked[c] == 0), isTrue, reason: name);
    }
  });

  test('sin camino devuelve null', () {
    final s = _flat(10, 10);
    for (var r = 0; r < 10; r++) {
      s[r * 10 + 5] = 40.0;
    }
    final grid = RouteGrid.synthetic(width: 10, height: 10, slope: s);
    expect(astar(grid, model, fast, 0, 9), isNull);
  });

  test('no corta la esquina entre dos celdas prohibidas', () {
    final s = _flat(3, 3);
    s[0 * 3 + 1] = 40.0;
    s[1 * 3 + 0] = 40.0;
    final grid = RouteGrid.synthetic(width: 3, height: 3, slope: s);
    expect(astar(grid, model, fast, 0, 4), isNull);
  });

  test('el perfil seguro tiene un límite de pendiente más bajo', () {
    final s = _flat(10, 10);
    for (var r = 0; r < 10; r++) {
      s[r * 10 + 5] = 23.0;
    }
    final grid = RouteGrid.synthetic(width: 10, height: 10, slope: s);
    expect(astar(grid, model, fast, 0, 9), isNotNull);
    expect(astar(grid, model, safe, 0, 9), isNull);
  });

  test('subir cuesta más que bajar', () {
    final z = Float64List(5 * 20);
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 20; c++) {
        z[r * 20 + c] = c * 0.5;
      }
    }
    final grid = RouteGrid.synthetic(width: 20, height: 5, slope: _flat(20, 5), z: z);
    final up = astar(grid, model, fast, 2 * 20, 2 * 20 + 19)!;
    final down = astar(grid, model, fast, 2 * 20 + 19, 2 * 20)!;
    expect(up.cost, greaterThan(down.cost));
  });

  test('métricas de un tramo llano con una parada', () {
    final grid = RouteGrid.synthetic(width: 11, height: 1, slope: _flat(11, 1));
    final m = evaluate(grid, model, List.generate(11, (i) => i), {10: 0.5});
    expect(m.distanceM, closeTo(20.0, 1e-9));
    expect(m.walkH, closeTo(20.0 / (2000.0 * model.speedFactor(0.0)), 1e-9));
    expect(m.stopH, closeTo(0.5, 1e-12));
    expect(m.mNominal, closeTo(20.0, 1e-9));
    expect(m.ascentM, 0.0);
  });

  test('los puntajes quedan entre 0 y 100', () {
    final grid = RouteGrid.synthetic(width: 11, height: 1, slope: _flat(11, 1));
    final m = evaluate(grid, model, List.generate(11, (i) => i), {10: 0.5});
    final (hz, ex) = computeScores(m, 5.0, 10.0, model);
    expect(hz.score, inInclusiveRange(0.0, 100.0));
    expect(ex.score, inInclusiveRange(0.0, 100.0));
    expect(ex.scienceValue, closeTo(0.5, 1e-12));
  });
}
