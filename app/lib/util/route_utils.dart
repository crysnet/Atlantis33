import 'dart:math' as math;

import '../routing/routing.dart';

/// Distancia acumulada en metros a lo largo del camino, celda por celda.
List<double> alongRoute(RouteGrid g, List<int> cells) {
  final d = List<double>.filled(cells.length, 0.0);
  for (var i = 1; i < cells.length; i++) {
    final a = cells[i - 1], b = cells[i];
    final diag = (a ~/ g.width != b ~/ g.width) && (a % g.width != b % g.width);
    d[i] = d[i - 1] + g.cellM * (diag ? math.sqrt2 : 1.0);
  }
  return d;
}

/// Posición de [cell] en el camino, o -1 si no pasa por ahí.
int indexOfCell(List<int> cells, int cell) => cells.indexOf(cell);
