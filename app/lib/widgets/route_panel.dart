import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'common.dart';
import 'map_view.dart' show routeColor;
import 'objective_dialog.dart';

/// Panel derecho: ruta automática única hacia el objetivo seleccionado y sus datos reales del terreno.
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
          title: l.routeAutoTitle,
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
                  Expanded(
                    child: Text(
                      (m.registry.byId(m.siteId)?.reach ?? false) ? l.siteReachNote : l.siteIndicativeNote,
                      style: AppText.body(11, color: AppColors.amber, height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            const _SelectedRouteCard(),
            const SizedBox(height: 8),
            const _ObjectivesBlock(),
          ]),
        ),
      ]),
    );
  }
}

class _SelectedRouteCard extends StatelessWidget {
  const _SelectedRouteCard();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final o = m.activeObjective;
    if (o == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
        child: Text(l.routeSelectObjective, style: AppText.body(12, color: AppColors.textDim, height: 1.45)),
      );
    }

    final blocked = m.data.isBlocked(o.xM, o.yM);
    final (lon, lat) = m.data.lonLat(o.xM, o.yM);
    final elev = m.data.elevationAt(o.xM, o.yM);
    final slope = m.data.slopeAt(o.xM, o.yM);
    final r = m.route;
    final met = r?.metrics;
    final color = blocked ? AppColors.red : routeColor('safe');

    Widget metric(String label, String value, {Color? c}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
            const SizedBox(height: 3),
            Text(value, style: AppText.head(15, color: c ?? AppColors.text)),
          ]),
        );

    return Container(
      decoration: BoxDecoration(color: AppColors.panel2, border: Border.all(color: color)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.diamond_outlined, size: 15, color: blocked ? AppColors.red : AppColors.cyan),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.name, style: AppText.head(15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  InkWell(
                    onTap: () => showObjectiveDialog(context, m, o.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_outlined, size: 12, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text(l.objectiveEditBtn.toUpperCase(), style: AppText.label(color: AppColors.textDim)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${o.id.toUpperCase()} · ${l.priorityLabel(o.priority)} · ${typeName(l, o.type)}',
                  style: AppText.mono(10.5, color: AppColors.cyan),
                ),
                const SizedBox(height: 8),
                Text(f.latLon(lon, lat), style: AppText.mono(11, color: AppColors.textDim)),
                const SizedBox(height: 10),
                Row(children: [
                  metric(l.objectiveElev, elev == null ? '-' : '${f.num(elev, 0)} m'),
                  metric(
                    l.objectiveSlope,
                    slope == null ? '-' : '${f.num(slope, 1)}°',
                    c: (slope ?? 0) >= m.data.model.slopeCautionMax ? AppColors.amber : AppColors.text,
                  ),
                ]),
                const Divider(height: 20, color: AppColors.hairline),
                Text(l.routeAutoHint, style: AppText.body(11, color: AppColors.textMute, height: 1.35)),
                const SizedBox(height: 10),
                if (blocked || r?.status == 'unreachable')
                  Text(
                    blocked ? l.objectiveForbidden : l.statusUnreachable,
                    style: AppText.body(12, color: AppColors.red, weight: FontWeight.w500),
                  )
                else if (met != null) ...[
                  Row(children: [
                    metric(l.metricDistance, f.km(met.distanceM)),
                    metric(l.metricDuration, f.hours(met.totalH)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    metric(
                      l.metricMaxSlope,
                      '${f.num(met.maxSlopeDeg, 0)}°',
                      c: met.maxSlopeDeg >= m.data.model.slopeCautionMax ? AppColors.amber : AppColors.text,
                    ),
                    metric(l.metricElevRange, '+${f.num(met.ascentM, 0)} / −${f.num(met.descentM, 0)} m'),
                  ]),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ObjectivesBlock extends StatelessWidget {
  const _ObjectivesBlock();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final activeId = m.activeObjective?.id;
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
            onTap: () => m.selectObjective(o.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: activeId == o.id ? AppColors.panel2 : Colors.transparent,
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
                          : '${o.id.toUpperCase()} · ${l.priorityLabel(o.priority)} · ${typeName(l, o.type)}',
                      style: AppText.mono(10, color: m.data.isBlocked(o.xM, o.yM) ? AppColors.red : AppColors.cyan),
                    ),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textMute),
                  visualDensity: VisualDensity.compact,
                  tooltip: l.objectiveEditBtn,
                  onPressed: () => showObjectiveDialog(context, m, o.id),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
