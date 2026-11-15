import 'dart:math' as math;

import 'astar.dart';
import 'grid.dart';
import 'metrics.dart';
import 'model.dart';

/// Objetivo científico. Coordenadas locales en metros: x al este, y al sur desde la esquina noroeste del recuadro.
class Objective {
  const Objective({
    required this.id,
    required this.name,
    required this.type,
    required this.priority,
    required this.workMin,
    required this.xM,
    required this.yM,
    this.transport = 'foot',
  });

  factory Objective.fromJson(Map<String, dynamic> j) => Objective(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? j['id'] as String,
        type: (j['type'] as String?) ?? 'sample',
        priority: (j['priority'] as num).toInt(),
        workMin: (j['work_min'] as num).toDouble(),
        xM: (j['x_m'] as num).toDouble(),
        yM: (j['y_m'] as num).toDouble(),
        transport: (j['transport'] as String?) ?? 'foot',
      );

  final String id;
  final String name;
  final String type;
  final int priority;
  final double workMin;
  final double xM;
  final double yM;

  /// Cómo se llega al objetivo: `foot` (a pie), `vehicle` (en vehículo) o `hybrid` (vehículo hasta donde se pueda y
  /// el resto a pie). Solo cuenta en el modo por objetivo.
  final String transport;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'priority': priority,
        'work_min': workMin,
        'x_m': xM,
        'y_m': yM,
        'transport': transport,
      };

  Objective copyWith({String? name, String? type, int? priority, double? workMin, double? xM, double? yM, String? transport}) => Objective(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        workMin: workMin ?? this.workMin,
        xM: xM ?? this.xM,
        yM: yM ?? this.yM,
        transport: transport ?? this.transport,
      );
}

/// Resultado de una ruta: el camino, sus métricas y sus dos puntajes.
class RouteResult {
  const RouteResult({
    required this.profile,
    required this.status,
    required this.visited,
    required this.skipped,
    this.weightedCost = 0.0,
    this.cells = const [],
    this.metrics,
    this.hazard,
    this.success,
    this.transport,
  });

  final String profile;

  /// `ok`, `not_feasible`, `unreachable` o `no_target`.
  final String status;
  final List<String> visited;

  /// Objetivos que no entraron, cada uno con su motivo (`blocked`, `unreachable`, `time`, `oxygen`, `rover`, `margin`, `not_primary`).
  final List<Map<String, String>> skipped;
  final double weightedCost;

  /// Celdas del camino, índices planos de la rejilla.
  final List<int> cells;
  final RouteMetrics? metrics;
  final HazardScore? hazard;
  final SuccessScore? success;

  /// Solo en el modo por objetivo: transporte de cada objetivo visitado y avisos (`notes`: `id` y `reason`).
  final Map<String, dynamic>? transport;

  Map<String, dynamic> toJson(int gridWidth) => {
        'profile': profile,
        'status': status,
        'visited': visited,
        'skipped': skipped,
        if (cells.isNotEmpty) 'weighted_cost': weightedCost,
        'cells': [for (final c in cells) [c % gridWidth, c ~/ gridWidth]],
        if (metrics != null) 'metrics': metrics!.toJson(),
        if (hazard != null) 'hazard': hazard!.toJson(),
        if (success != null) 'success': success!.toJson(),
        if (transport != null) 'transport': transport,
      };
}

class _Obj {
  _Obj(this.o, this.idx, this.blocked);

  final Objective o;
  final int idx;
  final bool blocked;
}

class _Plan {
  _Plan(this.cost, this.order, this.cells, this.metrics, this.stops, [this.notes]);

  final Map<int, double> stops;

  /// Avisos del transporte por objetivo; null en los otros modos.
  final List<Map<String, String?>>? notes;

  final double cost;
  final List<String> order;
  final List<int> cells;
  final RouteMetrics metrics;
}

class _Armada {
  _Armada(this.cost, this.cells, this.stops);

  final double cost;
  final List<int> cells;
  final Map<int, double> stops;
}

/// Itera las permutaciones en el mismo orden que `itertools.permutations`.
Iterable<List<T>> _permutations<T>(List<T> items) sync* {
  if (items.isEmpty) {
    yield <T>[];
    return;
  }
  for (var i = 0; i < items.length; i++) {
    final rest = [...items.sublist(0, i), ...items.sublist(i + 1)];
    for (final p in _permutations(rest)) {
      yield [items[i], ...p];
    }
  }
}

/// Calcula las tres rutas de una salida y guarda en memoria los tramos ya calculados.
/// Referencia: clase `Planificador` en tools/routing.py.
class Planner {
  Planner(this.grid, this.model, List<Objective> objectives, {this.withRover = false, this.withSupport = false, this.byObjective = false}) {
    for (final o in objectives) {
      final idx = grid.cellOf(o.xM, o.yM);
      _objs.add(_Obj(o, idx, grid.blocked[idx] != 0));
    }
    for (final e in _objs) {
      _byId[e.o.id] = e;
    }
    totalPriority = _objs.fold<double>(0.0, (a, e) => a + e.o.priority);
  }

  final RouteGrid grid;
  final RoutingModel model;

  /// Modo con rover: las rutas se evalúan con el rover aparcado en un punto de la ruta.
  final bool withRover;

  /// Modo con rover de apoyo: las rutas son a pie y un rover espera en el hábitat para una emergencia.
  final bool withSupport;

  /// Modo por objetivo: cada objetivo trae su transporte (`Objective.transport`).
  final bool byObjective;
  final List<_Obj> _objs = [];
  final Map<String, _Obj> _byId = {};
  late final double totalPriority;
  final Map<String, PathResult?> _legs = {};

  /// Cantidad de búsquedas A* hechas hasta ahora.
  int searches = 0;

  /// Mejor camino de [a] a [b]. Con [veh], solo por celdas que el vehículo puede recorrer (límites del rover).
  PathResult? _leg(String profile, int a, int b, [bool veh = false]) {
    final key = '$profile:$a:$b:$veh';
    if (!_legs.containsKey(key)) {
      searches++;
      final base = model.profiles[profile]!;
      _legs[key] = astar(grid, model, veh ? base.forVehicle(model.rover) : base, a, b);
    }
    return _legs[key];
  }

  /// En el modo por objetivo, el tramo hacia este objetivo se busca por celdas transitables para el vehículo.
  bool _veh(String? id) => byObjective && id != null && _byId[id]!.o.transport == 'vehicle';

  _Armada? _assemble(String profile, List<String> order) {
    final hab = grid.habitat;
    final points = [hab, for (final id in order) _byId[id]!.idx, hab];
    final cells = <int>[hab];
    final stops = <int, double>{};
    var cost = 0.0;
    for (var k = 0; k < points.length - 1; k++) {
      // El regreso al hábitat va en vehículo si el último objetivo se hizo en vehículo (el vehículo está ahí).
      final veh = _veh(k < order.length ? order[k] : (order.isNotEmpty ? order.last : null));
      var t = _leg(profile, points[k], points[k + 1], veh);
      if (t == null && veh) t = _leg(profile, points[k], points[k + 1]);
      if (t == null) return null;
      cost += t.cost;
      cells.addAll(t.cells.sublist(1));
      if (k < order.length) {
        stops[cells.length - 1] = _byId[order[k]]!.o.workMin / 60.0;
      }
    }
    return _Armada(cost, cells, stops);
  }

  List<List<String>> _bestOrders(String profile, List<String> ids) {
    final hab = grid.habitat;
    if (ids.length > 6) {
      final order = <String>[];
      var current = hab;
      final rest = [...ids];
      while (rest.isNotEmpty) {
        double cost(String i) => _leg(profile, current, _byId[i]!.idx, _veh(i))?.cost ?? double.infinity;
        var best = rest.first;
        var bestCost = cost(best);
        for (final i in rest.skip(1)) {
          final c = cost(i);
          if (c < bestCost) {
            best = i;
            bestCost = c;
          }
        }
        order.add(best);
        rest.remove(best);
        current = _byId[best]!.idx;
      }
      return [order];
    }
    final cands = <(double, int, List<String>)>[];
    var n = 0;
    for (final perm in _permutations(ids)) {
      final r = _assemble(profile, perm);
      if (r != null) cands.add((r.cost, n++, perm));
    }
    cands.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
    return [for (final c in cands) c.$3];
  }

  _Plan? _route(String profile, List<String> ids) {
    _Plan? best;
    for (final order in _bestOrders(profile, ids)) {
      final armada = _assemble(profile, order);
      if (armada == null) continue;
      final RouteMetrics m;
      List<Map<String, String?>>? notes;
      if (byObjective) {
        final r = objectiveRoverSteps(grid, model, armada.cells, armada.stops, [for (final id in order) (id, _byId[id]!.o.transport)]);
        m = evaluate(grid, model, armada.cells, armada.stops, roverSteps: r.steps, modeLabel: 'objective', roverOk: !r.stranded);
        notes = r.notes;
      } else {
        m = evaluate(grid, model, armada.cells, armada.stops, rover: withRover ? roverLegs(grid, model, armada.cells, armada.stops) : null, support: withSupport);
      }
      best ??= _Plan(armada.cost, order, armada.cells, m, armada.stops, notes);
      if (m.feasible) return _Plan(armada.cost, order, armada.cells, m, armada.stops, notes);
    }
    return best;
  }

  RouteResult _result(String profile, _Plan p, List<Map<String, String>> skipped) {
    final pri = p.order.fold<double>(0.0, (a, id) => a + _byId[id]!.o.priority);
    final (hz, ex) = computeScores(p.metrics, pri, totalPriority, model);
    return RouteResult(
      profile: profile,
      status: p.metrics.feasible ? 'ok' : 'not_feasible',
      visited: p.order,
      skipped: skipped,
      weightedCost: p.cost,
      cells: p.cells,
      metrics: p.metrics,
      hazard: hz,
      success: ex,
      transport: p.notes == null
          ? null
          : {
              'objectives': {for (final id in p.order) id: _byId[id]!.o.transport},
              'notes': p.notes,
            },
    );
  }

  /// Segura y rápida: van al objetivo de mayor prioridad y vuelven.
  RouteResult primary(String profile) {
    final free = _objs.where((e) => !e.blocked).toList();
    if (free.isEmpty) {
      return RouteResult(profile: profile, status: 'no_target', visited: const [], skipped: const []);
    }
    free.sort((a, b) {
      final c = b.o.priority.compareTo(a.o.priority);
      return c != 0 ? c : a.o.id.compareTo(b.o.id);
    });
    final o = free.first;
    final r = _route(profile, [o.o.id]);
    final omit = [
      for (final x in _objs)
        if (x.o.id != o.o.id) {'id': x.o.id, 'reason': x.blocked ? 'blocked' : 'not_primary'},
    ];
    if (r == null) {
      return RouteResult(
        profile: profile,
        status: 'unreachable',
        visited: const [],
        skipped: [...omit, {'id': o.o.id, 'reason': 'unreachable'}],
      );
    }
    return _result(profile, r, omit);
  }

  /// Ciencia: añade objetivos por prioridad mientras la salida siga siendo factible.
  ///
  /// Con `science_keep_comfort`, solo el primer objetivo exige factibilidad; los siguientes exigen además
  /// margen cómodo, para que la ruta no agote el tiempo y el oxígeno.
  RouteResult science([String profile = 'science']) {
    final chosen = <String>[];
    final omit = <Map<String, String>>[];
    final sorted = [..._objs]..sort((a, b) {
        final c = b.o.priority.compareTo(a.o.priority);
        return c != 0 ? c : a.o.id.compareTo(b.o.id);
      });
    for (final e in sorted) {
      if (e.blocked) {
        omit.add({'id': e.o.id, 'reason': 'blocked'});
        continue;
      }
      final r = _route(profile, [...chosen, e.o.id]);
      final needComfort = model.scienceKeepComfort && chosen.isNotEmpty;
      if (r == null) {
        omit.add({'id': e.o.id, 'reason': 'unreachable'});
      } else if (!r.metrics.feasible) {
        omit.add({'id': e.o.id, 'reason': !r.metrics.timeOk ? 'time' : (!r.metrics.o2Ok ? 'oxygen' : 'rover')});
      } else if (needComfort && !isComfortable(model, r.metrics)) {
        omit.add({'id': e.o.id, 'reason': 'margin'});
      } else {
        chosen.add(e.o.id);
      }
    }
    if (chosen.isEmpty) {
      return RouteResult(profile: profile, status: 'no_target', visited: const [], skipped: omit);
    }
    return _result(profile, _route(profile, chosen)!, omit);
  }

  /// Dos astronautas salen juntos y se reparten los objetivos, siempre a menos de `pairMaxSeparationM` uno del otro.
  /// Referencia: `pareja` en tools/routing.py (ahí está la descripción de la regla).
  PairResult pair([String profile = 'science']) {
    final free = [..._objs.where((e) => !e.blocked)]..sort((a, b) {
        final c = b.o.priority.compareTo(a.o.priority);
        return c != 0 ? c : a.o.id.compareTo(b.o.id);
      });
    final ids = [for (final e in free) e.o.id];
    final k = ids.length;
    final valid = <int, (_Plan, List<(double, double)>)>{};
    for (var mask = 1; mask < (1 << k); mask++) {
      final sub = [for (var i = 0; i < k; i++) if ((mask >> i) & 1 == 1) ids[i]];
      final r = _route(profile, sub);
      if (r == null || !r.metrics.feasible || (sub.length > 1 && !isComfortable(model, r.metrics))) continue;
      valid[mask] = (r, samplePositions(grid, model, r.cells, r.stops));
    }
    final masks = valid.keys.toList()..sort();
    double priorityOf(List<String> order) => order.fold<double>(0.0, (a, id) => a + _byId[id]!.o.priority);
    (double, double)? bestKey;
    (int, int, double, double, double, double, double, double)? best;
    for (var ia = 0; ia < masks.length; ia++) {
      for (var ib = ia; ib < masks.length; ib++) {
        final ma = masks[ia];
        final mb = masks[ib];
        final sep = maxSeparation(valid[ma]!.$2, valid[mb]!.$2);
        if (sep > model.pairMaxSeparationM) continue;
        final planA = valid[ma]!.$1;
        final planB = valid[mb]!.$1;
        final visited = {...planA.order, ...planB.order};
        final pri = visited.fold<double>(0.0, (a, id) => a + _byId[id]!.o.priority);
        final (hzA, exA) = computeScores(planA.metrics, priorityOf(planA.order), totalPriority, model);
        final (hzB, exB) = computeScores(planB.metrics, priorityOf(planB.order), totalPriority, model);
        final hazard = math.max(hzA.score, hzB.score);
        final fT = math.min(exA.timeFactor, exB.timeFactor);
        final fO = math.min(exA.consumablesFactor, exB.consumablesFactor);
        final value = totalPriority != 0 ? pri / totalPriority : 0.0;
        final success = 100.0 * value * fT * fO * (1.0 - hazard / 200.0);
        final tMax = math.max(planA.metrics.totalH, planB.metrics.totalH);
        final key = (success, -tMax);
        if (bestKey == null || key.$1 > bestKey.$1 + 1e-9 || ((key.$1 - bestKey.$1).abs() <= 1e-9 && key.$2 > bestKey.$2 + 1e-9)) {
          bestKey = key;
          best = (ma, mb, sep, value, hazard, fT, fO, success);
        }
      }
    }
    if (best == null) return PairResult(status: 'no_pair', limitM: model.pairMaxSeparationM, routes: const {});
    final (ma, mb, sep, value, hazard, fT, fO, success) = best;
    final routes = <String, RouteResult>{};
    for (final (name, mask) in [('pair1', ma), ('pair2', mb)]) {
      final plan = valid[mask]!.$1;
      final other = valid[mask == ma ? mb : ma]!.$1.order;
      final omit = <Map<String, String>>[
        for (final id in ids)
          if (!plan.order.contains(id)) {'id': id, 'reason': other.contains(id) ? 'other_astronaut' : 'not_in_pair'},
        for (final e in _objs)
          if (e.blocked) {'id': e.o.id, 'reason': 'blocked'},
      ];
      routes[name] = _result(name, plan, omit);
    }
    final visited = {...valid[ma]!.$1.order, ...valid[mb]!.$1.order}.toList()..sort();
    return PairResult(
      status: 'ok',
      limitM: model.pairMaxSeparationM,
      routes: routes,
      summary: PairSummary(
        visited: visited,
        maxSeparationM: sep,
        totalH: math.max(valid[ma]!.$1.metrics.totalH, valid[mb]!.$1.metrics.totalH),
        o2RemainingMinFrac: math.min(routes['pair1']!.metrics!.o2RemainingFrac, routes['pair2']!.metrics!.o2RemainingFrac),
        hazard: hazard,
        success: SuccessScore(score: success, scienceValue: value, timeFactor: fT, consumablesFactor: fO, hazardPenalty: 1.0 - hazard / 200.0),
      ),
    );
  }

  /// Las tres rutas de la salida: segura, rápida y de ciencia.
  Map<String, RouteResult> allThree() => {
        'safe': primary('safe'),
        'fast': primary('fast'),
        'science': science('science'),
      };
}

/// Resumen de una salida en pareja: lo que hacen los dos astronautas juntos.
class PairSummary {
  const PairSummary({
    required this.visited,
    required this.maxSeparationM,
    required this.totalH,
    required this.o2RemainingMinFrac,
    required this.hazard,
    required this.success,
  });

  final List<String> visited;

  /// Mayor distancia entre los dos astronautas durante la salida.
  final double maxSeparationM;

  /// Tiempo de la salida: el del que más tarda.
  final double totalH;
  final double o2RemainingMinFrac;

  /// Peligro de la pareja: el mayor de los dos.
  final double hazard;
  final SuccessScore success;

  Map<String, dynamic> toJson() => {
        'visited': visited,
        'max_separation_m': maxSeparationM,
        'total_h': totalH,
        'o2_remaining_min_frac': o2RemainingMinFrac,
        'hazard': hazard,
        'success': success.toJson(),
      };
}

/// Resultado del modo en pareja: dos rutas (`pair1`, `pair2`) y el resumen.
class PairResult {
  const PairResult({required this.status, required this.limitM, required this.routes, this.summary});

  /// `ok` o `no_pair` (ninguna pareja de rutas cumple la separación máxima).
  final String status;
  final double limitM;
  final Map<String, RouteResult> routes;
  final PairSummary? summary;
}

/// Distancia en línea recta entre dos puntos locales, en metros.
double distanceM(double x0, double y0, double x1, double y1) => math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
