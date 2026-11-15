import 'dart:math' as math;

import '../data/environment_data.dart';
import '../data/site_data.dart';
import '../routing/routing.dart';
import 'route_utils.dart';

/// Posición simulada sobre la ruta y lo que se calcula a partir de ella.
class SimPos {
  SimPos({
    required this.alongM,
    required this.totalM,
    required this.headingDeg,
    required this.elevM,
    required this.slopeHereDeg,
    required this.slopeAheadDeg,
    required this.slopeAheadAtM,
    required this.next,
    required this.distToNextM,
    required this.distToEndM,
    required this.habitatM,
    required this.walkBackH,
    required this.elapsedH,
    required this.o2Frac,
    required this.o2Depleted,
    required this.airC,
    required this.lmstLabel,
    required this.xM,
    required this.yM,
    required this.cellIndex,
    required this.doseUGy,
    required this.o2NeedBackFrac,
  });

  final double alongM;
  final double totalM;
  final double headingDeg;
  final double elevM;
  final double slopeHereDeg;
  final double slopeAheadDeg;
  final double slopeAheadAtM;
  final Objective? next;
  final double distToNextM;
  final double distToEndM;
  final double habitatM;
  final double walkBackH;
  final double elapsedH;
  final double o2Frac;

  /// El oxígeno de la ruta no alcanza: ya se agotó en esta posición.
  final bool o2Depleted;
  final double? airC;
  final String lmstLabel;

  /// Posición en el plano local (m) y índice de la celda en el camino.
  final double xM;
  final double yM;
  final int cellIndex;

  /// Dosis acumulada hasta aquí (µGy, interpolada del total de la ruta).
  final double doseUGy;

  /// Fracción de oxígeno que haría falta para volver a pie al hábitat en línea recta, con el ritmo medio de la ruta.
  final double o2NeedBackFrac;

  static const _lookM = 40.0;
  static const _aheadM = 90.0;

  static SimPos compute(SiteData d, List<Objective> objectives, RouteResult r, double t, {int? envSol, double? doseRate}) {
    final g = d.grid;
    final cells = r.cells;
    final along = alongRoute(g, cells);
    final total = along.last;
    final target = t * total;
    var i = 0;
    while (i < cells.length - 1 && along[i + 1] <= target) {
      i++;
    }
    // Rumbo hacia un punto unos metros por delante (o desde uno por detrás al final de la ruta).
    var j = i;
    while (j < cells.length - 1 && along[j] < along[i] + _lookM) {
      j++;
    }
    var a = i;
    var b = j;
    if (a == b) {
      a = math.max(0, i - 10);
      b = i;
    }
    final (ax, ay) = g.xy(cells[a]);
    final (bx, by) = g.xy(cells[b]);
    // x al este, y al sur: el rumbo se mide desde el norte hacia el este.
    final heading = (math.atan2(bx - ax, -(by - ay)) * 180 / math.pi + 360) % 360;
    final (px, py) = g.xy(cells[i]);
    final here = cells[i];
    // Pendiente máxima en los próximos metros y a qué distancia.
    var maxSlope = 0.0;
    var atM = 0.0;
    for (var k = i; k < cells.length && along[k] <= along[i] + _aheadM; k++) {
      final s = g.slopeReal[cells[k]];
      if (!s.isNaN && s > maxSlope) {
        maxSlope = s;
        atM = along[k] - along[i];
      }
    }
    // Siguiente objetivo de la ruta: el primero cuya celda más cercana queda por delante.
    Objective? next;
    var distNext = 0.0;
    for (final id in r.visited) {
      final matches = objectives.where((x) => x.id == id);
      if (matches.isEmpty) continue;
      final o = matches.first;
      final oc = g.cellOf(o.xM, o.yM);
      var best = 0;
      var bestD = double.infinity;
      for (var k = 0; k < cells.length; k++) {
        final (cx, cy) = g.xy(cells[k]);
        final (ox, oy) = g.xy(oc);
        final dd = (cx - ox) * (cx - ox) + (cy - oy) * (cy - oy);
        if (dd < bestD) {
          bestD = dd;
          best = k;
        }
      }
      if (along[best] > along[i] + 1.0 && (next == null || along[best] < along[i] + distNext)) {
        next = o;
        distNext = along[best] - along[i];
      }
    }
    final habM = math.sqrt((px - d.habitatX) * (px - d.habitatX) + (py - d.habitatY) * (py - d.habitatY));
    final m = r.metrics!;
    final elapsed = t * m.totalH;
    final lmst = d.envConfig.evaStartLmstH + elapsed;
    final env = d.environment;
    return SimPos(
      alongM: along[i],
      totalM: total,
      headingDeg: heading,
      elevM: g.z[here],
      slopeHereDeg: g.slopeReal[here].isNaN ? 0.0 : g.slopeReal[here],
      slopeAheadDeg: maxSlope,
      slopeAheadAtM: atM,
      next: next,
      distToNextM: distNext,
      distToEndM: total - along[i],
      habitatM: habM,
      walkBackH: habM / d.model.flatSpeedMPerH,
      elapsedH: elapsed,
      o2Frac: (1.0 - m.o2UsedFrac * t).clamp(0.0, 1.0),
      o2Depleted: 1.0 - m.o2UsedFrac * t <= 0,
      airC: _airAt(env.weatherFor(envSol ?? env.referenceSol), lmst),
      xM: px,
      yM: py,
      cellIndex: i,
      doseUGy: (doseRate ?? d.model.doseUGyPerDay) * m.totalH / 24.0 * t,
      o2NeedBackFrac: m.totalH > 0 ? m.o2UsedFrac / m.totalH * (habM / d.model.flatSpeedMPerH) : 0.0,
      lmstLabel: _clock(lmst),
    );
  }

  /// Hora del día `HH:MM`, redondeada al minuto (igual que la hora de fin de Seguridad).
  static String _clock(double h) {
    final total = (h * 60).round() % 1440;
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  /// Temperatura del aire a la hora local dada, con los datos de REMS del sol de referencia elegido en Seguridad.
  static double? _airAt(WeatherSol? w, double lmstH) {
    if (w == null) return null;
    final hour = lmstH.floor() % 24;
    for (var k = 0; k < 24; k++) {
      for (final h in w.hourly) {
        if (h.hour == (hour + k) % 24 && h.airC != null) return h.airC;
      }
    }
    return null;
  }
}
