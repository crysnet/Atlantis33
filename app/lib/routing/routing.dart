/// Cálculo de rutas del plan de caminata: A* sobre una rejilla de costos, perfiles, métricas y puntajes.
///
/// Es la versión en Dart de `tools/routing.py`. Las dos deben dar el mismo resultado;
/// `test/routing_golden_test.dart` lo comprueba contra la referencia de Python.
library;

export 'astar.dart';
export 'grid.dart';
export 'metrics.dart';
export 'model.dart';
export 'planner.dart';
