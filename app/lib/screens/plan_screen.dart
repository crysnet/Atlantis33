import 'package:flutter/material.dart';

import '../widgets/layers_panel.dart';
import '../widgets/map_view.dart';
import '../widgets/profile_chart.dart';
import '../widgets/route_panel.dart';

/// Pantalla principal: capas a la izquierda, mapa con perfil al centro y comparación de rutas a la derecha.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 1100;
      final left = compact ? 240.0 : 280.0;
      final right = compact ? 320.0 : 360.0;
      return Row(children: [
        SizedBox(width: left, child: const LayersPanel()),
        const VerticalDivider(width: 1),
        const Expanded(
          child: Column(children: [
            Expanded(child: MapView()),
            ProfileChart(),
          ]),
        ),
        const VerticalDivider(width: 1),
        SizedBox(width: right, child: const RoutePanel()),
      ]);
    });
  }
}
