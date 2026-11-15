import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/site_data.dart';
import '../l10n/app_localizations.dart';
import '../routing/routing.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'objective_dialog.dart';
import 'point_info.dart';
import 'tile_layer.dart';

Color routeColor(String profile) => switch (profile) {
      'safe' => AppColors.routeSafe,
      'fast' => AppColors.routeFast,
      'pair2' => AppColors.routeFast,
      _ => AppColors.routeScience,
    };

/// Mapa del recuadro: teselas de la ortofoto, capas de imagen y, encima, rutas y objetivos.
///
/// Trabaja en el plano local en metros. `_scale` son píxeles por metro y `_origin` la posición en pantalla
/// de la esquina noroeste del recuadro. El mapa propio evita depender de una librería de mapas con
/// proyecciones, que aquí no hacen falta.
class MapView extends StatefulWidget {
  const MapView({super.key, this.forceSim = false});

  /// Dibuja siempre al astronauta simulado, aunque el avance sea cero.
  final bool forceSim;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double _scale = 0.25;
  Offset _origin = Offset.zero;
  Size _size = Size.zero;
  bool _fitted = false;

  double _s0 = 1;
  Offset _w0 = Offset.zero;
  String? _dragId;

  /// Punto tocado en el mapa (metros locales) cuyo detalle muestra la tarjeta; null si no hay.
  Offset? _probe;

  /// Origen de la medida de distancia (metros locales), o null.
  Offset? _anchor;
  final ValueNotifier<Offset?> _hover = ValueNotifier(null);
  ui.Image? _forbidden;
  SiteData? _site;

  /// Lado del recuadro del sitio en metros (4000 en Gale).
  double _worldM = 4000;
  final Expando<Path> _pathCache = Expando<Path>();

  double get _minScale => math.min(_size.width, _size.height) / (_site?.base?.sizeM ?? _site?.context?.sizeM ?? _worldM) * 0.8;
  static const double _maxScale = 4.0;

  @override
  void dispose() {
    _hover.dispose();
    _forbidden?.dispose();
    super.dispose();
  }

  void _ensureForbidden(SiteData d) {
    if (identical(_site, d)) return;
    // Sitio nuevo: se rehace la imagen de zonas prohibidas y se reajusta la vista al recuadro.
    _site = d;
    _worldM = d.sizeM;
    _probe = null;
    _anchor = null;
    _fitted = false;
    _forbidden?.dispose();
    _forbidden = null;
    final g = d.grid;
    final px = Uint8List(g.width * g.height * 4);
    for (var i = 0; i < g.blocked.length; i++) {
      if (g.blocked[i] != 0) {
        final o = i * 4;
        final stripe = ((i % g.width) + (i ~/ g.width)) % 3 == 0;
        px[o] = 0xE7;
        px[o + 1] = 0x4C;
        px[o + 2] = 0x3C;
        px[o + 3] = stripe ? 120 : 235;
      }
    }
    ui.decodeImageFromPixels(px, g.width, g.height, ui.PixelFormat.rgba8888, (img) {
      if (mounted && identical(_site, d)) {
        setState(() => _forbidden = img);
      } else {
        img.dispose();
      }
    });
  }

  void _fit() {
    final s = math.min(_size.width, _size.height) / _worldM * 0.96;
    _scale = s;
    _origin = Offset((_size.width - _worldM * s) / 2, (_size.height - _worldM * s) / 2);
  }

  Offset _toWorld(Offset p) => (p - _origin) / _scale;

  Offset _toScreen(double x, double y) => Offset(_origin.dx + x * _scale, _origin.dy + y * _scale);

  void _zoomAt(Offset focal, double factor) {
    final ns = (_scale * factor).clamp(_minScale, _maxScale);
    final w = _toWorld(focal);
    setState(() {
      _scale = ns;
      _origin = focal - w * ns;
    });
  }

  String? _hitObjective(AppModel m, Offset p) {
    String? best;
    var bestD = 22.0;
    for (final o in m.objectives) {
      final d = (_toScreen(o.xM, o.yM) - p).distance;
      if (d < bestD) {
        bestD = d;
        best = o.id;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    _ensureForbidden(m.data);
    return LayoutBuilder(builder: (context, c) {
      _size = c.biggest;
      if (!_fitted && _size.width > 0) {
        _fit();
        _fitted = true;
      }
      return Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) _zoomAt(e.localPosition, math.exp(-e.scrollDelta.dy / 400));
        },
        child: MouseRegion(
          onHover: (e) => _hover.value = e.localPosition,
          onExit: (_) => _hover.value = null,
          cursor: m.addMode ? SystemMouseCursors.precise : SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (d) {
              final hit = d.pointerCount == 1 ? _hitObjective(m, d.localFocalPoint) : null;
              if (hit != null && !m.addMode) {
                _dragId = hit;
                m.selectObjective(hit);
              } else {
                _s0 = _scale;
                _w0 = _toWorld(d.localFocalPoint);
              }
            },
            onScaleUpdate: (d) {
              if (_dragId != null) {
                final w = _toWorld(d.localFocalPoint);
                m.moveObjectiveLive(_dragId!, w.dx.clamp(0.0, m.data.sizeM - 1), w.dy.clamp(0.0, m.data.sizeM - 1));
              } else {
                final ns = (_s0 * d.scale).clamp(_minScale, _maxScale);
                setState(() {
                  _scale = ns;
                  _origin = d.localFocalPoint - _w0 * ns;
                });
              }
            },
            onScaleEnd: (d) {
              if (_dragId != null) {
                _dragId = null;
                m.finishMove();
              }
            },
            // Con el dedo no hay cursor: la lectura de abajo sigue al último toque o pulsación larga.
            onLongPressStart: (d) => _hover.value = d.localPosition,
            onLongPressMoveUpdate: (d) => _hover.value = d.localPosition,
            onTapUp: (d) {
              _hover.value = d.localPosition;
              final w = _toWorld(d.localPosition);
              if (m.addMode) {
                if (w.dx >= 0 && w.dy >= 0 && w.dx < m.data.sizeM && w.dy < m.data.sizeM) {
                  m.setAddMode(false);
                  showObjectiveDialog(context, m, null, x: w.dx, y: w.dy);
                }
                return;
              }
              final hit = _hitObjective(m, d.localPosition);
              m.selectObjective(hit);
              if (hit != null) {
                setState(() => _probe = null);
                showObjectiveDialog(context, m, hit);
              } else {
                setState(() => _probe = w);
              }
            },
            child: ClipRect(
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
                  _world(m),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OverlayPainter(
                        model: m,
                        scale: _scale,
                        origin: _origin,
                        pathCache: _pathCache,
                        habitatLabel: l.habitat,
                        pnrLabel: l.pnrShort,
                        frameLabel: l.routeAreaLabel,
                        showSim: widget.forceSim || m.simActive,
                        probe: _probe,
                        anchor: _anchor,
                      ),
                    ),
                  ),
                  Positioned(left: 12, top: 12, child: _toolbar(l)),
                  if (m.addMode) Positioned(top: 12, left: 0, right: 0, child: Center(child: _banner(l.objectivesAddActive))),
                  if (m.computing) Positioned(top: 12, left: 0, right: 0, child: Center(child: _banner(l.computing, color: AppColors.amber))),
                  if (_probe != null)
                    Positioned(
                      right: 12,
                      top: 52,
                      bottom: 64,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: PointInfoCard(
                          model: m,
                          x: _probe!.dx,
                          y: _probe!.dy,
                          anchor: _anchor,
                          onAnchor: () => setState(() => _anchor = _anchor == null ? _probe : null),
                          onClose: () => setState(() => _probe = null),
                          onCreate: () {
                            final p = _probe!;
                            setState(() => _probe = null);
                            showObjectiveDialog(context, m, null, x: p.dx, y: p.dy);
                          },
                        ),
                      ),
                    ),
                  Positioned(left: 12, bottom: 12, child: _readout(m, l)),
                  Positioned(right: 12, bottom: 12, child: _scaleBar()),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _banner(String text, {Color color = AppColors.cyan}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: AppColors.panel.withValues(alpha: 0.92), border: Border.all(color: color)),
        child: Text(text, style: AppText.label(color: color)),
      );

  Widget _toolbar(AppLocalizations l) {
    Widget btn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 18, color: AppColors.text)),
          ),
        );
    final center = Offset(_size.width / 2, _size.height / 2);
    return Container(
      decoration: BoxDecoration(color: AppColors.panel.withValues(alpha: 0.92), border: Border.all(color: AppColors.hairline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn(Icons.add, l.zoomIn, () => _zoomAt(center, 1.5)),
        btn(Icons.remove, l.zoomOut, () => _zoomAt(center, 1 / 1.5)),
        btn(Icons.center_focus_strong_outlined, l.zoomFit, () => setState(_fit)),
      ]),
    );
  }

  Widget _readout(AppModel m, AppLocalizations l) {
    final f = Fmt(m.locale);
    return ValueListenableBuilder<Offset?>(
      valueListenable: _hover,
      builder: (context, h, _) {
        var text = l.hintDrag;
        if (h != null) {
          final w = _toWorld(h);
          if (w.dx >= 0 && w.dy >= 0 && w.dx < m.data.sizeM && w.dy < m.data.sizeM) {
            final (lon, lat) = m.data.lonLat(w.dx, w.dy);
            final z = m.data.elevationAt(w.dx, w.dy);
            final s = m.data.slopeAt(w.dx, w.dy);
            text = '${f.latLon(lon, lat)}  ·  ${l.elevation} ${z == null ? '-' : f.num(z, 0)} m  ·  ${s == null ? '-' : f.num(s, 0)}°';
          }
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: AppColors.panel.withValues(alpha: 0.92), border: Border.all(color: AppColors.hairline)),
          child: Text(text, style: AppText.mono(11, color: AppColors.textDim)),
        );
      },
    );
  }

  Widget _scaleBar() {
    const nice = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000];
    var meters = nice.first;
    for (final n in nice) {
      if (n * _scale <= 150) meters = n;
    }
    final px = meters * _scale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.panel.withValues(alpha: 0.92), border: Border.all(color: AppColors.hairline)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: px,
          height: 6,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.text),
              right: BorderSide(color: AppColors.text),
              bottom: BorderSide(color: AppColors.text),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(meters >= 1000 ? '${meters ~/ 1000} km' : '$meters m', style: AppText.mono(10, color: AppColors.textDim)),
      ]),
    );
  }

  int _zoomLevel(SiteData d) {
    // El nivel 0 tiene `tileMPerPx[0]` metros por píxel (8 en Gale); se elige el nivel cuyo píxel se acerca más al de la pantalla.
    final z = (math.log(d.tileMPerPx[0] * _scale) / math.ln2).round();
    return z.clamp(0, d.tileCount - 1);
  }

  List<Widget> _tiles(SiteData d, int z) => tileWidgets(
        d,
        z,
        -_origin.dx / _scale,
        -_origin.dy / _scale,
        (_size.width - _origin.dx) / _scale,
        (_size.height - _origin.dy) / _scale,
      );

  /// Teselas de un marco (contexto o mapa base) visibles, en el nivel que se acerca más al píxel de la pantalla.
  List<Widget> _frameTiles(SiteData d, ContextTiles c) {
    final z = (math.log(c.tileMPerPx[0] * _scale) / math.ln2).round().clamp(0, c.maxZoom);
    return contextTileWidgets(
      d,
      c,
      z,
      -_origin.dx / _scale,
      -_origin.dy / _scale,
      (_size.width - _origin.dx) / _scale,
      (_size.height - _origin.dy) / _scale,
    );
  }

  Widget _world(AppModel m) {
    final d = m.data;
    final z = _zoomLevel(d);
    final optical = m.layers['optical']!;
    final hill = m.layers['hillshade']!;
    final thermal = m.layers['thermal']!;
    final slope = m.layers['slope']!;
    final forb = m.layers['forbidden']!;
    final tnight = m.layers['thermal_night']!;
    final transit = m.layers['transit']!;
    final slope15 = m.layers['slope15']!;
    Widget image(String asset, double opacity) => Positioned(
          left: 0,
          top: 0,
          width: d.sizeM,
          height: d.sizeM,
          child: Opacity(
            opacity: opacity,
            child: Image.asset(asset, fit: BoxFit.fill, filterQuality: FilterQuality.medium, gaplessPlayback: true),
          ),
        );
    return Positioned.fill(
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(_origin.dx, _origin.dy, 0, 1)
          ..scaleByDouble(_scale, _scale, 1, 1),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: d.sizeM,
          maxHeight: d.sizeM,
          child: SizedBox(
            width: d.sizeM,
            height: d.sizeM,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (optical.visible && d.base != null)
                  Positioned.fill(
                    child: Opacity(opacity: optical.opacity, child: Stack(clipBehavior: Clip.none, children: _frameTiles(d, d.base!))),
                  ),
                if (optical.visible && d.context != null)
                  Positioned.fill(
                    child: Opacity(opacity: optical.opacity, child: Stack(clipBehavior: Clip.none, children: _frameTiles(d, d.context!))),
                  ),
                if (optical.visible) ...[
                  // La ortofoto de detalle se recorta a la ventana: sus teselas traen un relleno negro en el borde este y sur.
                  Positioned.fill(
                    child: ClipRect(
                      child: Opacity(opacity: optical.opacity, child: Stack(clipBehavior: Clip.none, children: [..._tiles(d, math.min(1, d.tileCount - 1)), if (z > 1) ..._tiles(d, z)])),
                    ),
                  ),
                ],
                if (thermal.visible) image(d.assetPath('layers/thermal.png'), thermal.opacity),
                if (tnight.visible) image(d.assetPath('layers/thermal_night.png'), tnight.opacity),
                if (transit.visible) image(d.assetPath('layers/transit.png'), transit.opacity),
                if (hill.visible) image(d.assetPath('layers/hillshade.png'), hill.opacity),
                if (slope.visible) image(d.assetPath('layers/slope.png'), slope.opacity),
                if (slope15.visible) image(d.assetPath('layers/slope15.png'), slope15.opacity),
                if (forb.visible && _forbidden != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: d.sizeM,
                    height: d.sizeM,
                    child: Opacity(opacity: forb.opacity, child: RawImage(image: _forbidden, fit: BoxFit.fill, filterQuality: FilterQuality.none)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.model,
    required this.scale,
    required this.origin,
    required this.pathCache,
    required this.habitatLabel,
    required this.pnrLabel,
    required this.frameLabel,
    required this.showSim,
    this.probe,
    this.anchor,
  });

  final AppModel model;
  final double scale;
  final Offset origin;
  final Expando<Path> pathCache;
  final String habitatLabel;
  final String pnrLabel;
  final String frameLabel;
  final bool showSim;

  /// Punto tocado, en metros locales.
  final Offset? probe;

  /// Origen de la medida, en metros locales.
  final Offset? anchor;

  Offset _p(double x, double y) => Offset(origin.dx + x * scale, origin.dy + y * scale);

  Path _routePath(RouteResult r) {
    var p = pathCache[r];
    if (p == null) {
      final g = model.data.grid;
      p = Path();
      var first = true;
      for (final c in r.cells) {
        final (x, y) = g.xy(c);
        if (first) {
          p.moveTo(x, y);
          first = false;
        } else {
          p.lineTo(x, y);
        }
      }
      pathCache[r] = p;
    }
    return p;
  }

  void _label(Canvas canvas, String text, Offset at, {Color color = AppColors.text, Color border = AppColors.hairline, bool alignRight = false}) {
    final tp = TextPainter(text: TextSpan(text: text, style: AppText.mono(10, color: color, weight: FontWeight.w600)), textDirection: TextDirection.ltr)
      ..layout();
    if (alignRight) at = Offset(at.dx - tp.width - 10, at.dy);
    final r = Rect.fromLTWH(at.dx, at.dy, tp.width + 10, tp.height + 6);
    canvas.drawRect(r, Paint()..color = AppColors.panel.withValues(alpha: 0.9));
    canvas.drawRect(r, Paint()..color = border..style = PaintingStyle.stroke);
    tp.paint(canvas, at + const Offset(5, 3));
  }

  static const _unitPalette = [Color(0xFF8E6BBF), Color(0xFF4FA3A5), Color(0xFFC9A227), Color(0xFFB5543C), Color(0xFF5B8C3A), Color(0xFF4F7FBF), Color(0xFFBF6B9E), Color(0xFF9A9A6B)];

  /// Recuadro punteado de la ventana de cálculo de rutas, cuando el sitio trae un marco de contexto más grande.
  void _frame(Canvas canvas, SiteData d) {
    if (d.context == null) return;
    final r = Rect.fromPoints(_p(0, 0), _p(d.sizeM, d.sizeM));
    final paint = Paint()..color = AppColors.text.withValues(alpha: 0.85)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    void dashed(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (var s = 0.0; s < len; s += 14) {
        canvas.drawLine(a + dir * s, a + dir * math.min(s + 8, len), paint);
      }
    }

    dashed(r.topLeft, r.topRight);
    dashed(r.topRight, r.bottomRight);
    dashed(r.bottomRight, r.bottomLeft);
    dashed(r.bottomLeft, r.topLeft);
    // arriba a la derecha: arriba a la izquierda están los botones de zoom
    _label(canvas, frameLabel, r.topRight + const Offset(-8, 8), alignRight: true);
  }

  /// Unidades geológicas y dunas (capa `geology`), cráteres (`craters`) y nombres (`names`).
  void _context(Canvas canvas, SiteData d, Size size) {
    final geo = model.layers['geology']!;
    if (geo.visible) {
      final units = <String>[];
      for (final a in d.vectors.areas) {
        if (a.rings.isEmpty) continue;
        final path = Path()..fillType = PathFillType.evenOdd;
        for (final ring in a.rings) {
          for (var i = 0; i < ring.length; i++) {
            final o = _p(ring[i].$1, ring[i].$2);
            i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
          }
          path.close();
        }
        final dune = a.kind == 'landform';
        if (!units.contains(a.unit)) units.add(a.unit);
        final color = dune ? const Color(0xFFE6AA28) : _unitPalette[d.vectors.areas.map((x) => x.unit).toSet().toList().indexOf(a.unit) % _unitPalette.length];
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: (dune ? 0.45 : 0.22) * geo.opacity));
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.9 * geo.opacity)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        final first = a.rings.first;
        var cx = 0.0, cy = 0.0;
        for (final p in first) {
          cx += p.$1;
          cy += p.$2;
        }
        final at = _p(cx / first.length, cy / first.length);
        if (!dune && (Offset.zero & size).contains(at)) _label(canvas, a.unit, at, color: color, border: color);
      }
    }
    final cr = model.layers['craters']!;
    if (cr.visible) {
      final stroke = Paint()..color = AppColors.text.withValues(alpha: 0.8 * cr.opacity)..style = PaintingStyle.stroke..strokeWidth = 1.3;
      for (final c in d.vectors.craters) {
        final rad = c.diameterM / 2 * scale;
        if (rad < 2.5) continue;
        canvas.drawCircle(_p(c.x, c.y), rad, stroke);
      }
    }
    final nm = model.layers['names']!;
    if (nm.visible) {
      for (final n in d.vectors.names) {
        final c = _p(n.x, n.y);
        canvas.drawCircle(c, 3.5, Paint()..color = AppColors.text.withValues(alpha: nm.opacity));
        _label(canvas, n.type.isEmpty ? n.name : '${n.name} · ${n.type}', c + const Offset(8, -9));
      }
    }
  }

  /// Minerales y zonas de exploración del sitio (capas `minerals_pts` y `zones`).
  void _vectors(Canvas canvas, SiteData d) {
    final zones = model.layers['zones']!;
    if (zones.visible) {
      final a = zones.opacity;
      for (final z in d.vectors.zones) {
        final ring = z.ring;
        if (ring != null) {
          final path = Path();
          for (var i = 0; i < ring.length; i++) {
            final o = _p(ring[i].$1, ring[i].$2);
            i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
          }
          path.close();
          final roi = z.type == 'roi';
          canvas.drawPath(
            path,
            Paint()
              ..color = (roi ? AppColors.amber : AppColors.text).withValues(alpha: (roi ? 0.95 : 0.55) * a)
              ..style = PaintingStyle.stroke
              ..strokeWidth = roi ? 1.6 : 1.0,
          );
        }
      }
      for (final z in d.vectors.zones) {
        if (z.x == null || z.y == null) continue;
        final c = _p(z.x!, z.y!);
        final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0;
        switch (z.type) {
          case 'habitation':
            line.color = AppColors.green.withValues(alpha: a);
            canvas.drawRect(Rect.fromCenter(center: c, width: 14, height: 14), line);
          case 'landing':
            line.color = AppColors.text.withValues(alpha: a);
            canvas.drawPath(Path()..moveTo(c.dx, c.dy - 8)..lineTo(c.dx + 7, c.dy + 6)..lineTo(c.dx - 7, c.dy + 6)..close(), line);
          default:
            line.color = AppColors.cyan.withValues(alpha: a);
            canvas.drawCircle(c, 7, line);
        }
        if (z.name.isNotEmpty) _label(canvas, z.name, c + const Offset(10, -8));
      }
    }
    // Redes de valles (Hynek 2010): búsqueda de biofirmas.
    final valleys = model.layers['valleys']!;
    if (valleys.visible && d.vectors.valleys.isNotEmpty) {
      final line = Paint()
        ..color = kValleyColor.withValues(alpha: valleys.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round;
      for (final v in d.vectors.valleys) {
        for (final pts in v.paths) {
          final path = Path();
          for (var i = 0; i < pts.length; i++) {
            final o = _p(pts[i].$1, pts[i].$2);
            i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
          }
          canvas.drawPath(path, line);
        }
      }
    }
    // Minerales de las capas de biofirmas: acuosos con más probabilidad de conservarlas (filosilicatos y carbonatos) e hidratados.
    final aqueous = model.layers['aqueous_pts']!;
    final hydrous = model.layers['hydrous_pts']!;
    if (aqueous.visible || hydrous.visible) {
      for (final q in d.vectors.minerals) {
        final layer = q.cls == 'hydrous' ? hydrous : aqueous;
        if (!layer.visible || !kMineralColors.containsKey(q.cls)) continue;
        final c = _p(q.x, q.y);
        final color = kMineralColors[q.cls]!.withValues(alpha: layer.opacity);
        final diamond = Path()..moveTo(c.dx, c.dy - 6)..lineTo(c.dx + 6, c.dy)..lineTo(c.dx, c.dy + 6)..lineTo(c.dx - 6, c.dy)..close();
        canvas.drawPath(diamond, Paint()..color = color);
        canvas.drawPath(diamond, Paint()..color = AppColors.bg..style = PaintingStyle.stroke..strokeWidth = 1.2);
      }
    }
    final minerals = model.layers['minerals_pts']!;
    if (minerals.visible) {
      for (final q in d.vectors.minerals) {
        // Un punto que ya dibuja una capa de biofirmas encendida no se dibuja otra vez aquí.
        if (q.cls == 'hydrous' ? hydrous.visible : (aqueous.visible && kMineralColors.containsKey(q.cls))) continue;
        final c = _p(q.x, q.y);
        final color = switch (q.cls) {
          'sulfate' => const Color(0xFFE6AA28),
          'phyllosilicate' => const Color(0xFFD63DA8),
          _ => AppColors.cyan,
        }
            .withValues(alpha: minerals.opacity);
        final diamond = Path()..moveTo(c.dx, c.dy - 6)..lineTo(c.dx + 6, c.dy)..lineTo(c.dx, c.dy + 6)..lineTo(c.dx - 6, c.dy)..close();
        canvas.drawPath(diamond, Paint()..color = color);
        canvas.drawPath(diamond, Paint()..color = AppColors.bg..style = PaintingStyle.stroke..strokeWidth = 1.2);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = model.data;
    // Recorrido real de Curiosity.
    // En Meridiani el recorrido del rover es el de Opportunity (capa propia); en Gale, el de Curiosity.
    final opp = model.layerDefs.any((x) => x.id == 'opportunity');
    final cur = model.layers[opp ? 'opportunity' : 'curiosity']!;
    final gap = opp ? 400.0 : 120.0;
    if (cur.visible) {
      final a = cur.opacity;
      final line = Paint()..color = AppColors.text.withValues(alpha: 0.5 * a)..style = PaintingStyle.stroke..strokeWidth = 1.2;
      final camp = Paint()..color = AppColors.cyan.withValues(alpha: 0.9 * a)..style = PaintingStyle.stroke..strokeWidth = 1.8;
      CuriosityPoint? prev;
      for (final pt in d.curiosity) {
        if (prev != null && math.sqrt(math.pow(pt.x - prev.x, 2) + math.pow(pt.y - prev.y, 2)) < gap) {
          canvas.drawLine(_p(prev.x, prev.y), _p(pt.x, pt.y), pt.campaign && prev.campaign ? camp : line);
        }
        prev = pt;
      }
    }

    _context(canvas, d, size);
    _frame(canvas, d);
    _vectors(canvas, d);

    // Rutas: las no seleccionadas atenuadas.
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    for (final sel in [false, true]) {
      for (final e in model.routes.entries) {
        final isSel = e.key == model.selectedRoute;
        if (isSel != sel || e.value.cells.isEmpty) continue;
        final color = routeColor(e.key);
        final casing = Paint()
          ..color = AppColors.bg.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (isSel ? 7.0 : 5.0) / scale;
        final stroke = Paint()
          ..color = color.withValues(alpha: isSel ? 1.0 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (isSel ? 3.5 : 2.2) / scale;
        final path = _routePath(e.value);
        canvas.drawPath(path, casing);
        canvas.drawPath(path, stroke);
      }
    }
    canvas.restore();

    // Punto de no retorno de la ruta seleccionada.
    final r = model.route;
    if (r != null && r.metrics != null && r.cells.isNotEmpty) {
      final nr = r.metrics!.noReturn;
      final c = _p(nr.xM, nr.yM);
      canvas.drawCircle(c, 8, Paint()..color = AppColors.amber..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(c, 2.5, Paint()..color = AppColors.amber);
      _label(canvas, pnrLabel, c + const Offset(12, -9), color: AppColors.amber, border: AppColors.amber);
    }

    // Hábitat.
    final h = _p(d.habitatX, d.habitatY);
    final hr = Rect.fromCenter(center: h, width: 18, height: 18);
    canvas.drawRect(hr, Paint()..color = AppColors.panel.withValues(alpha: 0.9));
    canvas.drawRect(hr, Paint()..color = AppColors.green..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(h, 2.5, Paint()..color = AppColors.green);
    _label(canvas, habitatLabel, h + const Offset(14, -9), color: AppColors.green, border: AppColors.green);

    // Objetivos.
    final visited = r?.visited.toSet() ?? const <String>{};
    for (final o in model.objectives) {
      final c = _p(o.xM, o.yM);
      final blocked = d.isBlocked(o.xM, o.yM);
      final sel = model.selectedObjective == o.id;
      final color = blocked ? AppColors.red : AppColors.cyan;
      final dia = Path()
        ..moveTo(c.dx, c.dy - 10)
        ..lineTo(c.dx + 10, c.dy)
        ..lineTo(c.dx, c.dy + 10)
        ..lineTo(c.dx - 10, c.dy)
        ..close();
      canvas.drawPath(dia, Paint()..color = AppColors.panel.withValues(alpha: 0.9));
      canvas.drawPath(dia, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sel ? 3 : 2);
      if (visited.contains(o.id)) canvas.drawCircle(c, 3, Paint()..color = color);
      if (sel) canvas.drawCircle(c, 16, Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1);
      _label(canvas, '${o.id.toUpperCase()} · P${o.priority}', c + const Offset(14, -9), color: color, border: color);
    }

    // Astronauta simulado: tramo recorrido y marcador con el rumbo.
    final sim = showSim ? model.simPos : null;
    if (r != null && sim != null) {
      final g = d.grid;
      final trail = Path();
      for (var k = 0; k <= sim.cellIndex; k++) {
        final (x, y) = g.xy(r.cells[k]);
        k == 0 ? trail.moveTo(_p(x, y).dx, _p(x, y).dy) : trail.lineTo(_p(x, y).dx, _p(x, y).dy);
      }
      final here = _p(sim.xM, sim.yM);
      trail.lineTo(here.dx, here.dy);
      canvas.drawPath(trail, Paint()..color = AppColors.bg.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 7..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
      canvas.drawPath(trail, Paint()..color = AppColors.cyan..style = PaintingStyle.stroke..strokeWidth = 4..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
      canvas.drawCircle(here, 15, Paint()..color = AppColors.cyan.withValues(alpha: 0.18));
      canvas.drawCircle(here, 15, Paint()..color = AppColors.cyan..style = PaintingStyle.stroke..strokeWidth = 1);
      // Flecha del rumbo (0° = norte, hacia arriba).
      final a = sim.headingDeg * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      final side = Offset(-dir.dy, dir.dx);
      final arrow = Path()
        ..moveTo(here.dx + dir.dx * 11, here.dy + dir.dy * 11)
        ..lineTo(here.dx - dir.dx * 7 + side.dx * 7, here.dy - dir.dy * 7 + side.dy * 7)
        ..lineTo(here.dx - dir.dx * 3, here.dy - dir.dy * 3)
        ..lineTo(here.dx - dir.dx * 7 - side.dx * 7, here.dy - dir.dy * 7 - side.dy * 7)
        ..close();
      canvas.drawPath(arrow, Paint()..color = AppColors.cyan);
      canvas.drawPath(arrow, Paint()..color = AppColors.bg..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    _probeMark(canvas);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => true;

  /// Mira sobre el punto tocado.
  void _probeMark(Canvas canvas) {
    final q = probe;
    final a0 = anchor;
    if (a0 != null) {
      final a = _p(a0.dx, a0.dy);
      final amber = Paint()..color = AppColors.amber..style = PaintingStyle.stroke..strokeWidth = 2;
      if (q != null) canvas.drawLine(a, _p(q.dx, q.dy), amber);
      canvas.drawCircle(a, 6, Paint()..color = AppColors.amber);
      canvas.drawCircle(a, 6, Paint()..color = AppColors.bg..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    if (q == null) return;
    final c = _p(q.dx, q.dy);
    final paint = Paint()..color = AppColors.cyan..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(c, 9, Paint()..color = AppColors.bg.withValues(alpha: 0.55));
    canvas.drawCircle(c, 9, paint);
    canvas.drawLine(c + const Offset(-16, 0), c + const Offset(-5, 0), paint);
    canvas.drawLine(c + const Offset(5, 0), c + const Offset(16, 0), paint);
    canvas.drawLine(c + const Offset(0, -16), c + const Offset(0, -5), paint);
    canvas.drawLine(c + const Offset(0, 5), c + const Offset(0, 16), paint);
  }
}
