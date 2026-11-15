import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../util/sim_pos.dart';
import '../widgets/common.dart';
import '../widgets/map_view.dart';

/// Misión: el mapa con el astronauta simulado y, al lado, la telemetría del traje en esa posición.
///
/// La posición avanza por la ruta seleccionada. Cada lectura sale del modelo (elevación, pendiente, rumbo, objetivos),
/// de REMS (temperatura del aire) o se interpola de los totales de la ruta (tiempo, oxígeno, dosis). No hay signos
/// vitales ni sensores del traje.
class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final pos = m.simPos;
    if (pos == null) {
      return Container(color: AppColors.bg, alignment: Alignment.center, child: Text(l.helmetNoRoute, style: AppText.mono(12, color: AppColors.textDim)));
    }
    return Row(children: [
      const Expanded(child: MapView(forceSim: true)),
      const VerticalDivider(width: 1),
      SizedBox(width: 350, child: _SuitPanel(m: m, pos: pos)),
    ]);
  }
}

class _SuitPanel extends StatelessWidget {
  const _SuitPanel({required this.m, required this.pos});

  final AppModel m;
  final SimPos pos;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final f = Fmt(m.locale);
    final d = m.data;
    final met = m.route!.metrics!;
    final cardinals = m.locale.languageCode == 'es' ? const ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'] : const ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

    // Alertas de la posición simulada: (texto, rojo si es grave).
    final alerts = <(String, bool)>[];
    if (pos.slopeAheadDeg > d.model.slopeCautionMax) {
      alerts.add((l.helmetSlopeWarn(f.num(pos.slopeAheadDeg, 0), f.num(pos.slopeAheadAtM, 0)), true));
    } else if (pos.slopeAheadDeg > d.model.slopeNominalMax) {
      alerts.add((l.helmetSlopeWarn(f.num(pos.slopeAheadDeg, 0), f.num(pos.slopeAheadAtM, 0)), false));
    }
    final pastPnr = pos.alongM >= met.noReturn.alongM;
    if (pastPnr) alerts.add((l.missionAlertPnr, false));
    final reserve = pos.o2Frac - pos.o2NeedBackFrac;
    if (reserve < 0) {
      alerts.add((l.missionAlertO2, true));
    } else if (reserve < 0.10) {
      alerts.add((l.missionAlertO2Low, false));
    }
    final (statusText, statusColor) = alerts.any((a) => a.$2)
        ? (l.missionAlert, AppColors.red)
        : alerts.isNotEmpty
            ? (l.missionCaution, AppColors.amber)
            : (l.missionNominal, AppColors.green);

    Widget kv(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute))),
            const SizedBox(width: 8),
            Text(v, style: AppText.mono(12.5, color: color ?? AppColors.text)),
          ]),
        );
    Widget group(String title, List<Widget> rows) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.label()),
            const SizedBox(height: 6),
            ...rows,
          ]),
        );

    final (lon, lat) = d.lonLat(pos.xM, pos.yM);
    final nextText = pos.next == null ? '${l.helmetHabitat} · ${f.meters(pos.distToEndM)}' : '${pos.next!.id.toUpperCase()} · ${f.meters(pos.distToNextM)}';
    final o2Color = reserve < 0 ? AppColors.red : (reserve < 0.10 ? AppColors.amber : AppColors.green);

    return Container(
      color: AppColors.panel,
      child: Column(children: [
        SectionHeader(
          icon: Icons.sensors,
          title: l.missionTitle,
          trailing: Tag(l.helmetSimulated, color: AppColors.amber),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: statusColor), color: statusColor.withValues(alpha: 0.08)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(l.missionStatus.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
                  const Spacer(),
                  Text(m.simT >= 1.0 ? l.missionDone : statusText, style: AppText.head(14, color: m.simT >= 1.0 ? AppColors.text : statusColor)),
                ]),
                const SizedBox(height: 6),
                if (alerts.isEmpty)
                  Text(l.missionAllClear, style: AppText.body(11.5, color: AppColors.textDim))
                else
                  for (final a in alerts)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: a.$2 ? AppColors.red : AppColors.amber),
                        const SizedBox(width: 6),
                        Expanded(child: Text(a.$1, style: AppText.body(11.5, color: a.$2 ? AppColors.red : AppColors.amber, height: 1.3))),
                      ]),
                    ),
              ]),
            ),
            const SizedBox(height: 12),
            group(l.missionPosition, [
              kv('LAT / LON', f.latLon(lon, lat)),
              kv(l.fieldElevation, '${f.num(pos.elevM, 0)} m'),
              kv(l.fieldSlope, '${f.num(pos.slopeHereDeg, 0)}°'),
              kv(l.helmetHeading, '${f.num(pos.headingDeg, 0)}° ${cardinals[((pos.headingDeg + 22.5) % 360 ~/ 45)]}'),
              kv(l.helmetNext, nextText, color: AppColors.cyan),
            ]),
            group('SUIT', [
              kv(l.helmetO2, f.percent(pos.o2Frac), color: o2Color),
              kv(l.missionO2Need, f.percent(pos.o2NeedBackFrac)),
              kv(l.missionO2Reserve, f.percent(reserve < 0 ? 0 : reserve), color: o2Color),
              kv(l.missionDose, '${f.num(pos.doseUGy, 0)} µGy'),
              kv(l.helmetAir, pos.airC == null ? l.wxNoData : '${f.num(pos.airC!, 0)} °C'),
            ]),
            group(l.helmetReturnTitle, [
              kv(l.helmetHabDist, f.meters(pos.habitatM)),
              kv(l.helmetWalkBack, f.hours(pos.walkBackH)),
              kv(l.helmetPnr, f.meters(met.noReturn.alongM)),
              kv(l.helmetBeyondPnr, pastPnr ? l.helmetYes : l.helmetNo, color: pastPnr ? AppColors.amber : AppColors.green),
            ]),
            group(l.helmetProgress, [
              kv('LMST', pos.lmstLabel),
              kv(l.helmetElapsed, f.hours(pos.elapsedH)),
              kv(l.helmetProgress, '${f.meters(pos.alongM)} / ${f.meters(pos.totalM)}'),
            ]),
            Text(l.missionNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.4)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 14, 8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              IconButton(
                onPressed: m.toggleSim,
                icon: Icon(m.simPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.orange),
                tooltip: m.simPlaying ? l.helmetPause : l.helmetPlay,
              ),
              IconButton(onPressed: m.resetSim, icon: const Icon(Icons.replay, color: AppColors.textDim), tooltip: l.missionReset),
              const Spacer(),
              Text(l.missionSpeed.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
              const SizedBox(width: 8),
              for (final s in const [1, 2, 4, 8])
                InkWell(
                  onTap: () => m.setSimSpeed(s),
                  child: Container(
                    width: 34,
                    height: 26,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: m.simSpeed == s ? AppColors.orange : Colors.transparent,
                      border: Border.all(color: m.simSpeed == s ? AppColors.orange : AppColors.hairline),
                    ),
                    child: Text('${s}x', style: AppText.mono(11, color: m.simSpeed == s ? AppColors.bg : AppColors.textDim, weight: FontWeight.w700)),
                  ),
                ),
            ]),
            Slider(value: m.simT, onChanged: m.setSimT),
          ]),
        ),
      ]),
    );
  }
}
