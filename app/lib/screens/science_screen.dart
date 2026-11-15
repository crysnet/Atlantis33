import 'package:flutter/material.dart';

import '../data/site_data.dart';
import '../l10n/app_localizations.dart';
import '../routing/routing.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/map_view.dart' show routeColor;
import '../widgets/objective_dialog.dart';
import '../widgets/tile_layer.dart';

/// Objetivos científicos: lista, detalle del punto con su recorte HiRISE y los datos de cada capa en ese sitio.
class ScienceScreen extends StatelessWidget {
  const ScienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final sel = m.objective(m.selectedObjective ?? '') ?? (m.objectives.isEmpty ? null : m.objectives.first);
    return LayoutBuilder(builder: (context, c) {
      final compact = c.maxWidth < 1100;
      return Row(children: [
        SizedBox(width: compact ? 270 : 320, child: _TargetList(selected: sel?.id)),
        const VerticalDivider(width: 1),
        Expanded(child: sel == null ? const _Empty() : _Detail(objective: sel)),
        const VerticalDivider(width: 1),
        SizedBox(width: compact ? 300 : 340, child: sel == null ? const SizedBox() : _Operations(objective: sel)),
      ]);
    });
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(AppLocalizations.of(context)!.sciPick, style: AppText.head(18, color: AppColors.textDim)));
}

Widget _priorityTag(AppLocalizations l, int p) {
  final (text, color) = p >= 4 ? (l.priorityHigh, AppColors.orange) : (p == 3 ? (l.priorityMedium, AppColors.amber) : (l.priorityLow, AppColors.textDim));
  return Tag('P$p · $text', color: color, filled: true);
}

class _TargetList extends StatelessWidget {
  const _TargetList({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.panel,
      child: Column(children: [
        SectionHeader(icon: Icons.gps_fixed, title: l.sciTargetsTitle, trailing: Tag('${m.objectives.length}', color: AppColors.cyan, filled: true)),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(10), children: [
            for (final o in m.objectives)
              GestureDetector(
                onTap: () => m.selectObjective(o.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected == o.id ? AppColors.panel2 : AppColors.panel,
                    border: Border.all(color: selected == o.id ? AppColors.cyan : AppColors.hairline),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      color: selected == o.id ? AppColors.cyan : AppColors.panel3,
                      child: Text(o.id.toUpperCase(), style: AppText.mono(12, color: selected == o.id ? AppColors.bg : AppColors.text, weight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.name, style: AppText.head(14)),
                        const SizedBox(height: 6),
                        Text('${typeName(l, o.type)} · ${l.workMinutes(o.workMin.round())}', style: AppText.mono(10.5, color: AppColors.textDim)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _priorityTag(l, o.priority),
                          if (m.data.isBlocked(o.xM, o.yM)) Tag(l.objectiveForbidden, color: AppColors.red, filled: true),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Valores del terreno en un punto, tomados de la rejilla de costos.
class _PointData {
  _PointData(SiteData d, Objective o)
      : cell = d.grid.cellOf(o.xM, o.yM),
        elev = d.elevationAt(o.xM, o.yM) ?? 0,
        slope = d.slopeAt(o.xM, o.yM) ?? 0,
        rough = d.grid.rough[d.grid.cellOf(o.xM, o.yM)],
        fromHabitat = distanceM(o.xM, o.yM, d.habitatX, d.habitatY),
        deltaElev = (d.elevationAt(o.xM, o.yM) ?? 0) - d.grid.z[d.grid.habitat];

  final int cell;
  final double elev;
  final double slope;
  final double rough;
  final double fromHabitat;
  final double deltaElev;
}

Color slopeColor(SiteData d, double s) {
  if (s < d.model.slopeNominalMax) return AppColors.slopeNominal;
  if (s < d.model.slopeCautionMax) return AppColors.slopeCaution;
  if (s <= 25) return AppColors.slopeHigh;
  return AppColors.slopeForbidden;
}

class _Detail extends StatelessWidget {
  const _Detail({required this.objective});

  final Objective objective;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final d = m.data;
    final o = objective;
    final p = _PointData(d, o);
    final (lon, lat) = d.lonLat(o.xM, o.yM);

    Widget stackRow(String index, String title, Widget body, Widget tag, {bool pending = false}) => Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 30, child: Text(index, style: AppText.mono(12, color: pending ? AppColors.textMute : AppColors.orange, weight: FontWeight.w700))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.toUpperCase(), style: AppText.mono(12, color: pending ? AppColors.textMute : AppColors.orange, weight: FontWeight.w700)),
                const SizedBox(height: 5),
                body,
              ]),
            ),
            tag,
          ]),
        );
    Widget value(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
            const SizedBox(height: 3),
            Text(v, style: AppText.head(15, color: color ?? AppColors.text)),
          ]),
        );

    return Container(
      color: AppColors.bg,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppColors.cyan,
            child: Text(o.id.toUpperCase(), style: AppText.mono(13, color: AppColors.bg, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(o.name, style: AppText.head(20))),
          _priorityTag(l, o.priority),
        ]),
        const SizedBox(height: 8),
        Text('${f.latLon(lon, lat)}   ·   ${l.elevation} ${f.num(p.elev, 0)} m   ·   ${f.num(p.slope, 0)}°', style: AppText.mono(11.5, color: AppColors.textDim)),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: Row(children: [
            Expanded(
              child: _framed(
                l.sciOrbital,
                f.text('HiRISE 0.25 m'),
                AppColors.cyan,
                OrbitalCrop(
                  data: d,
                  x: o.xM,
                  y: o.yM,
                  spanM: 160,
                  child: Positioned.fill(child: CustomPaint(painter: _CrosshairPainter(AppColors.cyan))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _framed(
                l.sciGround,
                d.roverPhotos[o.id] == null ? l.kindExample : l.kindMeasured,
                d.roverPhotos[o.id] == null ? AppColors.textMute : AppColors.cyan,
                d.roverPhotos[o.id] == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.photo_camera_outlined, color: AppColors.textMute, size: 28),
                            const SizedBox(height: 10),
                            Text(l.sciGroundSoon, textAlign: TextAlign.center, style: AppText.body(12, color: AppColors.textMute)),
                          ]),
                        ),
                      )
                    : _RoverPhotoView(photo: d.roverPhotos[o.id]!, note: l.sciGroundNote),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.layers_outlined, size: 15, color: AppColors.textDim),
                const SizedBox(width: 8),
                Text(l.sciDataStack, style: AppText.head(12)),
              ]),
            ),
            stackRow('01', l.stackOptical, Text(f.text('HiRISE · 0.25 m/px'), style: AppText.body(12, color: AppColors.textDim)), Tag(l.kindMeasured, color: AppColors.cyan)),
            stackRow(
              '02',
              l.stackTopo,
              Row(children: [
                value(l.fieldElevation, '${f.num(p.elev, 0)} m'),
                value(l.fieldSlope, '${f.num(p.slope, 0)}°', color: slopeColor(d, p.slope)),
                value(l.fieldRoughness, '${f.num(p.rough, 0)} cm'),
                value(l.fieldFromHabitat, f.km(p.fromHabitat, 2)),
                value(l.fieldDeltaElev, '${p.deltaElev >= 0 ? '+' : '−'}${f.num(p.deltaElev.abs(), 0)} m'),
              ]),
              Tag(l.kindModeled, color: AppColors.orange),
            ),
            stackRow('03', l.stackThermal, Text(l.stackThermalNote, style: AppText.body(12, color: AppColors.textDim)), Tag(l.kindMeasured, color: AppColors.cyan)),
            stackRow(
              '04',
              l.stackRadiation,
              Text(
                d.environment.radFor(m.envSol) == null
                    ? l.wxNoData
                    : '${f.num(d.environment.radFor(m.envSol)!.eMean, 0)} µGy/${m.locale.languageCode == 'es' ? 'día' : 'day'} · SOL ${m.envSol} · ${l.radUnitNote}',
                style: AppText.body(12, color: AppColors.textDim),
              ),
              Tag(l.kindMeasured, color: AppColors.cyan),
            ),
            stackRow('05', l.stackGeology, Text(l.stackGeologyNote, style: AppText.body(12, color: AppColors.textDim)), Tag(l.kindMeasured, color: AppColors.cyan)),
          ]),
        ),
      ]),
    );
  }

  Widget _framed(String title, String tag, Color tagColor, Widget child) => Container(
        decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.hairline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
            child: Row(children: [
              Expanded(child: Text(title, style: AppText.label(color: AppColors.text))),
              Tag(tag, color: tagColor),
            ]),
          ),
          Expanded(child: child),
        ]),
      );
}

class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(c, 16, p);
    canvas.drawCircle(c, 2.5, Paint()..color = color);
    for (final v in [const Offset(1, 0), const Offset(-1, 0), const Offset(0, 1), const Offset(0, -1)]) {
      canvas.drawLine(c + v * 22, c + v * 34, p);
    }
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => false;
}

class _Operations extends StatelessWidget {
  const _Operations({required this.objective});

  final Objective objective;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final o = objective;
    final blocked = m.data.isBlocked(o.xM, o.yM);
    return Container(
      color: AppColors.panel,
      child: Column(children: [
        SectionHeader(icon: Icons.build_outlined, title: '${l.opsTitle} · ${o.id.toUpperCase()}'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            Row(children: [
              Expanded(
                child: _stat(l.opsAllot, l.workMinutes(o.workMin.round()), AppColors.cyan),
              ),
              Expanded(child: _stat(l.fieldType, typeName(l, o.type), AppColors.text)),
            ]),
            const SizedBox(height: 16),
            if (blocked)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), border: Border.all(color: AppColors.red)),
                child: Row(children: [
                  const Icon(Icons.warning_amber, size: 16, color: AppColors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.objectiveForbidden, style: AppText.mono(11, color: AppColors.red))),
                ]),
              ),
            if (blocked) const SizedBox(height: 16),
            Text(l.opsVisitedBy.toUpperCase(), style: AppText.label()),
            const SizedBox(height: 8),
            for (final id in m.routeIds)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(color: AppColors.panel2, border: Border(left: BorderSide(color: routeColor(id), width: 3))),
                child: Row(children: [
                  Expanded(child: Text(routeName(l, id), style: AppText.body(12.5, weight: FontWeight.w500))),
                  if (m.routes[id]?.visited.contains(o.id) ?? false)
                    const Icon(Icons.check_circle, size: 16, color: AppColors.green)
                  else
                    Text('—', style: AppText.mono(12, color: AppColors.textMute)),
                ]),
              ),
            const SizedBox(height: 16),
            Text(l.opsHere.toUpperCase(), style: AppText.label()),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final (lon, lat) = m.data.lonLat(o.xM, o.yM);
              return Text(f.latLon(lon, lat), style: AppText.mono(12));
            }),
            const SizedBox(height: 4),
            Text('x ${f.num(o.xM, 0)} m · y ${f.num(o.yM, 0)} m', style: AppText.mono(11, color: AppColors.textMute)),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => showObjectiveDialog(context, m, o.id),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l.opsEdit.toUpperCase(), style: AppText.label(color: AppColors.orange)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String k, String v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
        const SizedBox(height: 4),
        Text(v, style: AppText.head(20, color: c)),
      ]);
}

/// Foto real de Curiosity con su pie: cámara, sol, fecha y crédito.
class _RoverPhotoView extends StatelessWidget {
  const _RoverPhotoView({required this.photo, required this.note});

  final RoverPhoto photo;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset(photo.asset, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          color: const Color(0xCC0E0C0B),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('CURIOSITY · ${photo.camera} · SOL ${photo.sol} · ${photo.dateTaken.substring(0, 10)}', style: AppText.mono(10, color: AppColors.text)),
            const SizedBox(height: 2),
            Text('${photo.credit} · $note', style: AppText.body(10, color: AppColors.textDim)),
          ]),
        ),
      ),
    ]);
  }
}
