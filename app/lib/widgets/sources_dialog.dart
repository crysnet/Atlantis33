import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';

/// Una fuente de datos: de dónde sale y qué parte de la app alimenta. `kind`: `real`, `modeled` o `assumed`.
class _Src {
  const _Src(this.kind, this.title, this.en, this.es, [this.url]);

  final String kind;
  final String title;
  final String en;
  final String es;
  final String? url;
}

const List<_Src> _sources = [
  _Src('real', 'HiRISE (MRO) · USGS Astrogeology', 'Gale orthophoto (25 cm) and DEM (1 m): MSL Gale merged mosaics.', 'Ortofoto (25 cm) y relieve (1 m) de Gale: mosaicos MSL Gale del USGS.',
      'https://astrogeology.usgs.gov/search/map/mars_msl_gale_merged_dem_1m'),
  _Src('real', 'Curiosity · NASA/JPL-Caltech', 'Rover positions (waypoints) and raw Navcam photos used for the demo objectives.', 'Posiciones del rover (waypoints) y fotos crudas de Navcam de los objetivos de demostración.',
      'https://mars.nasa.gov/mmgis-maps/MSL/Layers/json/MSL_waypoints.json'),
  _Src('real', 'RAD · NASA (CDAWeb)', 'Radiation dose measured by Curiosity, per sol (MSL_RAD_OBS-L2). Only valid for Gale.', 'Dosis de radiación medida por Curiosity, por sol (MSL_RAD_OBS-L2). Solo vale para Gale.'),
  _Src('real', 'REMS · NASA PDS', 'Weather measured by Curiosity (MSL-M-REMS-5-MODRDR-V1.0). Only valid for Gale.', 'Clima medido por Curiosity (MSL-M-REMS-5-MODRDR-V1.0). Solo vale para Gale.'),
  _Src('real', 'THEMIS-IR · Mars Odyssey · NASA Mars Trek', 'Thermal layers: day brightness in Gale, night brightness in Meridiani (relative, not calibrated thermal inertia).', 'Capas térmicas: brillo de día en Gale y de noche en Meridiani (relativo, no inercia térmica calibrada).',
      'https://trek.nasa.gov/mars/'),
  _Src('real', 'HiRISE and CTX · NASA Mars Trek', 'Meridiani orthophotos and the 1 m DEM of Endeavour crater.', 'Ortofotos de Meridiani y relieve de 1 m del cráter Endeavour.', 'https://trek.nasa.gov/mars/'),
  _Src('real', 'MOLA and HRSC blend · USGS', 'Meridiani relief at 200 m (read at 100 and 400 m): local slopes are smoothed.', 'Relieve de Meridiani a 200 m (leído a 100 y 400 m): las pendientes locales salen alisadas.',
      'https://planetarymaps.usgs.gov/mosaic/Mars/HRSC_MOLA_Blend/'),
  _Src('real', 'TES · ASU Mars Space Flight Facility', 'Dust Cover Index (Ruff and Christensen, 2002) and thermal inertia (Christensen et al., 2001), at 3.5 and 7.5 km per pixel.', 'Índice de polvo (Ruff y Christensen, 2002) e inercia térmica (Christensen y otros, 2001), a 3.5 y 7.5 km por píxel.',
      'https://www.mars.asu.edu/data/tes_ruffdust/'),
  _Src('real', 'CRISM, OMEGA and Exploration Zones · NASA Mars Trek', 'Aqueous and hydrous mineral detections, and the exploration zones of the NASA 2015 workshop.', 'Detecciones de minerales acuosos e hidratados y zonas de exploración del taller de la NASA de 2015.', 'https://trek.nasa.gov/mars/'),
  _Src('real', 'Global geologic map · USGS (SIM 3292)', 'Geologic unit shown in Science (Gale).', 'Unidad geológica que muestra la pantalla Ciencia (Gale).', 'https://pubs.usgs.gov/sim/3292/'),
  _Src('modeled', 'Computed by the team', 'Slope, roughness, forbidden zones, routes, hazard and success scores, transit classes.', 'Pendiente, rugosidad, zonas prohibidas, rutas, puntajes de peligro y éxito y clases de tránsito.'),
  _Src('assumed', 'Team assumptions (not NASA values)', 'Suit speed, EVA duration, oxygen, GO / NO-GO limits, transit thresholds, rover and pair parameters, demo objectives, habitat positions. Rover limits are rounded from the Apollo lunar rover (NASA NTRS 20250011301).', 'Velocidad del traje, duración de la EVA, oxígeno, límites de GO / NO-GO, umbrales de tránsito, parámetros de rover y pareja, objetivos de demostración y posiciones del hábitat. Los límites del rover se redondean del vehículo lunar de Apolo (NASA NTRS 20250011301).'),
];

/// Lista de fuentes de datos, separada en datos reales, calculados por el equipo y supuestos.
Future<void> showSourcesDialog(BuildContext context, AppModel m) {
  final l = AppLocalizations.of(context)!;
  final es = m.locale.languageCode == 'es';
  Widget group(String kind, String title, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 14),
        Text(title.toUpperCase(), style: AppText.label(color: color)),
        const SizedBox(height: 6),
        for (final s in _sources.where((s) => s.kind == kind))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title, style: AppText.body(12.5, weight: FontWeight.w600)),
              Text(es ? s.es : s.en, style: AppText.body(11.5, color: AppColors.textDim, height: 1.35)),
              if (s.url != null) SelectableText(s.url!, style: AppText.mono(10, color: AppColors.cyan)),
            ]),
          ),
      ]);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(),
      title: Text(l.srcTitle.toUpperCase(), style: AppText.head(15)),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.srcIntro, style: AppText.body(11.5, color: AppColors.textMute, height: 1.4)),
            group('real', l.srcReal, AppColors.green),
            group('modeled', l.srcModeled, AppColors.cyan),
            group('assumed', l.srcAssumed, AppColors.amber),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.srcClose.toUpperCase(), style: AppText.label()))],
    ),
  );
}
