import 'package:flutter/material.dart';

import '../data/site_data.dart';

/// Una tesela de [tileM] metros en (left, top). Las del borde del mapa suelen traer relleno negro más allá de los datos:
/// se recorta a lo que cabe en el mapa ([visW] × [visH] metros) para que no queden barras negras.
Widget _tile({required double left, required double top, required double tileM, required double visW, required double visH, required Image image}) {
  final w = visW < tileM ? visW : tileM, h = visH < tileM ? visH : tileM;
  if (w >= tileM && h >= tileM) {
    return Positioned(left: left, top: top, width: tileM + 0.3, height: tileM + 0.3, child: image);
  }
  return Positioned(
    left: left,
    top: top,
    width: w + (w >= tileM ? 0.3 : 0),
    height: h + (h >= tileM ? 0.3 : 0),
    child: ClipRect(
      child: OverflowBox(alignment: Alignment.topLeft, minWidth: tileM, maxWidth: tileM, minHeight: tileM, maxHeight: tileM, child: image),
    ),
  );
}

/// Teselas de la ortofoto del nivel [z] que cubren el rectángulo del mundo (x0, y0)-(x1, y1), en metros locales.
/// Cada tesela se coloca en metros, para dibujarla dentro de una transformación de escala y desplazamiento.
List<Widget> tileWidgets(SiteData d, int z, double x0, double y0, double x1, double y1) {
  final n = 1 << z;
  final tileM = d.tileSizeM(z);
  final tx0 = (x0 / tileM).floor().clamp(0, n - 1), tx1 = (x1 / tileM).floor().clamp(0, n - 1);
  final ty0 = (y0 / tileM).floor().clamp(0, n - 1), ty1 = (y1 / tileM).floor().clamp(0, n - 1);
  return [
    for (var ty = ty0; ty <= ty1; ty++)
      for (var tx = tx0; tx <= tx1; tx++)
        if (tx * tileM < d.sizeM && ty * tileM < d.sizeM)
          _tile(
            left: tx * tileM,
            top: ty * tileM,
            tileM: tileM,
            visW: d.sizeM - tx * tileM,
            visH: d.sizeM - ty * tileM,
            image: Image.asset(
              d.assetPath('ortho/$z/$tx/$ty.jpg'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
  ];
}

/// Teselas del marco de contexto del nivel [z] que cubren el rectángulo (x0, y0)-(x1, y1), en metros locales del sitio.
/// El mundo de teselas del marco empieza en la esquina noroeste del marco (`c.x`, `c.y`).
List<Widget> contextTileWidgets(SiteData d, ContextTiles c, int z, double x0, double y0, double x1, double y1) {
  final n = 1 << z;
  final tileM = c.tileSizeM(z);
  int clampN(num v) => v.floor().clamp(0, n - 1);
  final tx0 = clampN((x0 - c.x) / tileM), tx1 = clampN((x1 - c.x) / tileM);
  final ty0 = clampN((y0 - c.y) / tileM), ty1 = clampN((y1 - c.y) / tileM);
  return [
    for (var ty = ty0; ty <= ty1; ty++)
      for (var tx = tx0; tx <= tx1; tx++)
        if (tx * tileM < c.sizeM && ty * tileM < c.sizeM)
          _tile(
            left: c.x + tx * tileM,
            top: c.y + ty * tileM,
            tileM: tileM,
            visW: c.sizeM - tx * tileM,
            visH: c.sizeM - ty * tileM,
            image: Image.asset(
              c.assetDir == null ? d.assetPath('context/$z/$tx/$ty.jpg') : 'assets/${c.assetDir}/$z/$tx/$ty.jpg',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
  ];
}

/// Recorte de la ortofoto de [spanM] metros de lado centrado en (x, y), al máximo detalle.
class OrbitalCrop extends StatelessWidget {
  const OrbitalCrop({super.key, required this.data, required this.x, required this.y, this.spanM = 160, this.child});

  final SiteData data;
  final double x;
  final double y;
  final double spanM;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final side = c.biggest.shortestSide;
      final scale = side / spanM;
      final x0 = x - spanM / 2, y0 = y - spanM / 2;
      return ClipRect(
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(children: [
            Positioned.fill(
              child: Transform(
                transform: Matrix4.identity()
                  ..scaleByDouble(scale, scale, 1, 1)
                  ..translateByDouble(-x0, -y0, 0, 1),
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: data.sizeM,
                  maxHeight: data.sizeM,
                  child: SizedBox(
                    width: data.sizeM,
                    height: data.sizeM,
                    child: Stack(clipBehavior: Clip.none, children: tileWidgets(data, data.tileCount - 1, x0, y0, x0 + spanM, y0 + spanM)),
                  ),
                ),
              ),
            ),
            ?child,
          ]),
        ),
      );
    });
  }
}
