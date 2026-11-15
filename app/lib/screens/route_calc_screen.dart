import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

/// Pantalla de transparencia del cálculo de rutas: fórmula A*, restricciones estrictas (No-Go)
/// y fuentes reales NASA/USGS/ASU que protegen al astronauta en Meridiani Planum.
class RouteCalcScreen extends StatelessWidget {
  const RouteCalcScreen({super.key});

  String _pointLabel(AppModel m, AppLocalizations l, String id) =>
      id == 'habitat' ? l.habitat : (m.objective(id)?.name ?? id);

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final active = m.activePlannedRoute;

    return Container(
      color: AppColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.rcTitle, style: AppText.head(20)),
                const SizedBox(height: 6),
                Text(l.rcSubtitle, style: AppText.body(13, color: AppColors.textDim, height: 1.45)),
                const SizedBox(height: 18),
                if (active != null) ...[
                  _ActiveRouteAuditCard(
                    l: l,
                    f: f,
                    m: m,
                    route: active,
                    routeTitle: '${_pointLabel(m, l, active.fromId)} → ${_pointLabel(m, l, active.toId)}',
                  ),
                  const SizedBox(height: 16),
                ],
                _FormulaCard(l: l),
                const SizedBox(height: 18),
                _SectionBanner(icon: Icons.block, title: l.rcHardConstraintsSection, accent: AppColors.red),
                const SizedBox(height: 8),
                _ConstraintCard(
                  icon: Icons.landscape_outlined,
                  accent: AppColors.red,
                  title: l.rcHardSlopeTitle,
                  desc: l.rcHardSlopeDesc,
                ),
                const SizedBox(height: 10),
                _ConstraintCard(
                  icon: Icons.warning_amber_rounded,
                  accent: AppColors.amber,
                  title: l.rcHardDustTitle,
                  desc: l.rcHardDustDesc,
                ),
                const SizedBox(height: 20),
                _SectionBanner(icon: Icons.science_outlined, title: l.rcCriteriaSection, accent: AppColors.cyan),
                const SizedBox(height: 8),
                _CriterionCard(
                  index: '01',
                  title: l.rcCritSlopeTitle,
                  source: l.rcCritSlopeSource,
                  desc: l.rcCritSlopeDesc,
                  accent: AppColors.cyan,
                ),
                const SizedBox(height: 10),
                _CriterionCard(
                  index: '02',
                  title: l.rcCritDciTitle,
                  source: l.rcCritDciSource,
                  desc: l.rcCritDciDesc,
                  accent: AppColors.cyan,
                ),
                const SizedBox(height: 10),
                _CriterionCard(
                  index: '03',
                  title: l.rcCritTiTitle,
                  source: l.rcCritTiSource,
                  desc: l.rcCritTiDesc,
                  accent: AppColors.cyan,
                ),
                const SizedBox(height: 10),
                _CriterionCard(
                  index: '04',
                  title: l.rcCritThemisTitle,
                  source: l.rcCritThemisSource,
                  desc: l.rcCritThemisDesc,
                  accent: AppColors.cyan,
                ),
                const SizedBox(height: 10),
                _CriterionCard(
                  index: '05',
                  title: l.rcCritMobilityTitle,
                  source: l.rcCritMobilitySource,
                  desc: l.rcCritMobilityDesc,
                  accent: AppColors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({required this.icon, required this.title, required this.accent});

  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppText.label(color: accent))),
      ]);
}

class _ActiveRouteAuditCard extends StatelessWidget {
  const _ActiveRouteAuditCard({
    required this.l,
    required this.f,
    required this.m,
    required this.route,
    required this.routeTitle,
  });

  final AppLocalizations l;
  final Fmt f;
  final AppModel m;
  final PlannedRoute route;
  final String routeTitle;

  @override
  Widget build(BuildContext context) {
    final res = route.result;
    final met = res.metrics;

    Widget stat(String label, String value, {Color color = AppColors.text}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.panel2,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
            const SizedBox(height: 4),
            Text(value, style: AppText.head(15, color: color)),
          ]),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: res.status == 'unreachable' ? AppColors.red : AppColors.cyan),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          icon: Icons.alt_route,
          title: l.rcActiveRouteSection,
          trailing: Text(routeTitle, style: AppText.mono(11, color: AppColors.cyan)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: res.status == 'unreachable'
              ? Text(l.statusUnreachable, style: AppText.body(12.5, color: AppColors.red, weight: FontWeight.w500))
              : met == null
                  ? const SizedBox.shrink()
                  : Wrap(spacing: 10, runSpacing: 10, children: [
                      stat(l.metricDistance, f.km(met.distanceM)),
                      stat(l.metricDuration, f.hours(met.totalH)),
                      stat(
                        l.metricMaxSlope,
                        '${f.num(met.maxSlopeDeg, 1)}°',
                        color: met.maxSlopeDeg >= m.data.model.slopeCautionMax ? AppColors.amber : AppColors.green,
                      ),
                      stat(l.metricElevRange, '+${f.num(met.ascentM, 0)} / −${f.num(met.descentM, 0)} m'),
                      stat(l.rcCellsEvaluated, '${res.cells.length}'),
                    ]),
        ),
      ]),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SectionHeader(icon: Icons.functions, title: l.rcFormulaSection),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'cost(u → v) = km × [ 1 + 2.5 × (slope_v / 15°)² + 4.0 × surface_index_v ]',
                    style: AppText.mono(12, color: AppColors.cyan, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'surface_index = 0.40 × pen_DCI + 0.40 × pen_TI + 0.20 × pen_THEMIS',
                    style: AppText.mono(11.5, color: AppColors.orange),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Text(l.rcFormulaDesc, style: AppText.body(12.5, color: AppColors.textDim, height: 1.5)),
            ]),
          ),
        ]),
      );
}

class _ConstraintCard extends StatelessWidget {
  const _ConstraintCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.hairline),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: AppText.head(14, color: AppColors.text))),
                  ]),
                  const SizedBox(height: 6),
                  Text(desc, style: AppText.body(12.5, color: AppColors.textDim, height: 1.5)),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({
    required this.index,
    required this.title,
    required this.source,
    required this.desc,
    required this.accent,
  });

  final String index;
  final String title;
  final String source;
  final String desc;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(index, style: AppText.mono(12, color: AppColors.textMute, weight: FontWeight.w700)),
              Text(title, style: AppText.head(14)),
              Tag(source, color: accent, filled: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: AppText.body(12.5, color: AppColors.textDim, height: 1.5)),
        ]),
      );
}
