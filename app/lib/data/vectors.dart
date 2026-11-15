class MineralPoint {
  const MineralPoint({
    required this.cls,
    required this.source,
    required this.x,
    required this.y,
  });

  final String cls;
  final String source;
  final double x;
  final double y;
}

class ZoneFeature {
  const ZoneFeature({
    required this.type,
    required this.name,
    this.x,
    this.y,
    this.ring,
  });

  final String type;
  final String name;
  final double? x;
  final double? y;
  final List<(double, double)>? ring;
}

class CraterFeature {
  const CraterFeature({
    required this.x,
    required this.y,
    required this.diameterM,
    required this.id,
  });

  final double x;
  final double y;
  final double diameterM;
  final String id;
}

class NameFeature {
  const NameFeature({
    required this.name,
    required this.type,
    required this.x,
    required this.y,
  });

  final String name;
  final String type;
  final double x;
  final double y;
}

class AreaFeature {
  const AreaFeature({
    required this.kind,
    required this.unit,
    required this.desc,
    required this.rings,
  });

  final String kind;
  final String unit;
  final String desc;
  final List<List<(double, double)>> rings;
}

List<(double, double)> _parseRing(List raw) => [
      for (final pt in raw)
        (((pt as List)[0] as num).toDouble(), (pt[1] as num).toDouble()),
    ];

class SiteVectors {
  const SiteVectors({
    this.minerals = const [],
    this.zones = const [],
    this.craters = const [],
    this.names = const [],
    this.areas = const [],
  });

  static const SiteVectors empty = SiteVectors();

  final List<MineralPoint> minerals;
  final List<ZoneFeature> zones;
  final List<CraterFeature> craters;
  final List<NameFeature> names;
  final List<AreaFeature> areas;

  factory SiteVectors.fromJson(Map<String, dynamic> j) {
    final minerals = <MineralPoint>[];
    final zones = <ZoneFeature>[];
    final craters = <CraterFeature>[];
    final names = <NameFeature>[];
    final areas = <AreaFeature>[];

    for (final item in (j['features'] as List? ?? const [])) {
      final f = item as Map<String, dynamic>;
      final kind = f['kind'] as String? ?? '';
      switch (kind) {
        case 'mineral':
          minerals.add(
            MineralPoint(
              cls: f['cls'] as String? ?? '',
              source: f['source'] as String? ?? '',
              x: (f['x_m'] as num).toDouble(),
              y: (f['y_m'] as num).toDouble(),
            ),
          );
        case 'zone':
          final rawRing = f['ring'] as List?;
          zones.add(
            ZoneFeature(
              type: f['type'] as String? ?? '',
              name: f['name'] as String? ?? '',
              x: (f['x_m'] as num?)?.toDouble(),
              y: (f['y_m'] as num?)?.toDouble(),
              ring: rawRing != null ? _parseRing(rawRing) : null,
            ),
          );
        case 'crater':
          craters.add(
            CraterFeature(
              x: (f['x_m'] as num).toDouble(),
              y: (f['y_m'] as num).toDouble(),
              diameterM: (f['d_m'] as num).toDouble(),
              id: f['id'] as String? ?? '',
            ),
          );
        case 'name':
          names.add(
            NameFeature(
              name: f['name'] as String? ?? '',
              type: f['type'] as String? ?? '',
              x: (f['x_m'] as num).toDouble(),
              y: (f['y_m'] as num).toDouble(),
            ),
          );
        case 'landform':
          final rawRing = f['ring'] as List?;
          if (rawRing != null) {
            areas.add(
              AreaFeature(
                kind: 'landform',
                unit: f['name'] as String? ?? f['type'] as String? ?? 'Dune',
                desc: f['type'] as String? ?? '',
                rings: [_parseRing(rawRing)],
              ),
            );
          }
        case 'geology':
          final rawRings = f['rings'] as List? ?? const [];
          areas.add(
            AreaFeature(
              kind: 'geology',
              unit: f['unit'] as String? ?? '',
              desc: f['desc'] as String? ?? '',
              rings: [for (final r in rawRings) _parseRing(r as List)],
            ),
          );
      }
    }

    return SiteVectors(
      minerals: minerals,
      zones: zones,
      craters: craters,
      names: names,
      areas: areas,
    );
  }
}
