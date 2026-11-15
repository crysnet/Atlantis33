// Mide el tiempo del cálculo de rutas en la versión web (y en cualquier plataforma).
//
// Construir y abrir en Chrome:
//   flutter build web --release --target lib/bench/bench_main.dart
//   (servir build/web y abrir la página; al terminar muestra "DONE")
import 'dart:convert';
import 'dart:typed_data';

import 'package:ares_path/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(const _BenchApp());

class _BenchApp extends StatefulWidget {
  const _BenchApp();

  @override
  State<_BenchApp> createState() => _BenchAppState();
}

class _BenchAppState extends State<_BenchApp> {
  final List<String> _lines = ['running'];

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _log(String s) {
    // ignore: avoid_print
    print('BENCH $s');
    setState(() => _lines.add(s));
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final site = jsonDecode(await rootBundle.loadString('assets/site_gale/site.json')) as Map<String, dynamic>;
    final params = jsonDecode(await rootBundle.loadString('assets/site_gale/params.json')) as Map<String, dynamic>;
    final objJson = jsonDecode(await rootBundle.loadString('assets/site_gale/objectives.json')) as Map<String, dynamic>;
    final objectives = [for (final o in objJson['objectives'] as List) Objective.fromJson(o as Map<String, dynamic>)];
    final g = site['grid'] as Map<String, dynamic>;
    final h = site['habitat'] as Map<String, dynamic>;
    Future<Uint8List> read(String n) async => (await rootBundle.load('assets/site_gale/grid/$n')).buffer.asUint8List();
    final slope = await read('slope.bin');
    final rough = await read('rough.bin');
    final forb = await read('forbidden.bin');
    final elev = await read('elev.bin');
    for (final cell in [8.0, 4.0, 2.0]) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final sw = Stopwatch()..start();
      final grid = RouteGrid.fromBytes(
        slopeBytes: slope,
        roughBytes: rough,
        forbiddenBytes: forb,
        elevBytes: elev,
        components: g['components'] as Map<String, dynamic>,
        baseWidth: g['width'] as int,
        baseHeight: g['height'] as int,
        baseCellM: (g['cell_m'] as num).toDouble(),
        habitatRow: h['row'] as int,
        habitatCol: h['col'] as int,
        cellM: cell,
      );
      final tGrid = sw.elapsedMilliseconds;
      final model = RoutingModel.fromParams(params, cellM: cell);
      sw
        ..reset()
        ..start();
      final planner = Planner(grid, model, objectives);
      final routes = planner.allThree();
      final tAll = sw.elapsedMilliseconds;
      // Un cambio típico del usuario: se mueve un objetivo y se recalcula con los tramos ya guardados.
      final planner2 = Planner(grid, model, objectives);
      sw
        ..reset()
        ..start();
      final one = planner2.primary('fast');
      final tOne = sw.elapsedMilliseconds;
      _log('cell ${cell}m grid ${grid.width}x${grid.height}: load $tGrid ms; all three routes $tAll ms '
          '(${planner.searches} A* searches); fast route alone $tOne ms; '
          'science visits ${routes['science']!.visited}; safe ${routes['safe']!.status}; fast ${one.status}');
    }
    _log('DONE');
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SelectableText(_lines.join('\n')))),
      );
}
