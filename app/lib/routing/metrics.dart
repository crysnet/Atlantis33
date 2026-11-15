import 'dart:math' as math;

import 'grid.dart';
import 'model.dart';

const double _sqrt2 = 1.4142135623730951;

double _clamp(double x, [double a = 0.0, double b = 1.0]) => x < a ? a : (x > b ? b : x);

/// Punto de no retorno: el primer punto desde el que terminar la ruta cuesta menos que deshacer el camino andado.
class NoReturn {
  const NoReturn({required this.index, required this.xM, required this.yM, required this.alongM, required this.fromHabitatM});

  final int index;
  final double xM;
  final double yM;
  final double alongM;
  final double fromHabitatM;

  Map<String, dynamic> toJson() => {
        'index': index,
        'x_m': xM,
        'y_m': yM,
        'along_m': alongM,
        'from_habitat_m': fromHabitatM,
      };
}

/// Métricas de una ruta. Referencia: `evaluar` en tools/routing.py.
class RouteMetrics {
  const RouteMetrics({
    this.rover = false,
    this.support = false,
    this.roverOk = true,
    this.modeLabel,
    this.emergencyMaxH,
    this.emergencyMaxFootH,
    this.roverM = 0.0,
    this.roverH = 0.0,
    required this.distanceM,
    required this.walkH,
    required this.stopH,
    required this.totalH,
    required this.maxSlopeDeg,
    required this.mNominal,
    required this.mCaution,
    required this.mHighCaution,
    required this.ascentM,
    required this.descentM,
    required this.o2UsedFrac,
    required this.o2RemainingFrac,
    required this.doseUGy,
    required this.maxRadiusM,
    required this.roughMeanNorm,
    required this.noReturn,
    required this.timeOk,
    required this.o2Ok,
  });

  /// Ruta calculada con rover.
  final bool rover;

  /// Ruta calculada con un rover de apoyo esperando en el hábitat.
  final bool support;

  /// Falso si el vehículo se queda sin recoger (modo por objetivo): la ruta no es factible.
  final bool roverOk;

  /// Etiqueta de `mode` que sustituye a la de los otros modos (`objective`).
  final String? modeLabel;

  /// Con rover de apoyo: tiempo máximo para llegar al hábitat en una emergencia, con rover y sin él (horas).
  final double? emergencyMaxH;
  final double? emergencyMaxFootH;
  final double roverM;
  final double roverH;
  final double distanceM;
  final double walkH;
  final double stopH;
  final double totalH;
  final double maxSlopeDeg;
  final double mNominal;
  final double mCaution;
  final double mHighCaution;
  final double ascentM;
  final double descentM;
  final double o2UsedFrac;
  final double o2RemainingFrac;
  final double doseUGy;
  final double maxRadiusM;
  final double roughMeanNorm;
  final NoReturn noReturn;
  final bool timeOk;
  final bool o2Ok;

  bool get feasible => timeOk && o2Ok && roverOk;

  Map<String, dynamic> toJson() => {
        'distance_m': distanceM,
        'mode': modeLabel ?? (support ? 'support' : (rover ? 'rover' : 'foot')),
        'emergency_max_h': emergencyMaxH,
        'emergency_max_foot_h': emergencyMaxFootH,
        'rover_m': roverM,
        'rover_h': roverH,
        'walk_h': walkH,
        'stop_h': stopH,
        'total_h': totalH,
        'max_slope_deg': maxSlopeDeg,
        'm_nominal': mNominal,
        'm_caution': mCaution,
        'm_high_caution': mHighCaution,
        'ascent_m': ascentM,
        'descent_m': descentM,
        'o2_used_frac': o2UsedFrac,
        'o2_remaining_frac': o2RemainingFrac,
        'dose_ugy': doseUGy,
        'max_radius_m': maxRadiusM,
        'rough_mean_norm': roughMeanNorm,
        'no_return': noReturn.toJson(),
        'time_ok': timeOk,
        'o2_ok': o2Ok,
        'rover_ok': roverOk,
        'feasible': feasible,
      };
}

/// Calcula las métricas de una ruta.
///
/// [cells] son los índices planos del camino completo. [stops] mapea la posición en [cells] a las horas de trabajo.
///
/// [rover] es null (a pie) o el par (k, j) de [roverLegs]: el rover va en los pasos 1..k y j+1..n-1. En esos tramos la
/// velocidad es constante, el oxígeno se gasta a `o2Rate` del nominal sin recargo por subida, y subir y bajar del rover
/// cuesta `transferH` en k y en j.
///
/// [roverSteps] es la alternativa para el modo por objetivo: el conjunto de pasos (1..n-1) hechos en vehículo, de
/// [objectiveRoverSteps]. Bajar y subir del vehículo cuesta `transferH` cada vez, salvo al salir del hábitat y al llegar
/// a él. [modeLabel] cambia la etiqueta `mode` y [roverOk] falso (vehículo varado) vuelve infactible la ruta.
///
/// [support] pone un rover de apoyo en el hábitat (ver [supportEmergency]): no cambia la marcha ni el tiempo de la ruta,
/// cambia el tiempo de regreso en una emergencia, el punto de no retorno y el radio que cuenta en el peligro.
RouteMetrics evaluate(
  RouteGrid grid,
  RoutingModel model,
  List<int> cells,
  Map<int, double> stops, {
  (int, int)? rover,
  bool support = false,
  Set<int>? roverSteps,
  String? modeLabel,
  bool roverOk = true,
}) {
  if (rover != null) {
    stops = Map<int, double>.of(stops);
    for (final i in [rover.$1, rover.$2]) {
      stops[i] = (stops[i] ?? 0.0) + model.rover.transferH;
    }
  } else if (roverSteps != null && roverSteps.isNotEmpty) {
    final stops0 = stops.keys.toSet();
    stops = Map<int, double>.of(stops);
    for (var p = 0; p < cells.length; p++) {
      final ent = roverSteps.contains(p);
      final sal = roverSteps.contains(p + 1);
      final baja = ent && p < cells.length - 1 && (!sal || stops0.contains(p));
      final sube = sal && p > 0 && (!ent || stops0.contains(p));
      for (var c = 0; c < (baja ? 1 : 0) + (sube ? 1 : 0); c++) {
        stops[p] = (stops[p] ?? 0.0) + model.rover.transferH;
      }
    }
  }
  final w = grid.width;
  final cell = grid.cellM;
  final v0 = model.flatSpeedMPerH;
  final z = grid.z;
  final pend = grid.slope;
  final rug = grid.rough;
  final n = cells.length;
  final tCum = List<double>.filled(n, 0.0);
  final retCum = List<double>.filled(n, 0.0);
  final distCum = List<double>.filled(n, 0.0);
  var dist = 0.0, walk = 0.0, stopH = 0.0, up = 0.0, down = 0.0, o2 = 0.0;
  var mNom = 0.0, mCau = 0.0, mAlta = 0.0;
  var maxPend = pend[cells[0]];
  var rugAcum = 0.0;
  final (xs0, ys0) = grid.xy(grid.habitat);
  var radiusMax = 0.0;
  var roverM = 0.0, roverH = 0.0;
  final wCum = List<double>.filled(n, 0.0); // solo marcha, sin paradas
  final rad = List<double>.filled(n, 0.0); // distancia en línea recta al hábitat
  for (var i = 1; i < n; i++) {
    final u = cells[i - 1];
    final v = cells[i];
    final diag = (v ~/ w != u ~/ w) && (v % w != u % w);
    final d = cell * (diag ? _sqrt2 : 1.0);
    final dz = z[v] - z[u];
    final tan = dz / d;
    final double dt;
    final double dtRet;
    final onRover = rover != null ? (i <= rover.$1 || i > rover.$2) : (roverSteps != null && roverSteps.contains(i));
    if (onRover) {
      dt = dtRet = d / model.rover.speedMPerH;
      o2 += dt * model.rover.o2Rate / model.o2CapacityH;
      roverM += d;
      roverH += dt;
    } else {
      dt = d / (v0 * model.speedFactor(tan));
      dtRet = d / (v0 * model.speedFactor(-tan));
      o2 += dt * (1.0 + model.o2Uphill * math.max(0.0, tan)) / model.o2CapacityH;
    }
    walk += dt;
    dist += d;
    if (dz > 0) {
      up += dz;
    } else {
      down -= dz;
    }
    final s = pend[v];
    maxPend = math.max(maxPend, s);
    if (s < model.slopeNominalMax) {
      mNom += d;
    } else if (s < model.slopeCautionMax) {
      mCau += d;
    } else {
      mAlta += d;
    }
    rugAcum += math.min(rug[v] / model.roughRefCm, 1.0);
    final (x, y) = grid.xy(v);
    radiusMax = math.max(radiusMax, math.sqrt((x - xs0) * (x - xs0) + (y - ys0) * (y - ys0)));
    tCum[i] = tCum[i - 1] + dt;
    wCum[i] = wCum[i - 1] + dt;
    rad[i] = math.sqrt((x - xs0) * (x - xs0) + (y - ys0) * (y - ys0));
    retCum[i] = retCum[i - 1] + dtRet;
    distCum[i] = dist;
    final h = stops[i];
    if (h != null) {
      stopH += h;
      o2 += h * model.o2StopRate / model.o2CapacityH;
      tCum[i] += h;
    }
  }
  final total = walk + stopH;
  List<double>? emergWith;
  List<double>? emergFoot;
  var retEf = retCum;
  if (support) {
    final e = supportEmergency(grid, model, cells, wCum, retCum, distCum);
    emergWith = e.with_;
    emergFoot = e.foot;
    retEf = e.retEf;
    // El radio que cuenta en el peligro se reduce en la proporción en que el rover acorta el regreso.
    radiusMax = 0.0;
    for (var i = 0; i < n; i++) {
      radiusMax = math.max(radiusMax, rad[i] * (emergFoot[i] > 0 ? emergWith[i] / emergFoot[i] : 1.0));
    }
  }
  var pnr = n - 1;
  for (var i = 0; i < n; i++) {
    if (total - tCum[i] <= retEf[i]) {
      pnr = i;
      break;
    }
  }
  final (px, py) = grid.xy(cells[pnr]);
  return RouteMetrics(
    rover: rover != null || (roverSteps != null && roverSteps.isNotEmpty),
    support: support,
    roverOk: roverOk,
    modeLabel: modeLabel,
    emergencyMaxH: emergWith?.reduce(math.max),
    emergencyMaxFootH: emergFoot?.reduce(math.max),
    roverM: roverM,
    roverH: roverH,
    distanceM: dist,
    walkH: walk,
    stopH: stopH,
    totalH: total,
    maxSlopeDeg: maxPend,
    mNominal: mNom,
    mCaution: mCau,
    mHighCaution: mAlta,
    ascentM: up,
    descentM: down,
    o2UsedFrac: o2,
    o2RemainingFrac: 1.0 - o2,
    doseUGy: model.doseUGyPerDay * total / 24.0,
    maxRadiusM: radiusMax,
    roughMeanNorm: rugAcum / math.max(1, n - 1),
    noReturn: NoReturn(
      index: pnr,
      xM: px,
      yM: py,
      alongM: distCum[pnr],
      fromHabitatM: math.sqrt((px - xs0) * (px - xs0) + (py - ys0) * (py - ys0)),
    ),
    timeOk: total <= model.maxEvaH,
    o2Ok: (1.0 - o2) >= model.o2Reserve,
  );
}

/// (a, b): el rover puede recorrer los pasos 1..a (tramo inicial) y b+1..n-1 (tramo final) de la ruta, o null si el
/// hábitat no es transitable. Un paso es transitable si la celda no está prohibida y su pendiente y rugosidad no pasan
/// los límites del rover. Referencia: `corredores_rover` en tools/routing.py.
(int, int)? roverCorridors(RouteGrid grid, RoutingModel model, List<int> cells) {
  final n = cells.length;
  final r = model.rover;
  final ok = [
    for (final c in cells) grid.blocked[c] == 0 && grid.slopeReal[c] <= r.slopeLimitDeg && grid.rough[c] <= r.roughMaxCm,
  ];
  if (!ok[0]) return null;
  var a = 0;
  while (a + 1 < n && ok[a + 1]) {
    a++;
  }
  var b = n - 1;
  while (b - 1 >= 0 && ok[b - 1]) {
    b--;
  }
  return (a, b);
}

/// Tiempo para llegar al hábitat si hay una emergencia en cada punto de la ruta, con un rover de apoyo.
/// Referencia: `emergencia_apoyo` en tools/routing.py (ahí está la descripción de la regla).
///
/// Devuelve el tiempo a pie, el tiempo con rover y, para el punto de no retorno, el costo de deshacer lo andado con rover
/// (o a pie si no mejora).
({List<double> foot, List<double> with_, List<double> retEf}) supportEmergency(
  RouteGrid grid,
  RoutingModel model,
  List<int> cells,
  List<double> wCum,
  List<double> retCum,
  List<double> distCum,
) {
  final n = cells.length;
  final cor = roverCorridors(grid, model, cells);
  final v = model.rover.speedMPerH;
  final cam = model.rover.transferH;
  final sal = model.rover.dispatchH;
  final foot = List<double>.filled(n, 0.0);
  final with_ = List<double>.filled(n, 0.0);
  final retEf = List<double>.filled(n, 0.0);
  for (var i = 0; i < n; i++) {
    final seguir = wCum[n - 1] - wCum[i];
    foot[i] = math.min(retCum[i], seguir);
    var mejor = foot[i];
    retEf[i] = retCum[i];
    if (cor != null) {
      final (a, b) = cor;
      for (var m = 1; m <= math.min(i, a); m++) {
        final tr = distCum[m] / v;
        final t = math.max(retCum[i] - retCum[m], sal + tr) + tr + cam;
        if (t < retEf[i]) retEf[i] = t;
        if (t < mejor) mejor = t;
      }
      for (var m = math.max(i, b); m < n - 1; m++) {
        final tr = (distCum[n - 1] - distCum[m]) / v;
        final t = math.max(wCum[m] - wCum[i], sal + tr) + tr + cam;
        if (t < mejor) mejor = t;
      }
    }
    with_[i] = mejor;
  }
  return (foot: foot, with_: with_, retEf: retEf);
}

/// Dónde usa el rover una ruta de ida y vuelta, o null si no lo usa. Referencia: `tramos_rover` en tools/routing.py.
///
/// El rover se deja en un punto de aparcamiento P. Va de ida por el tramo inicial transitable (pendiente y rugosidad
/// dentro de los límites del rover) hasta P. El resto de la ida y las paradas son a pie. En la vuelta, se vuelve a pie
/// hasta P (la ruta de regreso debe pasar por esa celda), se sube al rover y se llega al hábitat por el tramo final
/// transitable. P es la celda más lejana del tramo inicial que cumple eso. Devuelve (k, j).
(int, int)? roverLegs(RouteGrid grid, RoutingModel model, List<int> cells, Map<int, double> stops) {
  final n = cells.length;
  if (n < 3) return null;
  final cor = roverCorridors(grid, model, cells);
  if (cor == null) return null;
  final (a, b) = cor;
  var lastStop = n ~/ 2;
  if (stops.isNotEmpty) {
    lastStop = stops.keys.reduce(math.max);
  }
  final where = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    where.putIfAbsent(cells[i], () => []).add(i);
  }
  for (var k = a; k >= 1; k--) {
    int? best;
    for (final j in where[cells[k]]!) {
      if (j > lastStop && j >= b && (best == null || j < best)) best = j;
    }
    if (best != null) return (k, best);
  }
  return null;
}

/// Qué pasos de una ruta se hacen en vehículo cuando cada objetivo trae su transporte. Referencia:
/// `pasos_rover_objetivos` en tools/routing.py (ahí están las reglas).
///
/// [stops] mapea la posición en [cells] a las horas de trabajo; [transports] es (id, transporte) en orden de visita.
/// Devuelve los pasos en vehículo, las notas (`id` y `reason`) y si el vehículo se queda varado.
({Set<int> steps, List<Map<String, String?>> notes, bool stranded}) objectiveRoverSteps(
  RouteGrid grid,
  RoutingModel model,
  List<int> cells,
  Map<int, double> stops,
  List<(String, String)> transports,
) {
  final n = cells.length;
  final r = model.rover;
  final ok = [
    for (final c in cells) grid.blocked[c] == 0 && grid.slopeReal[c] <= r.slopeLimitDeg && grid.rough[c] <= r.roughMaxCm,
  ];
  final suf = List<bool>.filled(n, true);
  for (var j = n - 2; j >= 0; j--) {
    suf[j] = suf[j + 1] && ok[j + 1];
  }
  final where = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    where.putIfAbsent(cells[i], () => []).add(i);
  }
  bool recoverable(int x, int b) => where[cells[x]]!.any((j) => j > b && suf[j]);

  final pos = stops.keys.toList()..sort();
  final legs = <(int, int, String, String)>[];
  var prev = 0;
  for (var q = 0; q < pos.length && q < transports.length; q++) {
    legs.add((prev, pos[q], transports[q].$2, transports[q].$1));
    prev = pos[q];
  }
  var roverCell = cells[0];
  final steps = <int>{};
  final notes = <Map<String, String?>>[];
  for (final (a, b, tr, id) in legs) {
    if (tr == 'foot') continue;
    int? i;
    for (var x = a; x <= b; x++) {
      if (cells[x] == roverCell) {
        i = x;
        break;
      }
    }
    if (i == null) {
      notes.add({'id': id, 'reason': 'rover_not_here'});
      continue;
    }
    if (!ok[i]) {
      notes.add({'id': id, 'reason': 'rover_cannot_start'});
      continue;
    }
    var m = i;
    while (m + 1 <= b && ok[m + 1]) {
      m++;
    }
    if (m == i) {
      notes.add({'id': id, 'reason': 'rover_blocked'});
      continue;
    }
    if (tr == 'vehicle' && m < b) {
      notes.add({'id': id, 'reason': 'vehicle_partial'});
    }
    int? k;
    for (var x = m; x > i; x--) {
      if (x == b || recoverable(x, b)) {
        k = x;
        break;
      }
    }
    if (k == null) {
      notes.add({'id': id, 'reason': 'no_recovery'});
      continue;
    }
    for (var s = i + 1; s <= k; s++) {
      steps.add(s);
    }
    roverCell = cells[k];
  }
  var stranded = false;
  if (roverCell != cells[n - 1]) {
    final aF = pos.isEmpty ? 0 : pos.last;
    int? i;
    for (var x = aF; x < n; x++) {
      if (cells[x] == roverCell && suf[x]) {
        i = x;
        break;
      }
    }
    if (i == null) {
      stranded = true;
      notes.add({'id': null, 'reason': 'rover_stranded'});
    } else {
      for (var s = i + 1; s < n; s++) {
        steps.add(s);
      }
    }
  }
  return (steps: steps, notes: notes, stranded: stranded);
}

/// Posición (x, y) en metros de un astronauta que sigue [cells] a pie, cada `pairSampleH` horas durante la salida.
/// Al terminar espera en el hábitat. Referencia: `posiciones` y `llegadas` en tools/routing.py.
List<(double, double)> samplePositions(RouteGrid grid, RoutingModel model, List<int> cells, Map<int, double> stops) {
  final w = grid.width;
  final n = cells.length;
  final arrive = List<double>.filled(n, 0.0);
  var leave = stops[0] ?? 0.0;
  for (var i = 1; i < n; i++) {
    final u = cells[i - 1];
    final v = cells[i];
    final diag = (v ~/ w != u ~/ w) && (v % w != u % w);
    final d = grid.cellM * (diag ? _sqrt2 : 1.0);
    final tan = (grid.z[v] - grid.z[u]) / d;
    arrive[i] = leave + d / (model.flatSpeedMPerH * model.speedFactor(tan));
    leave = arrive[i] + (stops[i] ?? 0.0);
  }
  final count = (model.maxEvaH / model.pairSampleH).round() + 1;
  final out = <(double, double)>[];
  var i = 0;
  for (var k = 0; k < count; k++) {
    final t = k * model.pairSampleH;
    while (i + 1 < n && arrive[i + 1] <= t) {
      i++;
    }
    out.add(grid.xy(cells[i]));
  }
  return out;
}

/// Mayor distancia en línea recta, en metros, entre dos astronautas a lo largo de la salida.
double maxSeparation(List<(double, double)> a, List<(double, double)> b) {
  var best = 0.0;
  for (var k = 0; k < a.length; k++) {
    final dx = a[k].$1 - b[k].$1;
    final dy = a[k].$2 - b[k].$2;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d > best) best = d;
  }
  return best;
}

/// Ruta factible con margen cómodo: los factores de tiempo y de consumibles del puntaje de éxito valen 1.
bool isComfortable(RoutingModel model, RouteMetrics m) {
  final marginT = (model.maxEvaH - m.totalH) / model.maxEvaH;
  final marginO2 = m.o2RemainingFrac - model.o2Reserve;
  return m.feasible &&
      marginT >= (model.success['time_margin_good'] as num).toDouble() &&
      marginO2 >= (model.success['o2_margin_good'] as num).toDouble();
}

/// Puntaje de peligro con su desglose. Cada componente va de 0 a 1; el puntaje, de 0 a 100.
class HazardScore {
  const HazardScore({required this.score, required this.components, required this.weights});

  final double score;
  final Map<String, double> components;
  final Map<String, double> weights;

  Map<String, dynamic> toJson() => {'score': score, 'components': components, 'weights': weights};
}

/// Puntaje de éxito con su desglose.
class SuccessScore {
  const SuccessScore({
    required this.score,
    required this.scienceValue,
    required this.timeFactor,
    required this.consumablesFactor,
    required this.hazardPenalty,
  });

  final double score;
  final double scienceValue;
  final double timeFactor;
  final double consumablesFactor;
  final double hazardPenalty;

  Map<String, dynamic> toJson() => {
        'score': score,
        'science_value': scienceValue,
        'time_factor': timeFactor,
        'consumables_factor': consumablesFactor,
        'hazard_penalty': hazardPenalty,
      };
}

/// Referencia: `puntajes` en tools/routing.py.
(HazardScore, SuccessScore) computeScores(RouteMetrics m, double visitedPriority, double totalPriority, RoutingModel model) {
  final hz = model.hazard;
  final ex = model.success;
  final wj = hz['weights'] as Map<String, dynamic>;
  final expo = ((hz['slope_caution_weight'] as num).toDouble() * m.mCaution +
          (hz['slope_high_weight'] as num).toDouble() * m.mHighCaution) /
      (hz['slope_exposure_ref_m'] as num).toDouble();
  final rWb = (hz['walkback_max_h'] as num).toDouble() * model.flatSpeedMPerH;
  final marginT = (model.maxEvaH - m.totalH) / model.maxEvaH;
  final marginO2 = m.o2RemainingFrac - model.o2Reserve;
  final comp = <String, double>{
    'slope': _clamp(expo),
    'terrain': _clamp(m.roughMeanNorm),
    'walkback': _clamp((m.maxRadiusM - rWb) / rWb),
    'consumables': _clamp(math.max(
      1.0 - marginO2 / (hz['consumables_margin_good'] as num).toDouble(),
      1.0 - marginT / (hz['time_margin_good'] as num).toDouble(),
    )),
    'radiation': _clamp(m.doseUGy / (model.doseUGyPerDay * model.maxEvaH / 24.0)),
    'day': _clamp((hz['day_conditions_component'] as num).toDouble()),
  };
  final weights = {for (final e in wj.entries) e.key: (e.value as num).toDouble()};
  var danger = 0.0;
  for (final e in comp.entries) {
    danger += weights[e.key]! * e.value;
  }
  final value = totalPriority != 0 ? visitedPriority / totalPriority : 0.0;
  final fT = _clamp(marginT / (ex['time_margin_good'] as num).toDouble());
  final fO = _clamp(marginO2 / (ex['o2_margin_good'] as num).toDouble());
  final success = 100.0 * value * fT * fO * (1.0 - danger / 200.0);
  return (
    HazardScore(score: danger, components: comp, weights: weights),
    SuccessScore(
      score: success,
      scienceValue: value,
      timeFactor: fT,
      consumablesFactor: fO,
      hazardPenalty: 1.0 - danger / 200.0,
    ),
  );
}
