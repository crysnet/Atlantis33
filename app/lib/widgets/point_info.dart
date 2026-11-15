import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/site_data.dart';
import '../data/vectors.dart';
import '../routing/routing.dart' show Objective;
import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

bool _inRing(List<(double, double)> ring, double x, double y) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final (xi, yi) = ring[i];
    final (xj, yj) = ring[j];
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

/// Tarjeta con lo que se sabe de un punto del mapa (coordenadas locales en metros). Sin red: todo sale del sitio cargado.
class PointInfoCard extends StatelessWidget {
  const PointInfoCard({super.key, required this.model, required this.x, required this.y, required this.onClose, required this.onCreate, this.anchor, required this.onAnchor});

  final AppModel model;
  final double x;
  final double y;
  final VoidCallback onClose;
  final VoidCallback onCreate;

  /// Punto de medida fijado antes (metros locales), o null.
  final Offset? anchor;

  /// Fija este punto como origen de la medida, o la quita si ya hay una.
  final VoidCallback onAnchor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = model.data;
    final f = Fmt(model.locale);
    final inside = x >= 0 && y >= 0 && x < d.sizeM && y < d.sizeM;
    final (lon, lat) = d.lonLat(x, y);

    final rows = <(String, String)>[
      (l.probeCoords, f.latLon(lon, lat)),
      (l.probeLocal, 'x ${f.num(x, 0)} m · y ${f.num(y, 0)} m'),
    ];
    if (inside) {
      final z = d.elevationAt(x, y);
      final s = d.slopeAt(x, y);
      final r = d.grid.rough[d.grid.cellOf(x, y)];
      rows.add((l.elevation, z == null || z.isNaN ? l.probeNoData : '${f.num(z, 0)} m'));
      rows.add((l.probeSlope, s == null || s.isNaN ? l.probeNoData : '${f.num(s, 1)}°'));
      if (r > 0) rows.add((l.probeRough, '${f.num(r, 0)} cm'));
      rows.add((l.probeTerrain, d.isBlocked(x, y) ? l.probeTerrainBlocked : l.probeTerrainOk));
    }
    rows.add((l.probeToHabitat, f.km(math.sqrt(math.pow(x - d.habitatX, 2) + math.pow(y - d.habitatY, 2)).toDouble(), 2)));

    final a = anchor;
    if (a != null) {
      final dist = math.sqrt(math.pow(x - a.dx, 2) + math.pow(y - a.dy, 2)).toDouble();
      final z0 = d.elevationAt(a.dx, a.dy);
      final z1 = d.elevationAt(x, y);
      final dz = (z0 == null || z1 == null || z0.isNaN || z1.isNaN) ? null : z1 - z0;
      rows.add((l.probeMeasured, '${dist >= 1000 ? f.km(dist, 2) : f.meters(dist)}${dz == null ? '' : ' · Δ ${dz >= 0 ? '+' : '−'}${f.num(dz.abs(), 0)} m'}'));
    }

    final cells = model.route?.cells ?? const <int>[];
    if (cells.isNotEmpty) {
      var best = double.infinity;
      for (final c in cells) {
        final (cx, cy) = d.grid.xy(c);
        final dd = (cx - x) * (cx - x) + (cy - y) * (cy - y);
        if (dd < best) best = dd;
      }
      rows.add((l.probeToRoute, f.meters(math.sqrt(best))));
    } else {
      rows.add((l.probeToRoute, l.probeNoRoute));
    }

    // Geología y dunas: la unidad que contiene el punto.
    for (final a in d.vectors.areas) {
      if (a.rings.isEmpty || !_inRing(a.rings.first, x, y)) continue;
      if (a.rings.skip(1).any((h) => _inRing(h, x, y))) continue;
      final dune = a.kind == 'landform';
      rows.add((dune ? l.probeDune : l.probeGeology, dune || a.desc.isEmpty ? a.unit : '${a.unit} · ${a.desc}'));
    }

    // Rasgo con nombre más cercano (dentro de 2 km).
    NameFeature? nn;
    var nd = 2000.0;
    for (final n in d.vectors.names) {
      final dd = math.sqrt(math.pow(n.x - x, 2) + math.pow(n.y - y, 2)).toDouble();
      if (dd < nd) {
        nd = dd;
        nn = n;
      }
    }
    if (nn != null) rows.add((l.probeNearName, '${nn.name}${nn.type.isEmpty ? '' : ' (${nn.type})'} · ${f.meters(nd)}'));

    // Objetivo más cercano; si trae foto real del rover y está a menos de 250 m, se muestra.
    Objective? no;
    var od = double.infinity;
    for (final o in model.objectives) {
      final dd = math.sqrt(math.pow(o.xM - x, 2) + math.pow(o.yM - y, 2)).toDouble();
      if (dd < od) {
        od = dd;
        no = o;
      }
    }
    if (no != null) rows.add((l.probeNearObjective, '${no.id.toUpperCase()} · ${no.name} · ${f.meters(od)}'));
    final photo = (no != null && od < 250) ? d.roverPhotos[no.id] : null;

    // Mineral más cercano (dentro de 1 km).
    MineralPoint? mn;
    var md = 1000.0;
    for (final q in d.vectors.minerals) {
      final dd = math.sqrt(math.pow(q.x - x, 2) + math.pow(q.y - y, 2)).toDouble();
      if (dd < md) {
        md = dd;
        mn = q;
      }
    }
    if (mn != null) {
      final cls = switch (mn.cls) {
        'sulfate' => l.probeMineralSulfate,
        'phyllosilicate' => l.probeMineralPhyllo,
        _ => l.probeMineralHydrous,
      };
      rows.add((l.probeMineral, '$cls · ${f.meters(md)}'));
    }

    // Curiosity: el waypoint más cercano si pasó a menos de 150 m.
    CuriosityPoint? cp;
    var cd = 150.0;
    for (final p in d.curiosity) {
      final dd = math.sqrt(math.pow(p.x - x, 2) + math.pow(p.y - y, 2)).toDouble();
      if (dd < cd) {
        cd = dd;
        cp = p;
      }
    }
    if (cp != null) rows.add((d.assetDir.startsWith('site_meridiani') ? l.probeOpportunity : l.probeCuriosity, 'sol ${cp.sol} · ${f.meters(cd)}'));

    return Container(
      width: 300,
      decoration: BoxDecoration(color: AppColors.panel.withValues(alpha: 0.96), border: Border.all(color: AppColors.cyan)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(children: [
            Expanded(child: Text(l.probeTitle, style: AppText.label(color: AppColors.cyan))),
            InkWell(
              onTap: onClose,
              child: Tooltip(message: l.probeClose, child: const SizedBox(width: 30, height: 30, child: Icon(Icons.close, size: 16, color: AppColors.textDim))),
            ),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final (k, v) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k, style: AppText.mono(9, color: AppColors.textDim)),
                    Text(v, style: AppText.mono(12, color: AppColors.text)),
                  ]),
                ),
              if (photo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.probePhoto, style: AppText.mono(9, color: AppColors.textDim)),
                    const SizedBox(height: 3),
                    Image.asset(photo.asset, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    Text('${photo.camera} · sol ${photo.sol}', style: AppText.mono(9, color: AppColors.textDim)),
                  ]),
                ),
              if (!inside)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.probeOutside, style: AppText.mono(10, color: AppColors.amber))),
            ]),
          ),
        ),
        if (inside)
          InkWell(
            onTap: onAnchor,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
              child: Center(child: Text(anchor == null ? l.probeMeasureFrom : l.probeMeasureClear, style: AppText.label(color: AppColors.amber))),
            ),
          ),
        if (inside)
          InkWell(
            onTap: onCreate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
              child: Center(child: Text(l.probeCreate, style: AppText.label(color: AppColors.cyan))),
            ),
          ),
      ]),
    );
  }
}
