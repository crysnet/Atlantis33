import 'dart:math' as math;
import 'dart:typed_data';

import 'grid.dart';
import 'model.dart';

const double _sqrt2 = 1.4142135623730951;

// Mismo orden de vecinos que `VECINOS` en tools/routing.py: (fila, columna, multiplicador de distancia).
const List<int> _dr = [-1, -1, -1, 0, 0, 1, 1, 1];
const List<int> _dc = [-1, 0, 1, -1, 1, -1, 0, 1];
const List<double> _dist = [_sqrt2, 1.0, _sqrt2, 1.0, 1.0, _sqrt2, 1.0, _sqrt2];

/// Camino de A*: costo ponderado y celdas del inicio a la meta.
class PathResult {
  const PathResult(this.cost, this.cells);

  final double cost;
  final List<int> cells;
}

/// Montículo mínimo ordenado por (f, g, índice), igual que las tuplas de `heapq` en Python.
class _Heap {
  _Heap() {
    _f = Float64List(_cap);
    _g = Float64List(_cap);
    _i = Int32List(_cap);
  }

  int _cap = 1024;
  int _n = 0;
  late Float64List _f;
  late Float64List _g;
  late Int32List _i;

  bool get isNotEmpty => _n > 0;

  bool _less(double f1, double g1, int i1, double f2, double g2, int i2) {
    if (f1 != f2) return f1 < f2;
    if (g1 != g2) return g1 < g2;
    return i1 < i2;
  }

  void push(double f, double g, int idx) {
    if (_n == _cap) {
      _cap *= 2;
      _f = Float64List(_cap)..setRange(0, _n, _f);
      _g = Float64List(_cap)..setRange(0, _n, _g);
      _i = Int32List(_cap)..setRange(0, _n, _i);
    }
    var k = _n++;
    while (k > 0) {
      final p = (k - 1) >> 1;
      if (!_less(f, g, idx, _f[p], _g[p], _i[p])) break;
      _f[k] = _f[p];
      _g[k] = _g[p];
      _i[k] = _i[p];
      k = p;
    }
    _f[k] = f;
    _g[k] = g;
    _i[k] = idx;
  }

  // Devuelve g en `popG` e índice en `popIdx` para no crear objetos por cada extracción.
  double popG = 0;
  int popIdx = 0;

  void pop() {
    popG = _g[0];
    popIdx = _i[0];
    final f = _f[--_n];
    final g = _g[_n];
    final idx = _i[_n];
    var k = 0;
    while (true) {
      var c = 2 * k + 1;
      if (c >= _n) break;
      if (c + 1 < _n && _less(_f[c + 1], _g[c + 1], _i[c + 1], _f[c], _g[c], _i[c])) c++;
      if (!_less(_f[c], _g[c], _i[c], f, g, idx)) break;
      _f[k] = _f[c];
      _g[k] = _g[c];
      _i[k] = _i[c];
      k = c;
    }
    if (_n > 0) {
      _f[k] = f;
      _g[k] = g;
      _i[k] = idx;
    }
  }
}

/// A* de [start] a [goal] (índices planos). Devuelve null si no hay camino.
///
/// Costo de un paso de u a v, con distancia d:
/// `d * (1 + wSlope * (pendiente_v / 25)^2 + wRough * min(rugosidad_v / 40, 1) + wTime * (t - 1))`,
/// con t = vmax / v(theta) >= 1 y theta la pendiente en el sentido del paso. Como el multiplicador es >= 1,
/// la distancia octil es una heurística admisible. No corta esquinas junto a celdas prohibidas.
/// Referencia: `astar` en tools/routing.py.
PathResult? astar(RouteGrid grid, RoutingModel model, Profile profile, int start, int goal) {
  final w = grid.width;
  final h = grid.height;
  final cell = grid.cellM;
  final pend = grid.slope;
  final rug = grid.rough;
  final z = grid.z;
  final forb = grid.blocked;
  final lim = profile.slopeLimitDeg;
  final rmax = profile.roughMaxCm;
  final ws = profile.wSlope;
  final wr = profile.wRough;
  final wt = profile.wTime;
  final invP2 = 1.0 / (model.slopeRefDeg * model.slopeRefDeg);
  final invR = 1.0 / model.roughRefCm;
  final k = model.toblerK;
  final fmin = model.minSpeedFactor;
  final gmax = model.maxSpeedFactor;
  if (forb[start] != 0 || pend[start] > lim || rug[start] > rmax || forb[goal] != 0 || pend[goal] > lim || rug[goal] > rmax) return null;

  final mr = goal ~/ w;
  final mc = goal % w;
  final n = w * h;
  final g = Float64List(n)..fillRange(0, n, double.infinity);
  final parent = Int32List(n)..fillRange(0, n, -1);
  g[start] = 0.0;
  final ir = start ~/ w;
  final ic = start % w;
  final dr0 = (ir - mr).abs();
  final dc0 = (ic - mc).abs();
  final heap = _Heap()
    ..push(cell * (math.max(dr0, dc0) + (_sqrt2 - 1.0) * math.min(dr0, dc0)), 0.0, start);
  while (heap.isNotEmpty) {
    heap.pop();
    final gu = heap.popG;
    final u = heap.popIdx;
    if (gu > g[u]) continue;
    if (u == goal) break;
    final r = u ~/ w;
    final c = u % w;
    final zu = z[u];
    for (var q = 0; q < 8; q++) {
      final dr = _dr[q];
      final dc = _dc[q];
      final rr = r + dr;
      final cc = c + dc;
      if (rr < 0 || rr >= h || cc < 0 || cc >= w) continue;
      final v = rr * w + cc;
      if (forb[v] != 0 || pend[v] > lim || rug[v] > rmax) continue;
      if (dr != 0 && dc != 0) {
        final a = u + dr * w;
        final b = u + dc;
        if (forb[a] != 0 || pend[a] > lim || rug[a] > rmax || forb[b] != 0 || pend[b] > lim || rug[b] > rmax) continue;
      }
      final d = cell * _dist[q];
      var gt = math.exp(-k * (((z[v] - zu) / d + 0.05).abs() - 0.05));
      if (gt < fmin) gt = fmin;
      final s = pend[v];
      var ro = rug[v] * invR;
      if (ro > 1.0) ro = 1.0;
      final ng = gu + d * (1.0 + ws * s * s * invP2 + wr * ro + wt * (gmax / gt - 1.0));
      if (ng < g[v]) {
        g[v] = ng;
        parent[v] = u;
        final da = (rr - mr).abs();
        final db = (cc - mc).abs();
        heap.push(ng + cell * (math.max(da, db) + (_sqrt2 - 1.0) * math.min(da, db)), ng, v);
      }
    }
  }
  if (g[goal] == double.infinity) return null;
  final path = <int>[goal];
  while (path.last != start) {
    path.add(parent[path.last]);
  }
  return PathResult(g[goal], path.reversed.toList());
}
