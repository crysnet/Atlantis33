// El isolate de fondo da las mismas rutas que el cálculo en el hilo principal, y un pedido nuevo reemplaza al que espera.
import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/routing/route_worker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SiteData d;
  setUpAll(() async => d = await SiteData.load());

  test('el isolate da las mismas rutas que el hilo principal', () async {
    final req = PlanRequest(d.objectives);
    final direct = runPlan(d.grid, d.model, req);
    final w = RouteWorker(d.grid, d.model);
    final sw = Stopwatch()..start();
    final out = await w.run(req);
    // ignore: avoid_print
    print('isolate: ${sw.elapsedMilliseconds} ms');
    w.dispose();
    expect(out, isNotNull);
    expect(out!.routes.keys.toSet(), direct.routes.keys.toSet());
    for (final k in direct.routes.keys) {
      expect(out.routes[k]!.cells, direct.routes[k]!.cells, reason: k);
      expect(out.routes[k]!.status, direct.routes[k]!.status);
    }
  });

  test('un pedido nuevo reemplaza al que espera turno', () async {
    final w = RouteWorker(d.grid, d.model);
    final a = w.run(PlanRequest(d.objectives));
    final b = w.run(PlanRequest(d.objectives.take(2).toList()));
    final c = w.run(PlanRequest(d.objectives.take(3).toList()));
    expect(await b, isNull, reason: 'b esperaba turno y c lo reemplazó');
    expect(await a, isNotNull);
    expect(await c, isNotNull);
    w.dispose();
  });
}
