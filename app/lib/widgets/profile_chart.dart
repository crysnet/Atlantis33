import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../routing/routing.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'common.dart';
import 'map_view.dart' show routeColor;

/// Perfil de elevación de la ruta seleccionada, coloreado por clase de pendiente.
class ProfileChart extends StatelessWidget {
  const ProfileChart({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final r = m.route;
    return Container(
      height: 150,
      decoration: const BoxDecoration(color: AppColors.panel, border: Border(top: BorderSide(color: AppColors.hairline))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Row(children: [
            Icon(Icons.show_chart, size: 15, color: AppColors.textDim),
            const SizedBox(width: 8),
            Text(l.profileTitle, style: AppText.head(12)),
            const SizedBox(width: 12),
            if (r != null && r.metrics != null) ...[
              Container(width: 10, height: 3, color: routeColor(r.profile)),
              const SizedBox(width: 6),
              Text(routeName(l, r.profile).toUpperCase(), style: AppText.label(color: routeColor(r.profile))),
              const SizedBox(width: 12),
              Flexible(
                child: Text('${f.km(r.metrics!.distanceM)}  ·  ${l.metricMaxSlope} ${f.num(r.metrics!.maxSlopeDeg, 0)}°  ·  +${f.num(r.metrics!.ascentM, 0)} m / −${f.num(r.metrics!.descentM, 0)} m',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.mono(10.5, color: AppColors.textDim)),
              ),
            ],
            const Spacer(),
            _legendDot(AppColors.slopeNominal, '<10°'),
            _legendDot(AppColors.slopeCaution, '10–20°'),
            _legendDot(AppColors.slopeHigh, '20–25°'),
          ]),
        ),
        Expanded(
          child: r == null || r.cells.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ProfilePainter(m, r, f, l.habitat, l.pnrShort),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _legendDot(Color c, String t) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(children: [
          Container(width: 8, height: 8, color: c),
          const SizedBox(width: 4),
          Text(t, style: AppText.mono(10, color: AppColors.textDim)),
        ]),
      );
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.model, this.route, this.f, this.habitatLabel, this.pnrLabel);

  final AppModel model;
  final RouteResult route;
  final Fmt f;
  final String habitatLabel;
  final String pnrLabel;

  Color _slopeColor(double s) {
    final mod = model.data.model;
    if (s < mod.slopeNominalMax) return AppColors.slopeNominal;
    if (s < mod.slopeCautionMax) return AppColors.slopeCaution;
    if (s <= 25) return AppColors.slopeHigh;
    return AppColors.slopeForbidden;
  }

  void _text(Canvas c, String t, Offset at, {Color color = AppColors.textDim, TextAlign align = TextAlign.left, double width = 80}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: AppText.mono(9.5, color: color)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: width);
    final dx = align == TextAlign.right ? at.dx - tp.width : (align == TextAlign.center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(c, Offset(dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = model.data.grid;
    final cells = route.cells;
    if (cells.length < 2) return;
    const left = 46.0, right = 14.0, top = 10.0, bottom = 18.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    final dist = List<double>.filled(cells.length, 0);
    var zmin = double.infinity, zmax = -double.infinity;
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) {
        final a = cells[i - 1], b = cells[i];
        final diag = (a ~/ g.width != b ~/ g.width) && (a % g.width != b % g.width);
        dist[i] = dist[i - 1] + g.cellM * (diag ? math.sqrt2 : 1.0);
      }
      zmin = math.min(zmin, g.z[cells[i]]);
      zmax = math.max(zmax, g.z[cells[i]]);
    }
    final total = dist.last;
    final span = math.max(zmax - zmin, 10.0);
    final pad = span * 0.1;
    final lo = zmin - pad, hi = zmax + pad;
    Offset pt(int i) => Offset(left + dist[i] / total * w, top + (1 - (g.z[cells[i]] - lo) / (hi - lo)) * h);

    // Rejilla y ejes.
    final grid = Paint()..color = AppColors.hairline..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = top + h * k / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _text(canvas, f.num(hi - (hi - lo) * k / 4, 0), Offset(left - 6, y - 6), align: TextAlign.right, width: 40);
    }
    final kmStep = total > 6000 ? 1000.0 : 500.0;
    for (var d = 0.0; d <= total; d += kmStep) {
      final x = left + d / total * w;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), grid);
      _text(canvas, f.num(d / 1000, 1), Offset(x - 12, top + h + 3), align: TextAlign.center, width: 30);
    }
    _text(canvas, 'km', Offset(left + w + 2, top + h + 3), width: 20);

    // Área bajo la línea.
    final area = Path()..moveTo(pt(0).dx, top + h);
    for (var i = 0; i < cells.length; i++) {
      area.lineTo(pt(i).dx, pt(i).dy);
    }
    area.lineTo(pt(cells.length - 1).dx, top + h);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.orange.withValues(alpha: 0.22), AppColors.orange.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );

    // Línea coloreada por la pendiente de cada celda.
    final line = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (var i = 1; i < cells.length; i++) {
      line.color = _slopeColor(g.slopeReal[cells[i]]);
      canvas.drawLine(pt(i - 1), pt(i), line);
    }

    // Paradas en objetivos.
    final index = <int, int>{};
    for (var i = 0; i < cells.length; i++) {
      index[cells[i]] = i;
    }
    for (final id in route.visited) {
      final o = model.objective(id);
      if (o == null) continue;
      final i = index[g.cellOf(o.xM, o.yM)];
      if (i == null) continue;
      final p = pt(i);
      canvas.drawLine(Offset(p.dx, top), Offset(p.dx, top + h), Paint()..color = AppColors.cyan.withValues(alpha: 0.7)..strokeWidth = 1);
      canvas.drawCircle(p, 4, Paint()..color = AppColors.cyan);
      _text(canvas, id.toUpperCase(), Offset(p.dx + 4, top + 1), color: AppColors.cyan, width: 30);
    }

    // Punto de no retorno.
    final nr = route.metrics!.noReturn.index;
    if (nr >= 0 && nr < cells.length) {
      final p = pt(nr);
      canvas.drawLine(Offset(p.dx, top), Offset(p.dx, top + h), Paint()..color = AppColors.amber..strokeWidth = 1.2);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.amber..style = PaintingStyle.stroke..strokeWidth = 2);
      _text(canvas, pnrLabel, Offset(p.dx + 6, top + h - 14), color: AppColors.amber, width: 30);
    }
    _text(canvas, habitatLabel, Offset(left + 3, top + 1), color: AppColors.green, width: 60);
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => true;
}
