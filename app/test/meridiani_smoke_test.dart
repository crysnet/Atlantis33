// Otro sitio (zona habitable de Meridiani, sin mediciones de radiación ni clima): todas las pestañas se dibujan
// con las aserciones activas, como en el modo desarrollo.
import 'package:ares_path/main.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('las pestañas se dibujan en el sitio de Meridiani', (tester) async {
    tester.view.physicalSize = const Size(2800, 1752);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.runAsync(() async {
      await tester.pumpWidget(const AresApp());
      await Future<void>.delayed(const Duration(seconds: 15));
    });
    await tester.pump();
    final model = AppScope.of(tester.element(find.byType(Scaffold).first));
    expect(model.siteId, 'meridiani_regional');
    expect(tester.takeException(), isNull, reason: 'carga inicial de Meridiani');
    expect(find.text('Indicative routes: the relief comes from a 200 m model, so local slopes are smoothed and the roughness is unknown. Use them as an approximation, not to avoid rocks or small slopes.'), findsOneWidget);
    // Todas las capas científicas y de tránsito encendidas, con la leyenda abierta.
    for (final id in ['transit', 'thermal_night', 'aqueous_pts', 'hydrous_pts', 'valleys', 'zones', 'names', 'craters']) {
      model.toggleLayer(id, true);
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'capas nuevas');
    expect(find.text('Transit zones (TES, 3.5 km per pixel)'), findsOneWidget);
    for (final tab in ['PLAN', 'SAFETY', 'SCIENCE']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final e = tester.takeException();
      expect(e, isNull, reason: 'Meridiani, pestaña $tab: $e');
      if (tab == 'SAFETY') {
        expect(find.textContaining('No radiation or weather measurements at this site'), findsOneWidget, reason: 'aviso de que no hay mediciones');
      }
    }

    // Fuentes: el diálogo se abre desde el pie de la pantalla y separa datos reales, calculados y supuestos.
    await tester.tap(find.text('SOURCES'));
    await tester.pumpAndSettle();
    expect(find.text('SOURCES AND DATA'), findsOneWidget);
    expect(find.text('REAL DATA'), findsOneWidget);
    expect(find.text('ASSUMPTIONS'), findsOneWidget);
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'diálogo de fuentes');
  });
}
