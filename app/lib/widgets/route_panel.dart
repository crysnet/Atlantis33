import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../routing/routing.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'common.dart';
import 'map_view.dart' show routeColor;
import 'objective_dialog.dart';

/// Panel derecho: comparación de rutas, objetivos científicos y supuestos del modelo.
class RoutePanel extends StatelessWidget {
  const RoutePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.panel,
      child: Column(children: [
        SectionHeader(
          icon: Icons.alt_route,
          title: l.routesTitle,
          trailing: m.computing
              ? Tag(l.computing, color: AppColors.amber, filled: true)
              : (m.computeMs > 0 ? Text('${m.computeMs} ms', style: AppText.mono(10, color: AppColors.textMute)) : null),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(10), children: [
            if ((m.registry.byId(m.siteId)?.indicative ?? false) || (m.registry.byId(m.siteId)?.reach ?? false)) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.amber)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text((m.registry.byId(m.siteId)?.reach ?? false) ? l.siteReachNote : l.siteIndicativeNote, style: AppText.body(11, color: AppColors.amber, height: 1.4))),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            const _ModeSelector(),
            const SizedBox(height: 8),
            if (m.exitMode == ExitMode.pair) const _PairCard(),
            for (final id in m.routeIds)
              if (m.routes[id] != null) _RouteCard(profile: id, route: m.routes[id]!),
            const SizedBox(height: 8),
            const _ObjectivesBlock(),
            const SizedBox(height: 8),
            const _AssumptionsBlock(),
          ]),
        ),
      ]),
    );
  }
}

class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.profile, required this.route});

  final String profile;
  final RouteResult route;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final r = widget.route;
    final sel = m.selectedRoute == widget.profile;
    final color = routeColor(widget.profile);
    final met = r.metrics;
    final (statusText, statusColor) = switch (r.status) {
      'ok' => (l.statusFeasible, AppColors.green),
      'not_feasible' => (l.statusNotFeasible, AppColors.red),
      'unreachable' => (l.statusUnreachable, AppColors.red),
      _ => (l.statusNoTarget, AppColors.amber),
    };
    Widget metric(String label, String value, {Color? c}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
            const SizedBox(height: 3),
            Text(value, style: AppText.head(15, color: c ?? AppColors.text)),
          ]),
        );
    final skipped = r.skipped.where((s) => s['reason'] != 'not_primary').toList();
    return GestureDetector(
      onTap: () => m.selectRoute(widget.profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.panel2 : AppColors.panel,
          border: Border.all(color: sel ? color : AppColors.hairline),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(routeName(l, widget.profile), style: AppText.head(15))),
                    Tag(statusText, color: statusColor, filled: true),
                  ]),
                  if (met != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      metric(l.metricDistance, f.km(met.distanceM)),
                      metric(l.metricDuration, f.hours(met.totalH)),
                      metric(l.metricMaxSlope, '${f.num(met.maxSlopeDeg, 0)}°',
                          c: met.maxSlopeDeg >= m.data.model.slopeCautionMax ? AppColors.amber : AppColors.text),
                    ]),
                    if (met.rover) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        metric(l.metricRover, met.roverM > 0 ? '${f.num(met.roverM, 0)} m · ${f.hours(met.roverH)}' : l.metricRoverNone, c: AppColors.cyan),
                      ]),
                    ],
                    if (r.transport != null)
                      for (final n in (r.transport!['notes'] as List))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.info_outline, size: 13, color: AppColors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                transportNote(l, (n as Map)['reason'] as String, m.objective((n)['id'] as String? ?? '')?.name ?? (n['id'] as String? ?? '')),
                                style: AppText.body(11, color: AppColors.amber, height: 1.35),
                              ),
                            ),
                          ]),
                        ),
                    if (met.support && met.emergencyMaxH != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        metric(l.metricEmergency, f.hours(met.emergencyMaxH!), c: AppColors.cyan),
                        metric(l.metricEmergencyFoot, f.hours(met.emergencyMaxFootH!)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      metric(l.metricClimb, '+${f.num(met.ascentM, 0)} m'),
                      metric(l.metricO2, f.o2(met.o2RemainingFrac, l.o2Depleted),
                          c: met.o2Ok ? AppColors.text : AppColors.red),
                      metric(l.metricDose, '${f.num(m.doseOver(met.totalH), 0)} µGy'),
                    ]),
                    const SizedBox(height: 12),
                    _score(l.hazardScore, r.hazard!.score, _hazardColor(r.hazard!.score), f),
                    const SizedBox(height: 7),
                    _score(l.successScore, r.success!.score, AppColors.cyan, f),
                    if (widget.profile != 'fast') _compareWithFast(m, r, met, l, f),
                    const SizedBox(height: 10),
                    Text(
                      '${l.visits}: ${r.visited.isEmpty ? '-' : r.visited.map((e) => e.toUpperCase()).join(' → ')}'
                      '   ·   ${l.metricNoReturn}: ${f.km(met.noReturn.alongM)}',
                      style: AppText.mono(10.5, color: AppColors.textDim, height: 1.4),
                    ),
                  ],
                  if (skipped.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l.skippedLabel}: ${skipped.map((s) => '${s['id']!.toUpperCase()} (${reasonName(l, s['reason']!)})').join(', ')}',
                      style: AppText.mono(10.5, color: AppColors.textMute, height: 1.4),
                    ),
                  ],
                  if (met != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _open = !_open),
                      child: Row(children: [
                        Icon(_open ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Text(l.breakdown.toUpperCase(), style: AppText.label(color: AppColors.orange)),
                      ]),
                    ),
                    if (_open) _breakdown(r, l, f),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Qué cambia frente a la ruta rápida: peligro, pendiente máxima, oxígeno al volver y tiempo. Verde si mejora, ámbar si empeora.
  /// Si es el mismo objetivo y casi el mismo camino, lo dice en vez de mostrar diferencias sin sentido.
  Widget _compareWithFast(AppModel m, RouteResult r, RouteMetrics met, AppLocalizations l, Fmt f) {
    final fast = m.routes['fast'];
    final fm = fast?.metrics;
    if (fast == null || fm == null || fast.hazard == null || r.hazard == null) return const SizedBox.shrink();
    final sameTarget = r.visited.join(',') == fast.visited.join(',');
    final dMin = ((met.totalH - fm.totalH) * 60).round();
    final dKm = (met.distanceM - fm.distanceM).abs();
    final dSlope = met.maxSlopeDeg - fm.maxSlopeDeg;
    final dHaz = r.hazard!.score - fast.hazard!.score;
    final dO2 = (met.o2RemainingFrac - fm.o2RemainingFrac) * 100;
    if (sameTarget && dMin.abs() < 3 && dKm < 100 && dSlope.abs() < 1 && dHaz.abs() < 1) {
      return Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.cmpSame, style: AppText.body(11, color: AppColors.textMute, height: 1.35)));
    }
    Widget chip(String label, double d, String text, {required bool lowerIsBetter}) {
      final good = lowerIsBetter ? d < 0 : d > 0;
      final neutral = d.abs() < 0.05;
      final c = neutral ? AppColors.textDim : (good ? AppColors.green : AppColors.amber);
      return Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 2),
        child: Text('$label $text', style: AppText.mono(10.5, color: c)),
      );
    }

    String sg(double v, int digits) => '${v > 0 ? '+' : ''}${f.num(v, digits)}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.cmpVsFast.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 3),
        Wrap(children: [
          chip(l.hazardScore, dHaz, sg(dHaz, 0), lowerIsBetter: true),
          chip(l.metricMaxSlope, dSlope, '${sg(dSlope, 1)}°', lowerIsBetter: true),
          chip(l.metricO2, dO2, '${sg(dO2, 0)} pp', lowerIsBetter: false),
          chip(l.metricDuration, dMin.toDouble(), '${dMin > 0 ? '+' : ''}$dMin min', lowerIsBetter: true),
          if (!sameTarget) chip(l.visits, 0, r.visited.map((e) => e.toUpperCase()).join('→'), lowerIsBetter: true),
        ]),
      ]),
    );
  }

  Color _hazardColor(double s) => s < 25 ? AppColors.green : (s < 50 ? AppColors.amber : AppColors.red);

  Widget _score(String label, double v, Color color, Fmt f) => Row(children: [
        SizedBox(width: 68, child: Text(label, style: AppText.label())),
        Expanded(child: MeterBar(value: v / 100, color: color)),
        SizedBox(width: 44, child: Text(f.num(v, 1), textAlign: TextAlign.right, style: AppText.mono(12, color: color, weight: FontWeight.w700))),
      ]);

  Widget _breakdown(RouteResult r, AppLocalizations l, Fmt f) {
    String hz(String k) => switch (k) {
          'slope' => l.hzSlope,
          'terrain' => l.hzTerrain,
          'walkback' => l.hzWalkback,
          'consumables' => l.hzConsumables,
          'radiation' => l.hzRadiation,
          _ => l.hzDay,
        };
    final h = r.hazard!;
    final s = r.success!;
    Widget row(String name, double value, double max, Color color, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Expanded(flex: 5, child: Text(name, style: AppText.body(11.5, color: AppColors.textDim))),
            Expanded(flex: 4, child: MeterBar(value: max == 0 ? 0 : value / max, color: color, height: 4)),
            SizedBox(width: 62, child: Text(text, textAlign: TextAlign.right, style: AppText.mono(10.5))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      Text(l.hazardScore, style: AppText.label(color: AppColors.textMute)),
      for (final e in h.components.entries)
        row(hz(e.key), e.value, 1, AppColors.orange, '${f.num(e.value * h.weights[e.key]!, 1)}/${f.num(h.weights[e.key]!, 0)}'),
      const SizedBox(height: 10),
      Text(l.successScore, style: AppText.label(color: AppColors.textMute)),
      row(l.scValue, s.scienceValue, 1, AppColors.cyan, f.percent(s.scienceValue)),
      row(l.scTime, s.timeFactor, 1, AppColors.cyan, f.percent(s.timeFactor)),
      row(l.scConsumables, s.consumablesFactor, 1, AppColors.cyan, f.percent(s.consumablesFactor)),
      row(l.scPenalty, s.hazardPenalty, 1, AppColors.cyan, f.percent(s.hazardPenalty)),
    ]);
  }
}

class _ObjectivesBlock extends StatelessWidget {
  const _ObjectivesBlock();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final r = m.route;
    final visited = r?.visited.toSet() ?? const <String>{};
    return Container(
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(children: [
            Text(l.objectivesTitle, style: AppText.label()),
            const Spacer(),
            Tag('${m.objectives.length}', color: AppColors.cyan),
          ]),
        ),
        if (m.objectives.isEmpty)
          Padding(padding: const EdgeInsets.all(12), child: Text(l.objectivesEmpty, style: AppText.body(12, color: AppColors.textDim))),
        for (final o in m.objectives)
          InkWell(
            onTap: () {
              m.selectObjective(o.id);
              showObjectiveDialog(context, m, o.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: m.selectedObjective == o.id ? AppColors.panel2 : Colors.transparent,
              child: Row(children: [
                Icon(Icons.diamond_outlined, size: 16, color: m.data.isBlocked(o.xM, o.yM) ? AppColors.red : AppColors.cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.name, style: AppText.body(12.5, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      m.data.isBlocked(o.xM, o.yM)
                          ? l.objectiveForbidden
                          : '${l.priorityLabel(o.priority)} · ${typeName(l, o.type)} · ${l.workMinutes(o.workMin.round())}${m.exitMode == ExitMode.byObjective ? ' · ${transportName(l, o.transport)}' : ''}',
                      style: AppText.mono(10, color: m.data.isBlocked(o.xM, o.yM) ? AppColors.red : AppColors.cyan),
                    ),
                  ]),
                ),
                if (visited.contains(o.id)) const Icon(Icons.check, size: 14, color: AppColors.green),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: OutlinedButton.icon(
            onPressed: m.toggleAddMode,
            icon: Icon(m.addMode ? Icons.close : Icons.add_location_alt_outlined, size: 16),
            label: Text(m.addMode ? l.objectivesAddActive : l.objectivesAdd, style: AppText.label(color: m.addMode ? AppColors.cyan : AppColors.orange)),
            style: OutlinedButton.styleFrom(
              foregroundColor: m.addMode ? AppColors.cyan : AppColors.orange,
              side: BorderSide(color: m.addMode ? AppColors.cyan : AppColors.orange),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AssumptionsBlock extends StatelessWidget {
  const _AssumptionsBlock();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final mod = m.data.model;
    final profiles = mod.profiles;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(children: [
            Expanded(child: Text(k, style: AppText.body(11.5, color: AppColors.textDim))),
            Text(v, style: AppText.mono(11)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.assumptionsTitle, style: AppText.label()),
        const SizedBox(height: 2),
        Text(l.assumptionsNote, style: AppText.body(11, color: AppColors.textMute)),
        row(l.assumeSpeed, '${f.num(mod.flatSpeedMPerH / 1000, 1)} km/h'),
        row(l.assumeEva, '${f.num(mod.maxEvaH, 0)} h'),
        row(l.assumeO2, '${f.num(mod.o2CapacityH, 0)} h'),
        row(l.assumeReserve, f.percent(mod.o2Reserve)),
        row(l.assumeSlopeLimit, '${f.num(profiles['safe']!.slopeLimitDeg, 0)}° / ${f.num(profiles['fast']!.slopeLimitDeg, 0)}°'),
        row(l.assumeDose, '${f.num(mod.doseUGyPerDay, 0)} µGy/d'),
        if (m.data.environment.rad.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 2), child: Text(l.doseGaleNote, style: AppText.body(10.5, color: AppColors.amber, height: 1.35))),
        if (m.exitMode == ExitMode.pair) ...[
          const SizedBox(height: 8),
          Text(l.assumePairTitle, style: AppText.label(color: AppColors.cyan)),
          row(l.assumePairSep, '${f.num(mod.pairMaxSeparationM, 0)} m'),
          row(l.assumePairSample, '${f.num(mod.pairSampleH * 60, 0)} min'),
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(l.assumePairNote, style: AppText.body(11, color: AppColors.textMute, height: 1.4))),
        ],
        if (m.exitMode == ExitMode.rover || m.exitMode == ExitMode.support || m.exitMode == ExitMode.byObjective) ...[
          const SizedBox(height: 8),
          Text(l.assumeRoverTitle, style: AppText.label(color: AppColors.cyan)),
          row(l.assumeRoverSpeed, '${f.num(mod.rover.speedKmh, 0)} km/h'),
          row(l.assumeRoverSlope, '${f.num(mod.rover.slopeLimitDeg, 0)}°'),
          row(l.assumeRoverRough, '${f.num(mod.rover.roughMaxCm, 0)} cm'),
          row(l.assumeRoverO2, f.percent(mod.rover.o2Rate)),
          row(l.assumeRoverTransfer, '${f.num(mod.rover.transferH * 60, 0)} min'),
          if (m.exitMode == ExitMode.support) row(l.assumeDispatch, '${f.num(mod.rover.dispatchH * 60, 0)} min'),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(m.exitMode == ExitMode.support ? l.assumeSupportNote : (m.exitMode == ExitMode.byObjective ? l.assumeObjectiveNote : l.assumeRoverNote), style: AppText.body(11, color: AppColors.textMute, height: 1.4)),
          ),
        ],
      ]),
    );
  }
}

/// Elige el modo de salida: a pie o con rover aparcado en un punto de la ruta.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    Widget chip(String text, IconData icon, ExitMode value) {
      final on = m.exitMode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => m.setExitMode(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: on ? AppColors.panel3 : AppColors.panel,
              border: Border.all(color: on ? AppColors.orange : AppColors.hairline),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 15, color: on ? AppColors.orange : AppColors.textDim),
              const SizedBox(width: 6),
              Flexible(child: Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label(color: on ? AppColors.orange : AppColors.textDim))),
            ]),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.modeTitle, style: AppText.label()),
      const SizedBox(height: 6),
      Row(children: [
        chip(l.modeFoot, Icons.directions_walk, ExitMode.foot),
        const SizedBox(width: 6),
        chip(l.modeRover, Icons.local_shipping_outlined, ExitMode.rover),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        chip(l.modeSupport, Icons.support_agent, ExitMode.support),
        const SizedBox(width: 6),
        chip(l.modePair, Icons.group_outlined, ExitMode.pair),
      ]),
      const SizedBox(height: 6),
      Row(children: [chip(l.modeObjective, Icons.tune, ExitMode.byObjective)]),
    ]);
  }
}

/// Resumen de la salida en pareja: lo que hacen los dos astronautas juntos.
class _PairCard extends StatelessWidget {
  const _PairCard();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final pr = m.pairResult;
    if (pr == null) return const SizedBox.shrink();
    final s = pr.summary;
    Widget metric(String label, String value, {Color? c}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
            const SizedBox(height: 3),
            Text(value, style: AppText.head(15, color: c ?? AppColors.text)),
          ]),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.panel2, border: Border.all(color: AppColors.cyan)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l.pairTitle, style: AppText.head(15))),
          Tag(s == null ? l.statusUnreachable : l.statusFeasible, color: s == null ? AppColors.red : AppColors.green, filled: true),
        ]),
        if (s == null) ...[
          const SizedBox(height: 8),
          Text(l.pairNone(f.num(pr.limitM, 0)), style: AppText.body(12, color: AppColors.textDim)),
        ] else ...[
          const SizedBox(height: 10),
          Row(children: [
            metric(l.pairVisits, s.visited.map((e) => e.toUpperCase()).join(' · ')),
            metric(l.metricDuration, f.hours(s.totalH)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            metric(l.pairSeparation, '${f.num(s.maxSeparationM, 0)} / ${f.num(pr.limitM, 0)} m'),
            metric(l.pairO2Min, f.o2(s.o2RemainingMinFrac, l.o2Depleted)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(width: 68, child: Text(l.hazardScore, style: AppText.label())),
            Expanded(child: MeterBar(value: s.hazard / 100, color: s.hazard < 25 ? AppColors.green : (s.hazard < 50 ? AppColors.amber : AppColors.red))),
            SizedBox(width: 44, child: Text(f.num(s.hazard, 1), textAlign: TextAlign.right, style: AppText.mono(12, weight: FontWeight.w700))),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            SizedBox(width: 68, child: Text(l.successScore, style: AppText.label())),
            Expanded(child: MeterBar(value: s.success.score / 100, color: AppColors.cyan)),
            SizedBox(width: 44, child: Text(f.num(s.success.score, 1), textAlign: TextAlign.right, style: AppText.mono(12, color: AppColors.cyan, weight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          Text(l.pairNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.4)),
        ],
      ]),
    );
  }
}
