import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/site_data.dart';
import '../routing/routing.dart';

/// Vista en perspectiva del terreno desde la posición del astronauta, dibujada con el modelo de elevación del sitio.
///
/// No es una foto: cada columna de la pantalla lanza un rayo en la dirección del rumbo y se pintan, de cerca a lejos,
/// las franjas de terreno que asoman por encima de lo ya dibujado. El sombreado sale de la pendiente del propio relieve
/// con un sol fijo; la bruma crece con la distancia. Sirve de fondo al Casco cuando el sitio no tiene fotos del rover.
class TerrainView extends StatefulWidget {
  const TerrainView({super.key, required this.data, required this.x, required this.y, required this.headingDeg});

  final SiteData data;

  /// Posición en metros locales del sitio (x al este, y al sur) y rumbo en grados desde el norte.
  final double x;
  final double y;
  final double headingDeg;

  @override
  State<TerrainView> createState() => _TerrainViewState();
}

class _TerrainViewState extends State<TerrainView> {
  OrthoSampler? _ortho;
  String _key = '';
  int _req = 0;

  @override
  void initState() {
    super.initState();
    _refreshOrtho();
  }

  @override
  void didUpdateWidget(TerrainView old) {
    super.didUpdateWidget(old);
    _refreshOrtho();
  }

  /// Carga la textura (ortofoto empaquetada) alrededor de la posición; solo cuando cambia la tesela central.
  void _refreshOrtho() {
    final d = widget.data;
    final key = '${d.assetDir}:${OrthoSampler.centerKey(d, widget.x, widget.y)}';
    if (key == _key) return;
    _key = key;
    final req = ++_req;
    OrthoSampler.load(d, widget.x, widget.y).then((o) {
      if (mounted && req == _req) setState(() => _ortho = o);
    });
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.infinite,
        painter: TerrainPainter(widget.data.grid, widget.x, widget.y, widget.headingDeg, _ortho),
      );
}

/// Brillo (0 a 1) de la ortofoto del sitio en un punto. Junta, con cuatro niveles de detalle, las teselas 3 × 3 que
/// rodean la posición; en cada punto usa el nivel más fino que lo cubre. Fuera de ellas no hay dato (null).
class OrthoSampler {
  OrthoSampler._(this._levels);

  final List<_OrthoLevel> _levels;

  static final Map<String, Uint8List?> _cache = {};

  static List<int> _zs(SiteData d) {
    final top = d.tileCount - 1;
    return [for (var z = top; z >= 0 && z > top - 7; z -= 2) z];
  }

  static String centerKey(SiteData d, double x, double y) {
    final z = d.tileCount - 1;
    final t = d.tileSizeM(z);
    return '${(x / t).floor()}:${(y / t).floor()}';
  }

  static Future<Uint8List?> _tile(SiteData d, int z, int tx, int ty) {
    final path = d.assetPath('ortho/$z/$tx/$ty.jpg');
    if (_cache.containsKey(path)) return Future.value(_cache[path]);
    return () async {
      try {
        final bytes = (await rootBundle.load(path)).buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        final img = (await codec.getNextFrame()).image;
        final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
        final lum = Uint8List(img.width * img.height);
        for (var i = 0; i < lum.length; i++) {
          lum[i] = ((rgba[i * 4] * 77 + rgba[i * 4 + 1] * 150 + rgba[i * 4 + 2] * 29) >> 8);
        }
        img.dispose();
        return _cache[path] = lum;
      } catch (_) {
        return _cache[path] = null;
      }
    }();
  }

  static Future<OrthoSampler> load(SiteData d, double x, double y) async {
    final levels = <_OrthoLevel>[];
    for (final z in _zs(d)) {
      final n = 1 << z;
      final t = d.tileSizeM(z);
      final cx = (x / t).floor(), cy = (y / t).floor();
      final tiles = <int, Uint8List>{};
      for (var ty = cy - 1; ty <= cy + 1; ty++) {
        for (var tx = cx - 1; tx <= cx + 1; tx++) {
          if (tx < 0 || ty < 0 || tx >= n || ty >= n || tx * t >= d.sizeM || ty * t >= d.sizeM) continue;
          final lum = await _tile(d, z, tx, ty);
          if (lum != null) tiles[ty * n + tx] = lum;
        }
      }
      levels.add(_OrthoLevel(z, n, t, tiles));
    }
    return OrthoSampler._(levels);
  }

  double? sample(double x, double y) {
    for (final l in _levels) {
      final v = l.at(x, y);
      if (v != null) return v;
    }
    return null;
  }
}

class _OrthoLevel {
  _OrthoLevel(this.z, this.n, this.tileM, this.tiles);

  final int z;
  final int n;
  final double tileM;
  final Map<int, Uint8List> tiles;

  double? at(double x, double y) {
    if (x < 0 || y < 0) return null;
    final tx = (x / tileM).floor(), ty = (y / tileM).floor();
    final lum = tiles[ty * n + tx];
    if (lum == null) return null;
    // Interpolación bilineal dentro de la tesela, para que la textura no se vea en bloques.
    const px = 512;
    final fx = ((x / tileM) - tx) * px - 0.5, fy = ((y / tileM) - ty) * px - 0.5;
    final x0 = fx.floor(), y0 = fy.floor();
    final tx1 = fx - x0, ty1 = fy - y0;
    int at(int u, int v) => lum[v.clamp(0, px - 1) * px + u.clamp(0, px - 1)];
    final top = at(x0, y0) * (1 - tx1) + at(x0 + 1, y0) * tx1;
    final bot = at(x0, y0 + 1) * (1 - tx1) + at(x0 + 1, y0 + 1) * tx1;
    return (top * (1 - ty1) + bot * ty1) / 255.0;
  }
}

class TerrainPainter extends CustomPainter {
  TerrainPainter(this.g, this.x, this.y, this.headingDeg, this.ortho);

  final RouteGrid g;
  final double x;
  final double y;
  final double headingDeg;

  /// Textura de la ortofoto; null mientras carga o si el sitio no la trae.
  final OrthoSampler? ortho;

  /// Altura de los ojos sobre el suelo (m), campo de visión horizontal y radio de Marte (m).
  static const double eyeM = 1.7;
  static const double fovDeg = 100;
  static const double marsR = 3396190;

  static const Color skyTop = Color(0xFF6B5A55);
  static const Color haze = Color(0xFFD7B08A);
  static const Color shadeDark = Color(0xFF4A2E22);
  static const Color shadeLight = Color(0xFFC08A62);

  /// Elevación por interpolación bilineal entre centros de celda; null fuera del mapa.
  double? _z(double px, double py) {
    final cm = g.cellM;
    final fx = px / cm - 0.5, fy = py / cm - 0.5;
    final x0 = fx.floor(), y0 = fy.floor();
    if (x0 < 0 || y0 < 0 || x0 + 1 >= g.width || y0 + 1 >= g.height) return null;
    final tx = fx - x0, ty = fy - y0;
    final i = y0 * g.width + x0;
    final z00 = g.z[i], z10 = g.z[i + 1], z01 = g.z[i + g.width], z11 = g.z[i + g.width + 1];
    final z = (z00 * (1 - tx) + z10 * tx) * (1 - ty) + (z01 * (1 - tx) + z11 * tx) * ty;
    return z.isFinite ? z : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final horizonY = h * 0.52;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizonY + 1),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skyTop, haze]).createShader(Rect.fromLTWH(0, 0, w, horizonY)),
    );
    canvas.drawRect(Rect.fromLTWH(0, horizonY, w, h - horizonY), Paint()..color = shadeDark);
    final z0 = _z(x, y);
    if (z0 == null) return;
    final eyeZ = z0 + eyeM;

    final focal = (w / 2) / math.tan(fovDeg * math.pi / 360);
    final maxDist = math.max(2000.0, g.cellM * 150);
    const steps = 120;
    const nearM = 4.0;
    final ratio = math.pow(maxDist / nearM, 1 / (steps - 1)).toDouble();
    final cols = math.max(40, (w / 4).floor());
    final colW = w / cols;
    final h0 = headingDeg * math.pi / 180;
    final sun = (az: 225 * math.pi / 180, el: 35 * math.pi / 180);
    final sunX = math.sin(sun.az) * math.cos(sun.el), sunY = -math.cos(sun.az) * math.cos(sun.el), sunZ = math.sin(sun.el);
    final paint = Paint()..isAntiAlias = false;
    final d = g.cellM;

    for (var c = 0; c < cols; c++) {
      final off = ((c + 0.5) / cols - 0.5) * (fovDeg * math.pi / 180);
      final a = h0 + off;
      final dx = math.sin(a), dy = -math.cos(a);
      final cosOff = math.cos(off);
      var top = h;
      var dist = nearM;
      for (var k = 0; k < steps && top > 0; k++, dist *= ratio) {
        final px = x + dx * dist, py = y + dy * dist;
        final z = _z(px, py);
        if (z == null) break;
        final depth = dist * cosOff;
        final drop = dist * dist / (2 * marsR);
        final sy = horizonY - focal * (z - drop - eyeZ) / depth;
        if (sy >= top) continue;
        // Normal del relieve por diferencias centrales y sombreado con el sol fijo.
        final zx = (_z(px + d, py) ?? z) - (_z(px - d, py) ?? z);
        final zy = (_z(px, py + d) ?? z) - (_z(px, py - d) ?? z);
        final nx = -zx / (2 * d), ny = -zy / (2 * d);
        final inv = 1 / math.sqrt(nx * nx + ny * ny + 1);
        final lit = ((nx * sunX + ny * sunY + sunZ) * inv).clamp(0.0, 1.0);
        var base = Color.lerp(shadeDark, shadeLight, lit)!;
        // Textura real: el brillo de la ortofoto modula el color (0.5 = sin cambio).
        final tex = ortho?.sample(px, py);
        if (tex != null) base = _scale(base, (1 + 1.8 * (tex - 0.55)).clamp(0.35, 1.7));
        final fog = math.pow(dist / maxDist, 0.6).toDouble().clamp(0.0, 1.0);
        paint.color = Color.lerp(base, haze, fog)!;
        canvas.drawRect(Rect.fromLTRB(c * colW, math.max(0.0, sy), (c + 1) * colW + 0.5, top + 1), paint);
        top = sy;
      }
    }
  }

  static Color _scale(Color c, double f) => Color.from(alpha: 1, red: (c.r * f).clamp(0.0, 1.0), green: (c.g * f).clamp(0.0, 1.0), blue: (c.b * f).clamp(0.0, 1.0));

  @override
  bool shouldRepaint(TerrainPainter old) => !identical(old.ortho, ortho) || old.x != x || old.y != y || old.headingDeg != headingDeg || !identical(old.g, g);
}
