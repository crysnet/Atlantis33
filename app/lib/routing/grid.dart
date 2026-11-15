import 'dart:typed_data';

/// Rejilla de costos a la resolución de ruteo. Las celdas se indexan en plano: fila * ancho + columna.
///
/// Orden de las celdas: filas de norte a sur, columnas de oeste a este. Coordenadas locales en metros:
/// x al este, y al sur, desde la esquina noroeste del recuadro.
/// Referencia: `tools/routing.py`, clase `Rejilla`.
class RouteGrid {
  RouteGrid._({
    required this.width,
    required this.height,
    required this.cellM,
    required this.slope,
    required this.slopeReal,
    required this.rough,
    required this.z,
    required this.blocked,
    required this.habitat,
  });

  /// Construye la rejilla a partir de los binarios exportados (`grid/*.bin`) y de `site.json`.
  ///
  /// [baseWidth] x [baseHeight] es la rejilla exportada y [baseCellM] su celda. Si [cellM] es mayor,
  /// se agrega por bloques (media de la pendiente, la rugosidad y la elevación; prohibida si la mitad o más
  /// de las celdas del bloque lo son).
  factory RouteGrid.fromBytes({
    required Uint8List slopeBytes,
    required Uint8List roughBytes,
    required Uint8List forbiddenBytes,
    required Uint8List elevBytes,
    required Map<String, dynamic> components,
    required int baseWidth,
    required int baseHeight,
    required double baseCellM,
    required int habitatRow,
    required int habitatCol,
    required double cellM,
  }) {
    final n0 = baseWidth * baseHeight;
    final slopeC = components['slope'] as Map<String, dynamic>;
    final roughC = components['rough'] as Map<String, dynamic>;
    final elevC = components['elev'] as Map<String, dynamic>;
    final slopeUnit = (slopeC['unit_deg'] as num).toDouble();
    final slopeNodata = (slopeC['nodata'] as num).toInt();
    final roughUnit = (roughC['unit_cm'] as num).toDouble();
    final roughNodata = (roughC['nodata'] as num).toInt();
    final elevUnit = (elevC['unit_m'] as num).toDouble();
    final elevOffset = (elevC['offset_m'] as num).toDouble();
    final elevNodata = (elevC['nodata'] as num).toInt();

    var slope = Float64List(n0);
    var rough = Float64List(n0);
    var z = Float64List(n0);
    var forb = Float64List(n0);
    final elev16 = ByteData.sublistView(elevBytes);
    for (var i = 0; i < n0; i++) {
      slope[i] = slopeBytes[i] == slopeNodata ? double.nan : slopeBytes[i] * slopeUnit;
      rough[i] = roughBytes[i] == roughNodata ? double.nan : roughBytes[i] * roughUnit;
      final e = elev16.getUint16(i * 2, Endian.little);
      z[i] = e == elevNodata ? double.nan : elevOffset + e * elevUnit;
      forb[i] = forbiddenBytes[i].toDouble();
    }

    var w = baseWidth;
    var h = baseHeight;
    final k = (cellM / baseCellM).round();
    if (k > 1) {
      slope = _blockMean(slope, w, h, k);
      rough = _blockMean(rough, w, h, k);
      z = _blockMean(z, w, h, k);
      forb = _blockMean(forb, w, h, k);
      for (var i = 0; i < forb.length; i++) {
        forb[i] = forb[i] >= 0.5 ? 1.0 : 0.0;
      }
      w = w ~/ k;
      h = h ~/ k;
    }
    final n = w * h;
    final blocked = Uint8List(n);
    final pend = Float64List(n);
    final pendReal = Float64List(n);
    final rug = Float64List(n);
    final zz = Float64List(n);
    for (var i = 0; i < n; i++) {
      final malo = slope[i].isNaN || z[i].isNaN || forb[i] > 0;
      blocked[i] = malo ? 1 : 0;
      pend[i] = malo ? 999.0 : slope[i];
      pendReal[i] = slope[i].isNaN ? 0.0 : slope[i];
      rug[i] = rough[i].isNaN ? 0.0 : rough[i];
      zz[i] = z[i].isNaN ? 0.0 : z[i];
    }
    return RouteGrid._(
      width: w,
      height: h,
      cellM: baseCellM * (k > 1 ? k : 1),
      slope: pend,
      slopeReal: pendReal,
      rough: rug,
      z: zz,
      blocked: blocked,
      habitat: (habitatRow ~/ (k > 1 ? k : 1)) * w + habitatCol ~/ (k > 1 ? k : 1),
    );
  }

  /// Rejilla ya armada, para pruebas con terreno sintético.
  factory RouteGrid.synthetic({
    required int width,
    required int height,
    required Float64List slope,
    Float64List? z,
    Float64List? rough,
    double cellM = 2.0,
    int habitat = 0,
  }) {
    final n = width * height;
    final blocked = Uint8List(n);
    final pend = Float64List(n);
    for (var i = 0; i < n; i++) {
      final malo = slope[i] > 25.0;
      blocked[i] = malo ? 1 : 0;
      pend[i] = slope[i];
    }
    return RouteGrid._(
      width: width,
      height: height,
      cellM: cellM,
      slope: pend,
      slopeReal: Float64List.fromList(slope),
      rough: rough ?? Float64List(n),
      z: z ?? Float64List(n),
      blocked: blocked,
      habitat: habitat,
    );
  }

  final int width;
  final int height;
  final double cellM;

  /// Pendiente en grados. 999 en celdas prohibidas o sin dato.
  final Float64List slope;

  /// Pendiente real, sin el 999. Solo para informes.
  final Float64List slopeReal;

  /// Rugosidad en centímetros.
  final Float64List rough;

  /// Elevación en metros.
  final Float64List z;

  /// 1 = celda prohibida o sin dato.
  final Uint8List blocked;

  /// Índice plano de la celda del hábitat.
  final int habitat;

  int cellOf(double xM, double yM) => (yM ~/ cellM) * width + (xM ~/ cellM);

  /// Centro de la celda, en metros locales.
  (double, double) xy(int idx) {
    final r = idx ~/ width;
    final c = idx % width;
    return ((c + 0.5) * cellM, (r + 0.5) * cellM);
  }

  /// Media de bloques de k x k que ignora NaN. Un bloque sin datos queda en NaN.
  static Float64List _blockMean(Float64List a, int w, int h, int k) {
    final w2 = w ~/ k;
    final h2 = h ~/ k;
    final out = Float64List(w2 * h2);
    for (var r = 0; r < h2; r++) {
      for (var c = 0; c < w2; c++) {
        var sum = 0.0;
        var cnt = 0;
        for (var dr = 0; dr < k; dr++) {
          for (var dc = 0; dc < k; dc++) {
            final v = a[(r * k + dr) * w + (c * k + dc)];
            if (!v.isNaN) {
              sum += v;
              cnt++;
            }
          }
        }
        out[r * w2 + c] = cnt > 0 ? sum / cnt : double.nan;
      }
    }
    return out;
  }
}
