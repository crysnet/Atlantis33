// La vista en perspectiva del Casco se dibuja sin errores en todos los sitios y en varios rumbos.
import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/widgets/terrain_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final dir in ['site_gale', 'site_meridiani_endeavour', 'site_meridiani_endeavour_reach', 'site_meridiani_habitat', 'site_meridiani_regional']) {
    testWidgets('$dir: se dibuja en cualquier rumbo', (tester) async {
      late SiteData d;
      await tester.runAsync(() async => d = await SiteData.load(dir));
      final (hx, hy) = (d.habitatX, d.habitatY);
      for (final heading in [0.0, 90.0, 200.0, 315.0]) {
        await tester.pumpWidget(MaterialApp(home: SizedBox(width: 800, height: 400, child: TerrainView(data: d, x: hx, y: hy, headingDeg: heading))));
        expect(tester.takeException(), isNull, reason: '$dir rumbo $heading');
      }
    });
  }

  testWidgets('fuera del mapa no falla', (tester) async {
    late SiteData d;
    await tester.runAsync(() async => d = await SiteData.load('site_meridiani_habitat'));
    await tester.pumpWidget(MaterialApp(home: SizedBox(width: 400, height: 200, child: TerrainView(data: d, x: -50, y: 10, headingDeg: 0))));
    expect(tester.takeException(), isNull);
  });
}
