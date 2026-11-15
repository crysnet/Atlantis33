import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../data/site_data.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/terrain_view.dart';

/// Pantalla de casco: concepto visual de un HUD para la visera.
///
/// La posición del astronauta es simulada: se mueve con un deslizador a lo largo de la ruta seleccionada.
/// Todo lo que se muestra sale de esa ruta (distancias, rumbo, pendiente, objetivos) o de los datos reales de
/// REMS del sol de referencia (temperatura). El tiempo transcurrido y el oxígeno se interpolan de los totales
/// de la ruta. No hay signos vitales ni sensores del traje: no hay datos para ellos.
class HelmetScreen extends StatefulWidget {
  const HelmetScreen({super.key});

  @override
  State<HelmetScreen> createState() => _HelmetScreenState();
}

class _HelmetScreenState extends State<HelmetScreen> {
  /// Foto de la zona que muestra la tarjeta (se cambia tocándola).
  int _zone = 0;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final r = m.route;
    if (r == null || r.metrics == null || r.cells.length < 2) {
      return Container(color: AppColors.bg, alignment: Alignment.center, child: Text(l.helmetNoRoute, style: AppText.mono(12, color: AppColors.textDim)));
    }
    final d = m.data;
    final f = Fmt(m.locale);
    final pos = m.simPos!;
    final photo = d.roverPhotos['t2'] ?? (d.roverPhotos.isEmpty ? null : d.roverPhotos.values.first);
    final es = m.locale.languageCode == 'es';
    final cardinals = es ? const ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'] : const ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final slopeColor = pos.slopeAheadDeg > d.model.slopeCautionMax
        ? AppColors.red
        : pos.slopeAheadDeg > d.model.slopeNominalMax
            ? AppColors.amber
            : AppColors.green;

    Widget glass(Widget child, {EdgeInsets padding = const EdgeInsets.all(10)}) => Container(
          padding: padding,
          decoration: BoxDecoration(color: const Color(0xB30E0C0B), border: Border.all(color: AppColors.hairline)),
          child: child,
        );
    Widget kv(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 118, child: Text(k.toUpperCase(), style: AppText.label(color: AppColors.textMute))),
            Text(v, style: AppText.mono(13, color: color ?? AppColors.text)),
          ]),
        );

    final nextText = pos.next == null
        ? '${l.helmetHabitat} · ${f.meters(pos.distToEndM)}'
        : '${pos.next!.id.toUpperCase()} · ${f.meters(pos.distToNextM)}';

    return Container(
      color: AppColors.bg,
      child: Stack(fit: StackFit.expand, children: [
        if (photo != null)
          Positioned.fill(child: Image.asset(photo.asset, fit: BoxFit.cover, filterQuality: FilterQuality.medium))
        else
          // Sin fotos del rover (Meridiani): vista en perspectiva del relieve desde la posición y el rumbo simulados.
          Positioned.fill(child: TerrainView(data: d, x: pos.xM, y: pos.yM, headingDeg: pos.headingDeg)),
        Positioned.fill(child: Container(color: const Color(0x8C0E0C0B))),
        // Encabezado: concepto y procedencia del fondo.
        Positioned(
          left: 14,
          top: 12,
          width: 420,
          child: glass(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Tag(l.helmetConcept, color: AppColors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text(l.helmetTitle, style: AppText.head(13))),
            ]),
            const SizedBox(height: 6),
            Text(l.helmetNote, style: AppText.body(11, color: AppColors.textDim, height: 1.4)),
            const SizedBox(height: 4),
            Text(
              photo != null ? l.helmetBackdrop('${photo.camera} · SOL ${photo.sol}') : l.helmetBackdropTerrain,
              style: AppText.body(10.5, color: AppColors.textMute, height: 1.3),
            ),
          ])),
        ),
        // Brújula.
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: glass(
              SizedBox(width: 420, height: 44, child: CustomPaint(painter: _CompassPainter(pos.headingDeg, cardinals))),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          ),
        ),
        // Objetivo siguiente.
        Positioned(
          top: 72,
          left: 0,
          right: 0,
          child: Center(
            child: glass(Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.flag_outlined, size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(l.helmetNext.toUpperCase(), style: AppText.label(color: AppColors.textMute)),
              const SizedBox(width: 10),
              Text(nextText, style: AppText.head(16, color: AppColors.cyan)),
              if (pos.next != null) ...[
                const SizedBox(width: 10),
                Text(pos.next!.name, style: AppText.body(11.5, color: AppColors.textDim)),
              ],
            ])),
          ),
        ),
        // Advertencia de pendiente por delante.
        if (pos.slopeAheadDeg > d.model.slopeNominalMax)
          Positioned(
            top: 126,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xCC0E0C0B), border: Border.all(color: slopeColor, width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: slopeColor),
                  const SizedBox(width: 8),
                  Text(l.helmetSlopeWarn(f.num(pos.slopeAheadDeg, 0), f.num(pos.slopeAheadAtM, 0)), style: AppText.head(13, color: slopeColor)),
                ]),
              ),
            ),
          ),
        // Datos a la izquierda: regreso.
        Positioned(
          left: 14,
          top: 150,
          child: glass(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(l.helmetReturnTitle, style: AppText.label()),
            const SizedBox(height: 8),
            kv(l.helmetHabDist, f.meters(pos.habitatM)),
            kv(l.helmetWalkBack, f.hours(pos.walkBackH)),
            kv(l.helmetPnr, f.meters(r.metrics!.noReturn.alongM)),
            kv(l.helmetBeyondPnr, pos.alongM >= r.metrics!.noReturn.alongM ? l.helmetYes : l.helmetNo, color: pos.alongM >= r.metrics!.noReturn.alongM ? AppColors.amber : AppColors.green),
          ])),
        ),
        // Datos a la derecha: posición y entorno.
        Positioned(
          right: 14,
          top: 12,
          child: glass(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(l.helmetHereTitle, style: AppText.label()),
            const SizedBox(height: 8),
            kv(l.helmetHeading, '${f.num(pos.headingDeg, 0)}° ${cardinals[((pos.headingDeg + 22.5) % 360 ~/ 45)]}'),
            kv(l.fieldElevation, '${f.num(pos.elevM, 0)} m'),
            kv(l.fieldSlope, '${f.num(pos.slopeHereDeg, 0)}°'),
            kv(l.helmetSlopeAhead, '${f.num(pos.slopeAheadDeg, 0)}°', color: slopeColor),
            kv(l.helmetAir, pos.airC == null ? l.wxNoData : '${f.num(pos.airC!, 0)} °C'),
            kv('LMST', pos.lmstLabel),
            kv(l.helmetElapsed, f.hours(pos.elapsedH)),
            kv(l.helmetO2, pos.o2Depleted ? l.o2Depleted : f.percent(pos.o2Frac)),
          ])),
        ),
        // Foto real de la zona (Opportunity en Endeavour): referencia de cómo se ve el lugar, no de este punto.
        if (d.zonePhotos.isNotEmpty)
          Positioned(
            right: 14,
            bottom: 150,
            width: 300,
            child: _ZoneCard(
              photo: d.zonePhotos[_zone % d.zonePhotos.length],
              index: _zone % d.zonePhotos.length,
              count: d.zonePhotos.length,
              onNext: () => setState(() => _zone++),
              lang: m.locale.languageCode,
              l: l,
              f: f,
            ),
          ),
        // Control inferior: avance sobre la ruta.
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: glass(Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(
                onPressed: m.toggleSim,
                icon: Icon(m.simPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.orange),
                tooltip: m.simPlaying ? l.helmetPause : l.helmetPlay,
              ),
              Text(l.helmetProgress.toUpperCase(), style: AppText.label()),
              const SizedBox(width: 12),
              Text('${f.meters(pos.alongM)} / ${f.meters(pos.totalM)}', style: AppText.mono(12, color: AppColors.orange)),
              const Spacer(),
              Text(l.helmetSimulated, style: AppText.body(10.5, color: AppColors.textMute)),
            ]),
            Slider(value: m.simT, onChanged: m.setSimT),
            Text(l.helmetFootnote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.3)),
          ])),
        ),
      ]),
    );
  }
}

/// Tarjeta con una foto real de la zona, con su cámara, sol y crédito. Al tocarla pasa a la siguiente.
class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.photo, required this.index, required this.count, required this.onNext, required this.lang, required this.l, required this.f});

  final ZonePhoto photo;
  final int index;
  final int count;
  final VoidCallback onNext;
  final String lang;
  final AppLocalizations l;
  final Fmt f;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: l.zonePhotoNext,
        child: InkWell(
          onTap: onNext,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xD90E0C0B), border: Border.all(color: AppColors.hairline)),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(l.zonePhotoTitle.toUpperCase(), style: AppText.label(color: AppColors.textMute))),
                Text('${index + 1}/$count', style: AppText.mono(10.5, color: AppColors.textMute)),
                const SizedBox(width: 4),
                const Icon(Icons.navigate_next, size: 16, color: AppColors.orange),
              ]),
              const SizedBox(height: 6),
              Image.asset(photo.asset, width: 284, fit: BoxFit.fitWidth, filterQuality: FilterQuality.medium),
              const SizedBox(height: 6),
              Text(photo.title(lang), style: AppText.body(11, height: 1.3)),
              Text('${photo.camera} · SOL ${photo.sol} · ${photo.credit}', style: AppText.mono(9.5, color: AppColors.textMute)),
              const SizedBox(height: 2),
              Text(l.zonePhotoNote, style: AppText.body(10, color: AppColors.textMute, height: 1.3)),
            ]),
          ),
        ),
      );
}

/// Cinta de brújula: marcas cada 5° alrededor del rumbo actual.
class _CompassPainter extends CustomPainter {
  _CompassPainter(this.heading, this.cardinals);

  final double heading;
  final List<String> cardinals;

  @override
  void paint(Canvas canvas, Size size) {
    const pxPerDeg = 5.0;
    final cx = size.width / 2;
    final tick = Paint()..color = AppColors.textDim..strokeWidth = 1;
    final start = (heading - cx / pxPerDeg).floor();
    final end = (heading + cx / pxPerDeg).ceil();
    for (var deg = start; deg <= end; deg++) {
      if (deg % 5 != 0) continue;
      final x = cx + (deg - heading) * pxPerDeg;
      final dd = ((deg % 360) + 360) % 360;
      final major = dd % 15 == 0;
      canvas.drawLine(Offset(x, size.height - 2), Offset(x, size.height - (major ? 14 : 8)), tick);
      if (major) {
        final label = dd % 45 == 0 ? cardinals[dd ~/ 45] : '$dd';
        final tp = TextPainter(
          text: TextSpan(text: label, style: AppText.mono(11, color: dd % 45 == 0 ? AppColors.orange : AppColors.textDim)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 2));
      }
    }
    final marker = Path()
      ..moveTo(cx, size.height - 16)
      ..lineTo(cx - 5, size.height - 6)
      ..lineTo(cx + 5, size.height - 6)
      ..close();
    canvas.drawPath(marker, Paint()..color = AppColors.cyan);
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.heading != heading;
}
