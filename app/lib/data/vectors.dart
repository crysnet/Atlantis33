/// Un mineral detectado desde órbita: punto en coordenadas locales del sitio.
class MineralPoint {
  const MineralPoint({required this.cls, required this.source, required this.x, required this.y});

  factory MineralPoint.fromJson(Map<String, dynamic> j) => MineralPoint(
        cls: j['cls'] as String,
        source: (j['source'] as String?) ?? '',
        x: (j['x_m'] as num).toDouble(),
        y: (j['y_m'] as num).toDouble(),
      );

  /// `sulfate`, `phyllosilicate` o `hydrous`.
  final String cls;

  /// `aqueous` (distribución de minerales acuosos), `CRISM` u `OMEGA`.
  final String source;
  final double x;
  final double y;
}

/// Una zona de exploración, zona habitable, sitio de aterrizaje o región de interés: un punto o un contorno.
class ZoneFeature {
  const ZoneFeature({required this.type, required this.name, this.x, this.y, this.ring});

  factory ZoneFeature.fromJson(Map<String, dynamic> j) => ZoneFeature(
        type: j['type'] as String,
        name: (j['name'] as String?) ?? '',
        x: (j['x_m'] as num?)?.toDouble(),
        y: (j['y_m'] as num?)?.toDouble(),
        ring: j['ring'] == null ? null : [for (final p in j['ring'] as List) ((p as List)[0] as num, p[1] as num)].map((p) => (p.$1.toDouble(), p.$2.toDouble())).toList(),
      );

  /// `ez`, `habitation`, `landing`, `roi` o `ez_radius`.
  final String type;
  final String name;
  final double? x;
  final double? y;

  /// Contorno cerrado en coordenadas locales, para `roi` y `ez_radius`.
  final List<(double, double)>? ring;
}

/// Cráter de la base de Robbins (1 km o más): centro y diámetro en metros.
class CraterFeature {
  const CraterFeature({required this.x, required this.y, required this.diameterM});

  factory CraterFeature.fromJson(Map<String, dynamic> j) =>
      CraterFeature(x: (j['x_m'] as num).toDouble(), y: (j['y_m'] as num).toDouble(), diameterM: (j['d_m'] as num).toDouble());

  final double x;
  final double y;
  final double diameterM;
}

/// Red de valles (Hynek et al. 2010): una o más líneas en coordenadas locales (recortadas al mapa base).
class ValleyFeature {
  const ValleyFeature({required this.paths});

  factory ValleyFeature.fromJson(Map<String, dynamic> j) => ValleyFeature(paths: [
        for (final line in j['paths'] as List)
          [for (final p in line as List) (((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
      ]);

  final List<List<(double, double)>> paths;
}

/// Nombre oficial de la UAI de un rasgo.
class NameFeature {
  const NameFeature({required this.name, required this.type, required this.x, required this.y});

  factory NameFeature.fromJson(Map<String, dynamic> j) => NameFeature(
        name: j['name'] as String,
        type: (j['type'] as String?) ?? '',
        x: (j['x_m'] as num).toDouble(),
        y: (j['y_m'] as num).toDouble(),
      );

  final String name;

  /// Tipo de rasgo en latín (`Crater`, `Mons`, `Vallis`...).
  final String type;
  final double x;
  final double y;
}

/// Polígono del mapa geológico global (unidad con sus anillos: el primero es el exterior y los demás, huecos) o un campo de dunas.
class AreaFeature {
  const AreaFeature({required this.kind, required this.unit, required this.desc, required this.rings});

  factory AreaFeature.fromJson(Map<String, dynamic> j) => AreaFeature(
        kind: j['kind'] as String,
        unit: (j['unit'] as String?) ?? 'dune',
        desc: (j['desc'] as String?) ?? (j['name'] as String?) ?? '',
        rings: [for (final r in (j['rings'] ?? [j['ring']]) as List) _ring(r as List)],
      );

  static List<(double, double)> _ring(List r) {
    final out = <(double, double)>[];
    for (final p in r) {
      final q = p as List;
      out.add(((q[0] as num).toDouble(), (q[1] as num).toDouble()));
    }
    return out;
  }

  /// `geology` o `landform`.
  final String kind;

  /// Código de la unidad geológica (`Htu`, `mNh`...) o `dune`.
  final String unit;
  final String desc;
  final List<List<(double, double)>> rings;
}

/// Capas vectoriales de un sitio (`vectors.json`): minerales, zonas de exploración, cráteres, nombres, geología, dunas y redes de valles.
/// Vacío si el sitio no las trae.
class SiteVectors {
  const SiteVectors({this.minerals = const [], this.zones = const [], this.craters = const [], this.names = const [], this.areas = const [], this.valleys = const []});

  factory SiteVectors.fromJson(Map<String, dynamic> j) {
    final f = (j['features'] as List).cast<Map<String, dynamic>>();
    return SiteVectors(
      minerals: [for (final q in f) if (q['kind'] == 'mineral') MineralPoint.fromJson(q)],
      zones: [for (final q in f) if (q['kind'] == 'zone') ZoneFeature.fromJson(q)],
      craters: [for (final q in f) if (q['kind'] == 'crater') CraterFeature.fromJson(q)],
      names: [for (final q in f) if (q['kind'] == 'name') NameFeature.fromJson(q)],
      areas: [for (final q in f) if (q['kind'] == 'geology' || q['kind'] == 'landform') AreaFeature.fromJson(q)],
      valleys: [for (final q in f) if (q['kind'] == 'valley') ValleyFeature.fromJson(q)],
    );
  }

  final List<MineralPoint> minerals;
  final List<ZoneFeature> zones;
  final List<CraterFeature> craters;
  final List<NameFeature> names;

  /// Unidades geológicas y campos de dunas.
  final List<AreaFeature> areas;

  /// Redes de valles (solo Meridiani).
  final List<ValleyFeature> valleys;
}
