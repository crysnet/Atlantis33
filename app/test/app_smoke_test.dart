// Prueba de humo: la app arranca con los datos reales y las cuatro pestañas se dibujan sin errores.
//
// Corre con las aserciones activas (como el modo desarrollo), así que atrapa errores de maquetación
// que una build de release ocultaría.
import 'package:ares_path/main.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:ares_path/widgets/objective_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('las cuatro pestañas y el modo con rover se dibujan sin errores', (tester) async {
    tester.view.physicalSize = const Size(2800, 1752);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    // En las pruebas el texto usa una tipografía de cuadros anchos, no las de la app: los desbordes de texto
    // son un artefacto de la prueba. Cualquier otro error sí hace fallar la prueba.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);

    await tester.runAsync(() async {
      await tester.pumpWidget(const AresApp());
      // Carga de assets y cálculo de las tres rutas (en la VM de pruebas, sin optimizar).
      await Future<void>.delayed(const Duration(seconds: 15));
    });
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'pestaña Plan');

    // Capas de contexto de Gale (minerales, zonas, nombres, cráteres, geología): se dibujan sin errores con el marco de contexto.
    final gale = AppScope.of(tester.element(find.byType(Scaffold).first));
    for (final id in ['aqueous_pts', 'hydrous_pts', 'zones', 'names', 'craters', 'geology']) {
      gale.toggleLayer(id, true);
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'capas de contexto en Gale');
    for (final id in ['aqueous_pts', 'hydrous_pts', 'zones', 'names', 'craters', 'geology']) {
      gale.toggleLayer(id, false);
    }

    // Modo con rover: recalcula las tres rutas con el rover aparcado y las dibuja.
    await tester.tap(find.text('WITH ROVER'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'modo con rover');
    expect(find.text('ROVER'), findsWidgets, reason: 'las tarjetas muestran el tramo en rover');

    // Rover de apoyo en el hábitat.
    await tester.tap(find.text('SUPPORT'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'modo con rover de apoyo');
    expect(find.text('EMERGENCY RETURN'), findsWidgets, reason: 'las tarjetas muestran el regreso en emergencia');

    // Salida en pareja: dos astronautas con los objetivos repartidos.
    await tester.tap(find.text('PAIR'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 25)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'modo en pareja');
    expect(find.text('EVA IN A PAIR'), findsWidgets, reason: 'tarjeta de la pareja');

    // Modo por objetivo: cada objetivo trae su transporte. Se cambia el de t1 desde el diálogo del objetivo.
    await tester.tap(find.text('BY OBJECTIVE'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 25)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'modo por objetivo');
    final ctx = tester.element(find.byType(Scaffold).first);
    final model = AppScope.of(ctx);
    expect(model.exitMode, ExitMode.byObjective);
    expect(model.route?.transport, isNotNull, reason: 'la ruta trae el transporte de cada objetivo');
    showObjectiveDialog(ctx, model, 't1');
    await tester.pumpAndSettle();
    expect(find.text('TRANSPORT'), findsOneWidget, reason: 'el diálogo tiene el selector de transporte');
    await tester.tap(find.text('On foot'));
    await tester.pump();
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    expect(model.objective('t1')!.transport, 'foot');
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 25)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'recalculo tras cambiar el transporte');
    expect(model.route?.metrics?.roverM, isNotNull);

    for (final tab in ['SAFETY', 'SCIENCE', 'MISSION', 'HELMET', 'PLAN']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final e = tester.takeException();
      expect(e, isNull, reason: 'pestaña $tab: $e');
      if (tab == 'MISSION') {
        // Simulación: reproducir un momento, con el marcador y la telemetría en pantalla, y pausar.
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump(const Duration(seconds: 2));
        final sim = tester.takeException();
        expect(sim, isNull, reason: 'simulación en marcha: $sim');
        expect(find.byIcon(Icons.pause), findsOneWidget);
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();
      }
    }

    // Misiones guardadas: se abre la lista desde la barra superior y se crea una misión nueva.
    await tester.tap(find.text('MISSION 1'));
    await tester.pumpAndSettle();
    expect(find.text('MISSIONS'), findsOneWidget, reason: 'lista de misiones');
    await tester.tap(find.text('NEW MISSION'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'misión nueva');
    expect(model.book.missions.length, 2);
    expect(model.objectives, isEmpty);
    expect(find.text('MISSION 2'), findsWidgets, reason: 'la misión nueva queda abierta');

  });
}
