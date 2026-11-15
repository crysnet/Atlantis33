import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/environment_data.dart';
import '../l10n/app_localizations.dart';
import '../routing/routing.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../util/route_utils.dart';
import '../widgets/common.dart';
import '../widgets/map_view.dart' show routeColor;

Color _levelColor(CheckLevel v) => switch (v) {
      CheckLevel.go => AppColors.green,
      CheckLevel.caution => AppColors.amber,
      CheckLevel.noGo => AppColors.red,
      CheckLevel.pending => AppColors.textMute,
    };

String _levelText(AppLocalizations l, CheckLevel v) => switch (v) {
      CheckLevel.go => l.safeGo,
      CheckLevel.caution => l.safeCaution,
      CheckLevel.noGo => l.safeNoGo,
      CheckLevel.pending => l.safePending,
    };

/// Hora marciana (LMST) por hora terrestre: un sol dura 24.66 horas terrestres.
const double _lmstPerEarthHour = 24.0 / 24.6598;

/// Verificaciones de salida. Radiación y clima usan datos reales de RAD y REMS del sol elegido;
/// terreno y consumibles salen del modelo de rutas; el polvo no tiene datos.
class _Checks {
  _Checks(this.levels, this.weather);

  final Map<String, CheckLevel> levels;
  final WeatherCheck weather;
}

_Checks _computeChecks(AppModel m) {
  final d = m.data;
  final r = m.route;
  final met = r?.metrics;
  var terrain = CheckLevel.pending;
  var cons = CheckLevel.pending;
  if (r != null) {
    if (met == null) {
      terrain = CheckLevel.noGo;
      cons = CheckLevel.noGo;
    } else {
      terrain = met.maxSlopeDeg >= d.model.slopeCautionMax ? CheckLevel.caution : CheckLevel.go;
      cons = !met.feasible ? CheckLevel.noGo : (isComfortable(d.model, met) ? CheckLevel.go : CheckLevel.caution);
    }
  }
  final window = (met?.totalH ?? 0) * _lmstPerEarthHour;
  final wx = met == null
      ? const WeatherCheck(level: CheckLevel.pending, hoursInWindow: 0)
      : d.environment.weatherCheck(m.envSol, d.envConfig, window);
  return _Checks({
    'rad': d.environment.radiationLevel(m.envSol, d.envConfig),
    'weather': wx.level,
    'dust': CheckLevel.pending,
    'terrain': terrain,
    'consumables': cons,
  }, wx);
}

/// Seguridad de la salida: estado por verificación, radiación y clima reales, terreno y consumibles.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final checks = _computeChecks(m);
    final levels = checks.levels;
    final real = levels.values.where((v) => v != CheckLevel.pending).length;
    final CheckLevel overall;
    if (levels.values.contains(CheckLevel.noGo)) {
      overall = CheckLevel.noGo;
    } else if (levels.values.contains(CheckLevel.caution)) {
      overall = CheckLevel.caution;
    } else if (real < 5) {
      overall = CheckLevel.pending;
    } else {
      overall = CheckLevel.go;
    }
    final (overallText, overallColor) = overall == CheckLevel.pending ? (l.safeIncomplete, AppColors.amber) : (_levelText(l, overall), _levelColor(overall));
    final r = m.route;
    final chips = [
      ('rad', l.checkRad),
      ('weather', l.checkWeather),
      ('dust', l.checkDust),
      ('terrain', l.checkTerrain),
      ('consumables', l.checkConsumables),
    ];
    return ListView(padding: const EdgeInsets.all(14), children: [
      Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: overallColor.withValues(alpha: 0.12), border: Border.all(color: overallColor)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: overallColor, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text('${l.safeOverall}: $overallText', style: AppText.head(14, color: overallColor)),
          ]),
        ),
        for (final (id, label) in chips) Tag('$label: ${_levelText(l, levels[id]!)}', color: _levelColor(levels[id]!), filled: true),
        Text(l.safeRealChecks(real), style: AppText.mono(10.5, color: AppColors.textMute)),
        const SizedBox(width: 20),
        for (final id in m.routeIds)
          InkWell(
            onTap: () => m.selectRoute(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: m.selectedRoute == id ? AppColors.panel3 : Colors.transparent,
                border: Border.all(color: m.selectedRoute == id ? routeColor(id) : AppColors.hairline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 3, color: routeColor(id)),
                const SizedBox(width: 8),
                Text(routeName(l, id).toUpperCase(), style: AppText.label(color: m.selectedRoute == id ? AppColors.text : AppColors.textDim)),
              ]),
            ),
          ),
      ]),
      if (m.data.environment.rad.isEmpty && m.data.environment.weather.isEmpty) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.amber)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(child: Text(l.safeNoEnvData, style: AppText.body(12, color: AppColors.amber, height: 1.4))),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      const _SolSelector(),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final rad = _RadiationPanel(route: r);
        final wx = _WeatherPanel(route: r, check: checks.weather);
        return wide
            ? IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 5, child: rad),
                  const SizedBox(width: 10),
                  Expanded(flex: 6, child: wx),
                ]),
              )
            : Column(children: [rad, const SizedBox(height: 10), wx]);
      }),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final terrain = _TerrainPanel(route: r);
        final cons = _ConsumablesPanel(route: r);
        return wide
            ? IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 5, child: terrain),
                  const SizedBox(width: 10),
                  Expanded(flex: 4, child: cons),
                ]),
              )
            : Column(children: [terrain, const SizedBox(height: 10), cons]);
      }),
      const SizedBox(height: 10),
      const _RulesPanel(),
    ]);
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.icon, required this.title, required this.child, this.tag});

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? tag;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionHeader(icon: icon, title: title, trailing: tag),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ]),
      );
}

Widget _tile(String k, String v, {Color color = AppColors.text, String? sub}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.panel2, border: Border.all(color: AppColors.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(v, style: AppText.head(15, color: color)),
          if (sub != null) Text(sub, style: AppText.mono(9.5, color: AppColors.textMute)),
        ]),
      ),
    );

/// Control para elegir el sol de REMS y RAD con que se evalúa la salida.
class _SolSelector extends StatelessWidget {
  const _SolSelector();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final env = m.data.environment;
    final w = env.weatherFor(m.envSol);
    final first = env.firstWeatherSol;
    final last = env.referenceSol;
    final date = w == null ? '' : w.utcStart.substring(0, 10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
       Row(children: [
        Text(l.safeSolTitle, style: AppText.label()),
        const SizedBox(width: 14),
        Text('SOL ${m.envSol}', style: AppText.head(15, color: AppColors.orange)),
        const SizedBox(width: 10),
        Text('$date ${l.utcLabel}', style: AppText.mono(11, color: AppColors.textDim)),
        Expanded(
          child: last > first
              ? Slider(
                  value: m.envSol.toDouble().clamp(first.toDouble(), last.toDouble()),
                  min: first.toDouble(),
                  max: last.toDouble(),
                  divisions: last - first,
                  onChanged: (v) => m.setEnvSol(v.round()),
                )
              : const SizedBox.shrink(),
        ),
       ]),
       Row(children: [
        const Icon(Icons.history, size: 13, color: AppColors.amber),
        const SizedBox(width: 6),
        Expanded(child: Text(l.safeSolNote, style: AppText.body(11, color: AppColors.textDim))),
       ]),
      ]),
    );
  }
}

class _RadiationPanel extends StatelessWidget {
  const _RadiationPanel({required this.route});

  final RouteResult? route;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final d = m.data;
    final env = d.environment;
    final cfg = d.envConfig;
    final rs = env.radFor(m.envSol);
    final base = env.baselineE;
    final ratio = env.radiationRatio(m.envSol);
    final level = env.radiationLevel(m.envSol, cfg);
    final met = route?.metrics;
    // Dosis de la ruta con la tasa del sol elegido.
    final routeDose = met != null && rs != null ? rs.eMean * met.totalH / 24.0 : null;
    final bars = [for (final r in env.rad) if (r.sol > m.envSol - 60 && r.sol <= m.envSol) r];
    return _Box(
      icon: Icons.radar,
      title: l.panelRadiation,
      tag: Tag(l.kindMeasured, color: AppColors.cyan),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _tile(l.radRate, rs == null ? '—' : '${f.num(rs.eMean, 0)} µGy/${f.locale.languageCode == 'es' ? 'día' : 'day'}', color: _levelColor(level)),
          const SizedBox(width: 8),
          _tile(l.radBaseline, base == null ? '—' : f.num(base, 0), sub: 'µGy/${f.locale.languageCode == 'es' ? 'día' : 'day'}'),
          const SizedBox(width: 8),
          _tile(l.radRatio, ratio == null ? '—' : '${f.num(ratio, 2)}×', color: _levelColor(level)),
          const SizedBox(width: 8),
          _tile(l.radProjected, routeDose == null ? '—' : '${f.num(routeDose, 0)} µGy'),
        ]),
        const SizedBox(height: 12),
        Text(l.radHistory.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 6),
        SizedBox(
          height: 130,
          child: CustomPaint(
            size: Size.infinite,
            painter: _DosePainter(bars, base, cfg, m.envSol, f),
          ),
        ),
        const SizedBox(height: 8),
        Text(l.radUnitNote, style: AppText.body(10.5, color: AppColors.textMute)),
        const SizedBox(height: 2),
        Text('${l.radSource} · MSL_RAD_OBS-L2', style: AppText.mono(9.5, color: AppColors.textMute)),
      ]),
    );
  }
}

class _DosePainter extends CustomPainter {
  _DosePainter(this.bars, this.base, this.cfg, this.selectedSol, this.f);

  final List<RadSol> bars;
  final double? base;
  final EnvConfig cfg;
  final int selectedSol;
  final Fmt f;

  void _text(Canvas c, String t, Offset at, {Color color = AppColors.textDim, TextAlign align = TextAlign.left, double width = 80}) {
    final tp = TextPainter(text: TextSpan(text: t, style: AppText.mono(9.5, color: color)), textDirection: TextDirection.ltr, textAlign: align)
      ..layout(maxWidth: width);
    final dx = align == TextAlign.right ? at.dx - tp.width : (align == TextAlign.center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(c, Offset(dx, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const left = 40.0, right = 8.0, top = 6.0, bottom = 16.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    final cautionLine = base == null ? null : base! * cfg.radCautionRatio;
    var ymax = bars.map((b) => b.eMean).reduce(math.max);
    if (cautionLine != null) ymax = math.max(ymax, cautionLine * 1.08);
    ymax *= 1.08;
    double yOf(double v) => top + h * (1 - v / ymax);
    final grid = Paint()..color = AppColors.hairline..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final y = top + h * k / 3;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _text(canvas, f.num(ymax * (1 - k / 3), 0), Offset(left - 5, y - 6), align: TextAlign.right, width: 34);
    }
    final bw = w / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final ratio = base == null ? 0.0 : b.eMean / base!;
      final color = ratio >= cfg.radNoGoRatio ? AppColors.red : (ratio >= cfg.radCautionRatio ? AppColors.amber : AppColors.cyan);
      final r = Rect.fromLTRB(left + i * bw + bw * 0.15, yOf(b.eMean), left + (i + 1) * bw - bw * 0.15, top + h);
      canvas.drawRect(r, Paint()..color = color.withValues(alpha: b.sol == selectedSol ? 1.0 : 0.55));
      if (b.sol == selectedSol) canvas.drawRect(r.inflate(1.5), Paint()..color = AppColors.text..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
    void dashed(double y, Color c) {
      final p = Paint()..color = c..strokeWidth = 1.2;
      for (var x = left; x < left + w; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, left + w), y), p);
      }
    }
    if (base != null) dashed(yOf(base!), AppColors.green);
    if (cautionLine != null) dashed(yOf(cautionLine), AppColors.amber);
    _text(canvas, 'SOL ${bars.first.sol}', Offset(left, top + h + 3), width: 60);
    _text(canvas, 'SOL ${bars.last.sol}', Offset(left + w, top + h + 3), align: TextAlign.right, width: 60);
  }

  @override
  bool shouldRepaint(_DosePainter old) => true;
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({required this.route, required this.check});

  final RouteResult? route;
  final WeatherCheck check;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final d = m.data;
    final w = d.environment.weatherFor(m.envSol);
    final met = route?.metrics;
    final window = (met?.totalH ?? 0) * _lmstPerEarthHour;
    String range(double? a, double? b, String unit, [int digits = 0]) =>
        (a == null || b == null) ? l.wxNoData : '${f.num(a, digits)} … ${f.num(b, digits)} $unit';
    return _Box(
      icon: Icons.thermostat,
      title: l.panelWeather,
      tag: Tag(l.kindMeasured, color: AppColors.cyan),
      child: w == null
          ? Text(l.wxNoData, style: AppText.mono(12, color: AppColors.textMute))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.wxProfile, style: AppText.label(color: AppColors.textMute)),
              const SizedBox(height: 6),
              SizedBox(
                height: 150,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TempPainter(w, d.envConfig.evaStartLmstH, d.envConfig.evaStartLmstH + window, f, met != null, l.wxAirShort, l.wxGroundShort),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Container(width: 10, height: 10, color: AppColors.orange.withValues(alpha: 0.35)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    met == null
                        ? l.wxWindow
                        : '${l.wxWindow}: ${f.num(d.envConfig.evaStartLmstH, 0).padLeft(2, '0')}:00 → ${f.num((d.envConfig.evaStartLmstH + window) % 24, 1)} LMST   ·   ${l.wxMinWindow}: '
                            '${check.minAirC == null ? l.wxNoData : '${f.num(check.minAirC!, 0)} °C'} (${check.hoursInWindow} ${l.wxCoverage})',
                    style: AppText.mono(10.5, color: AppColors.textDim),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _tile(l.wxAir, range(w.airMinC, w.airMaxC, '°C'), sub: '${w.hoursWithAir}/24 ${l.wxCoverage}'),
                const SizedBox(width: 8),
                _tile(l.wxGround, range(w.groundMinC, w.groundMaxC, '°C')),
                const SizedBox(width: 8),
                _tile(l.wxPressure, range(w.pressureMinPa, w.pressureMaxPa, 'Pa')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _tile(l.wxUv, w.uvPeak == null ? l.wxNoData : '${f.num(w.uvPeak!, 1)} W/m²'),
                const SizedBox(width: 8),
                _tile(l.wxHumidity, w.humidityMaxPct == null ? l.wxNoData : '${f.num(w.humidityMaxPct!, 1)} %'),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox.shrink()),
              ]),
              const SizedBox(height: 8),
              Text('${l.wxSource} · MSL-M-REMS-5-MODRDR-V1.0', style: AppText.mono(9.5, color: AppColors.textMute)),
            ]),
    );
  }
}

class _TempPainter extends CustomPainter {
  _TempPainter(this.w, this.evaStart, this.evaEnd, this.f, this.showWindow, this.airLabel, this.groundLabel);

  final WeatherSol w;
  final double evaStart;
  final double evaEnd;
  final Fmt f;
  final bool showWindow;
  final String airLabel;
  final String groundLabel;

  double _text(Canvas c, String t, Offset at, {Color color = AppColors.textDim, TextAlign align = TextAlign.left, double width = 80}) {
    final tp = TextPainter(text: TextSpan(text: t, style: AppText.mono(9.5, color: color)), textDirection: TextDirection.ltr, textAlign: align)
      ..layout(maxWidth: width);
    final dx = align == TextAlign.right ? at.dx - tp.width : (align == TextAlign.center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(c, Offset(dx, at.dy));
    return tp.width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, right = 10.0, top = 8.0, bottom = 18.0;
    final width = size.width - left - right, height = size.height - top - bottom;
    final vals = <double>[
      for (final h in w.hourly) ...[?h.airC, ?h.groundC],
    ];
    if (vals.isEmpty) return;
    final lo = vals.reduce(math.min) - 4, hi = vals.reduce(math.max) + 4;
    double x(num hour) => left + hour / 24 * width;
    double y(double v) => top + height * (1 - (v - lo) / (hi - lo));
    final grid = Paint()..color = AppColors.hairline..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final yy = top + height * k / 4;
      canvas.drawLine(Offset(left, yy), Offset(left + width, yy), grid);
      _text(canvas, f.num(hi - (hi - lo) * k / 4, 0), Offset(left - 5, yy - 6), align: TextAlign.right, width: 34);
    }
    for (var hh = 0; hh <= 24; hh += 6) {
      canvas.drawLine(Offset(x(hh), top), Offset(x(hh), top + height), grid);
      _text(canvas, '${hh.toString().padLeft(2, '0')}h', Offset(x(hh), top + height + 3), align: TextAlign.center, width: 30);
    }
    if (showWindow) {
      final a = x(evaStart.clamp(0, 24)), b = x(evaEnd.clamp(0, 24));
      canvas.drawRect(Rect.fromLTRB(a, top, b, top + height), Paint()..color = AppColors.orange.withValues(alpha: 0.18));
      canvas.drawRect(Rect.fromLTRB(a, top, b, top + height), Paint()..color = AppColors.orange.withValues(alpha: 0.6)..style = PaintingStyle.stroke);
    }
    void series(double? Function(HourPoint) pick, Color color, {double widthPx = 2.2}) {
      final line = Paint()..color = color..strokeWidth = widthPx..strokeCap = StrokeCap.round;
      HourPoint? prev;
      for (final h in w.hourly) {
        final v = pick(h);
        if (v == null) {
          prev = null;
          continue;
        }
        if (prev != null && pick(prev) != null) {
          canvas.drawLine(Offset(x(prev.hour + 0.5), y(pick(prev)!)), Offset(x(h.hour + 0.5), y(v)), line);
        }
        canvas.drawCircle(Offset(x(h.hour + 0.5), y(v)), 2.6, Paint()..color = color);
        prev = h;
      }
    }

    series((h) => h.groundC, AppColors.orange, widthPx: 1.6);
    series((h) => h.airC, AppColors.cyan);
    // Mínimo y máximo del aire.
    HourPoint? mn, mx;
    for (final h in w.hourly) {
      if (h.airC == null) continue;
      if (mn == null || h.airC! < mn.airC!) mn = h;
      if (mx == null || h.airC! > mx.airC!) mx = h;
    }
    if (mn != null) _text(canvas, '${f.num(mn.airC!, 0)}°', Offset(x(mn.hour + 0.5) + 4, y(mn.airC!) - 13), color: AppColors.cyan, width: 40);
    if (mx != null && mx != mn) _text(canvas, '${f.num(mx.airC!, 0)}°', Offset(x(mx.hour + 0.5) + 4, y(mx.airC!) - 13), color: AppColors.cyan, width: 40);
    // Leyenda.
    canvas.drawLine(Offset(left + 6, top + 6), Offset(left + 22, top + 6), Paint()..color = AppColors.cyan..strokeWidth = 2.2);
    final wAir = _text(canvas, airLabel, Offset(left + 26, top), color: AppColors.cyan, width: 80);
    final x2 = left + 26 + wAir + 14;
    canvas.drawLine(Offset(x2, top + 6), Offset(x2 + 16, top + 6), Paint()..color = AppColors.orange..strokeWidth = 1.6);
    _text(canvas, groundLabel, Offset(x2 + 20, top), color: AppColors.orange, width: 80);
  }

  @override
  bool shouldRepaint(_TempPainter old) => true;
}

/// Muestra los umbrales de GO / NO-GO, que son supuestos del equipo.
class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final c = m.data.envConfig;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 5, child: Text(k, style: AppText.body(12, color: AppColors.textDim))),
            Expanded(flex: 5, child: Text(v, style: AppText.mono(11.5), textAlign: TextAlign.right)),
          ]),
        );
    final caution = l.safeCaution.toLowerCase();
    return _Box(
      icon: Icons.rule,
      title: l.rulesTitle,
      tag: Tag('ASSUMPTION', color: AppColors.amber),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        row(l.rulesRad, '$caution ≥ ${f.num(c.radCautionRatio, 1)}× · no-go ≥ ${f.num(c.radNoGoRatio, 1)}×'),
        row(l.rulesAir, '$caution ≤ ${f.num(c.airCautionC, 0)} °C · no-go ≤ ${f.num(c.airNoGoC, 0)} °C'),
        row(l.rulesStart, '${f.num(c.evaStartLmstH, 0).padLeft(2, '0')}:00 LMST'),
        const SizedBox(height: 2),
        Text(l.rulesNote, style: AppText.body(11, color: AppColors.textMute, height: 1.4)),
        const SizedBox(height: 4),
        Text(l.rulesCrew, style: AppText.body(11, color: AppColors.textMute, height: 1.4)),
      ]),
    );
  }
}

class _TerrainPanel extends StatelessWidget {
  const _TerrainPanel({required this.route});

  final RouteResult? route;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final met = route?.metrics;
    if (route == null || met == null) {
      return _Box(icon: Icons.landscape_outlined, title: l.panelTerrain, child: Text('—', style: AppText.mono(12, color: AppColors.textMute)));
    }
    final total = met.mNominal + met.mCaution + met.mHighCaution;
    Widget seg(double v, Color c) => Expanded(flex: (v / total * 1000).round().clamp(1, 1000), child: Container(height: 12, color: c));
    Widget legend(Color c, String t, double v) => Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, color: c),
            const SizedBox(width: 6),
            Text('$t  ${f.num(v, 0)} m (${f.percent(v / total)})', style: AppText.mono(10.5, color: AppColors.textDim)),
          ]),
        );

    final g = m.data.grid;
    final along = alongRoute(g, route!.cells);
    final rows = <(String, double, double)>[(l.habitat, 0, 0)];
    for (final id in route!.visited) {
      final o = m.objective(id);
      if (o == null) continue;
      final idx = indexOfCell(route!.cells, g.cellOf(o.xM, o.yM));
      rows.add((id.toUpperCase(), idx >= 0 ? along[idx] : 0, distanceM(o.xM, o.yM, m.data.habitatX, m.data.habitatY)));
    }
    rows.add((l.pnrShort, met.noReturn.alongM, met.noReturn.fromHabitatM));
    final speed = m.data.model.flatSpeedMPerH;

    TableRow head() => TableRow(children: [
          for (final t in [l.colStop, l.colAlong, l.colStraight, l.colWalkback])
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(t, style: AppText.label(color: AppColors.textMute))),
        ]);
    TableRow row((String, double, double) r) => TableRow(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(r.$1, style: AppText.mono(12, weight: FontWeight.w700, color: r.$1 == l.pnrShort ? AppColors.amber : AppColors.text))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(f.km(r.$2, 2), style: AppText.mono(12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(f.km(r.$3, 2), style: AppText.mono(12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${f.num(r.$3 / speed * 60, 0)} min', style: AppText.mono(12))),
          ],
        );

    return _Box(
      icon: Icons.landscape_outlined,
      title: l.panelTerrain,
      tag: Tag(l.kindModeled, color: AppColors.orange),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.terrainByClass.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 8),
        Row(children: [
          seg(met.mNominal, AppColors.slopeNominal),
          if (met.mCaution > 0) seg(met.mCaution, AppColors.slopeCaution),
          if (met.mHighCaution > 0) seg(met.mHighCaution, AppColors.slopeHigh),
        ]),
        const SizedBox(height: 8),
        Wrap(runSpacing: 4, children: [
          legend(AppColors.slopeNominal, '<10°', met.mNominal),
          legend(AppColors.slopeCaution, '10–20°', met.mCaution),
          legend(AppColors.slopeHigh, '20–25°', met.mHighCaution),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _kv(l.metricMaxSlope, '${f.num(met.maxSlopeDeg, 0)}°', met.maxSlopeDeg >= m.data.model.slopeCautionMax ? AppColors.amber : AppColors.text),
          _kv(l.terrainRoughness, f.percent(met.roughMeanNorm)),
          _kv(l.metricClimb, '+${f.num(met.ascentM, 0)} m'),
          _kv(l.metricDistance, f.km(met.distanceM)),
        ]),
        const SizedBox(height: 16),
        Text(l.walkbackTitle.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 4),
        Table(columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(1.4), 2: FlexColumnWidth(1.4), 3: FlexColumnWidth(1.6)}, children: [head(), for (final r in rows) row(r)]),
        const SizedBox(height: 8),
        Text(l.consNote, style: AppText.body(11, color: AppColors.textMute)),
      ]),
    );
  }

  Widget _kv(String k, String v, [Color c = AppColors.text]) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
          const SizedBox(height: 3),
          Text(v, style: AppText.head(16, color: c)),
        ]),
      );
}

class _ConsumablesPanel extends StatelessWidget {
  const _ConsumablesPanel({required this.route});

  final RouteResult? route;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final mod = m.data.model;
    final met = route?.metrics;
    if (route == null || met == null) {
      return _Box(icon: Icons.air, title: l.panelConsumables, child: Text('—', style: AppText.mono(12, color: AppColors.textMute)));
    }
    final o2Color = met.o2Ok ? AppColors.cyan : AppColors.red;
    final timeFrac = met.totalH / mod.maxEvaH;
    final timeColor = met.timeOk ? AppColors.cyan : AppColors.red;

    Widget bar(String label, double frac, Color color, String value, {double? marker}) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(label.toUpperCase(), style: AppText.label(color: AppColors.textMute))),
              Text(value, style: AppText.mono(12, color: color, weight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Stack(clipBehavior: Clip.none, children: [
              MeterBar(value: frac, color: color, height: 8),
              if (marker != null)
                Positioned.fill(
                  child: Align(alignment: Alignment(marker * 2 - 1, 0), child: Container(width: 2, height: 14, color: AppColors.amber)),
                ),
            ]),
          ]),
        );

    TableRow compare(String id) {
      final r = m.routes[id];
      final mt = r?.metrics;
      final (txt, col) = mt == null ? ('—', AppColors.textMute) : (mt.feasible ? (l.statusFeasible, AppColors.green) : (l.statusNotFeasible, AppColors.red));
      Widget cell(Widget w) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: w);
      return TableRow(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
        children: [
          cell(Row(children: [Container(width: 8, height: 3, color: routeColor(id)), const SizedBox(width: 6), Flexible(child: Text(routeName(l, id), style: AppText.body(12), overflow: TextOverflow.ellipsis))])),
          cell(Text(mt == null ? '—' : f.hours(mt.totalH), style: AppText.mono(12))),
          cell(Text(mt == null ? '—' : f.percent(mt.o2RemainingFrac), style: AppText.mono(12))),
          cell(Align(alignment: Alignment.centerLeft, child: Tag(txt, color: col))),
        ],
      );
    }

    return _Box(
      icon: Icons.air,
      title: l.panelConsumables,
      tag: Tag(l.kindModeled, color: AppColors.orange),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        bar(l.consO2, met.o2RemainingFrac, o2Color, '${f.percent(met.o2RemainingFrac)}  ·  ${l.consReserve} ${f.percent(mod.o2Reserve)}', marker: mod.o2Reserve),
        bar(l.consTime, timeFrac, timeColor, '${f.hours(met.totalH)} / ${f.hours(mod.maxEvaH)}'),
        const SizedBox(height: 4),
        Text(l.consCompare.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 4),
        Table(columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1.4), 2: FlexColumnWidth(1.2), 3: FlexColumnWidth(2)}, children: [
          TableRow(children: [
            for (final t in ['', l.metricDuration, l.metricO2, ''])
              Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(t, style: AppText.label(color: AppColors.textMute), overflow: TextOverflow.ellipsis)),
          ]),
          for (final id in m.routeIds) compare(id),
        ]),
      ]),
    );
  }
}
