import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';

/// Cabecera de sección: icono, título en mayúsculas y un widget opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textDim),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: AppText.head(13), overflow: TextOverflow.ellipsis)),
          ?trailing,
        ]),
      );
}

/// Etiqueta pequeña con borde, para el origen del dato, el estado y las prioridades.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = AppColors.textDim, this.filled = false});

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(text, style: AppText.mono(9.5, color: color, weight: FontWeight.w600)),
      );
}

Color kindColor(LayerKind k) => switch (k) {
      LayerKind.measured => AppColors.cyan,
      LayerKind.modeled => AppColors.orange,
      LayerKind.example => AppColors.textMute,
    };

String kindText(AppLocalizations l, LayerKind k) => switch (k) {
      LayerKind.measured => l.kindMeasured,
      LayerKind.modeled => l.kindModeled,
      LayerKind.example => l.kindExample,
    };

String routeName(AppLocalizations l, String profile) => switch (profile) {
      'safe' => l.routeSafe,
      'fast' => l.routeFast,
      'pair1' => l.routePair1,
      'pair2' => l.routePair2,
      _ => l.routeScience,
    };

String typeName(AppLocalizations l, String type) => switch (type) {
      'image' => l.typeImage,
      'measurement' => l.typeMeasurement,
      'equipment' => l.typeEquipment,
      _ => l.typeSample,
    };

String layerName(AppLocalizations l, String id) => switch (id) {
      'optical' => l.layerOptical,
      'hillshade' => l.layerHillshade,
      'slope' => l.layerSlope,
      'forbidden' => l.layerForbidden,
      'curiosity' => l.layerCuriosity,
      'thermal' => l.layerThermal,
      'minerals' => l.layerMinerals,
      'slope15' => l.layerSlope15,
      'transit' => l.layerTransit,
      'thermal_night' => l.layerThermalNight,
      'aqueous_pts' => l.layerAqueousPts,
      'hydrous_pts' => l.layerHydrousPts,
      'valleys' => l.layerValleys,
      'zones' => l.layerZones,
      'names' => l.layerNames,
      'craters' => l.layerCraters,
      'geology' => l.layerGeology,
      _ => l.layerRadiation,
    };

String reasonName(AppLocalizations l, String reason) => switch (reason) {
      'blocked' => l.reasonBlocked,
      'unreachable' => l.reasonUnreachable,
      'time' => l.reasonTime,
      'oxygen' => l.reasonOxygen,
      'margin' => l.reasonMargin,
      'rover' => l.reasonRover,
      'other_astronaut' => l.reasonOtherAstronaut,
      'not_in_pair' => l.reasonNotInPair,
      _ => l.reasonNotPrimary,
    };

String transportName(AppLocalizations l, String t) => switch (t) {
      'vehicle' => l.transportVehicle,
      'hybrid' => l.transportHybrid,
      _ => l.transportFoot,
    };

/// Aviso del transporte por objetivo (motivo de `RouteResult.transport['notes']`), con el nombre del objetivo.
String transportNote(AppLocalizations l, String reason, String name) => switch (reason) {
      'rover_not_here' => l.transportNoteNotHere(name),
      'rover_cannot_start' => l.transportNoteCannotStart(name),
      'rover_blocked' => l.transportNoteBlocked(name),
      'vehicle_partial' => l.transportNotePartial(name),
      'no_recovery' => l.transportNoteNoRecovery(name),
      _ => l.transportNoteStranded,
    };

/// Barra horizontal de 0 a 1 con relleno de color.
///
/// No usa `LayoutBuilder` a propósito: se coloca dentro de `IntrinsicHeight`, que no admite `LayoutBuilder`
/// (la build de release lo ignora, pero el modo desarrollo lanza una aserción).
class MeterBar extends StatelessWidget {
  const MeterBar({super.key, required this.value, required this.color, this.height = 5});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.panel3)),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: value.clamp(0.0, 1.0), heightFactor: 1.0, child: ColoredBox(color: color)),
          ),
        ]),
      );
}
