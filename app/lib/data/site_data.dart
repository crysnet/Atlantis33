import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../routing/routing.dart';
import 'environment_data.dart';
import 'vectors.dart';

/// Posición real de Curiosity (waypoint de la NASA) en coordenadas locales.
class CuriosityPoint {
  const CuriosityPoint({required this.sol, required this.x, required this.y, required this.elev, required this.campaign});

  final int sol;
  final double x;
  final double y;
  final double elev;

  /// Pertenece a la campaña boxwork.
  final bool campaign;
}

/// Foto real de Curiosity asociada a un objetivo de demostración.
class RoverPhoto {
  const RoverPhoto({required this.sol, required this.camera, required this.dateTaken, required this.credit, required this.file, this.assetDir = 'site_gale'});

  final int sol;
  final String camera;
  final String dateTaken;
  final String credit;

  /// Nombre del archivo en `assets/<assetDir>/rover/`.
  final String file;

  /// Carpeta de assets del sitio al que pertenece la foto.
  final String assetDir;

  String get asset => 'assets/$assetDir/rover/$file';
}

/// Foto real de la zona (no de un objetivo): imagen de prensa del JPL, de Opportunity en Perseverance Valley.
class ZonePhoto {
  const ZonePhoto({required this.file, required this.camera, required this.sol, required this.dateTaken, required this.titleEn, required this.titleEs, required this.credit, required this.assetDir});

  factory ZonePhoto.fromJson(Map<String, dynamic> j, String assetDir) => ZonePhoto(
        file: j['file'] as String,
        camera: j['camera'] as String,
        sol: (j['sol'] as num).toInt(),
        dateTaken: j['date_taken'] as String,
        titleEn: j['title_en'] as String,
        titleEs: j['title_es'] as String,
        credit: j['credit'] as String,
        assetDir: assetDir,
      );

  final String file;
  final String camera;

  /// Sol de la primera imagen (algunos mosaicos abarcan varios).
  final int sol;
  final String dateTaken;
  final String titleEn;
  final String titleEs;
  final String credit;
  final String assetDir;

  String get asset => 'assets/$assetDir/$file';
  String title(String lang) => lang == 'es' ? titleEs : titleEn;
}

/// Marco de contexto: teselas más gruesas que cubren mucho más que la ventana del sitio. Coordenadas locales del sitio
/// (la esquina noroeste del marco puede tener x e y negativas).
class ContextTiles {
  const ContextTiles({required this.x, required this.y, required this.sizeM, required this.maxZoom, required this.tileMPerPx, this.assetDir});

  factory ContextTiles.fromJson(Map<String, dynamic> j) => ContextTiles(
        x: (j['x_m'] as num).toDouble(),
        y: (j['y_m'] as num).toDouble(),
        sizeM: (j['size_m'] as num).toDouble(),
        maxZoom: (j['max_zoom'] as num).toInt(),
        tileMPerPx: [for (final m in j['m_per_px'] as List) (m as num).toDouble()],
        assetDir: j['asset_dir'] as String?,
      );

  /// Carpeta de assets compartida (mapa base de una región); null si las teselas están en `context/` del sitio.
  final String? assetDir;

  final double x;
  final double y;

  /// Lado del marco en metros.
  final double sizeM;
  final int maxZoom;

  /// Metros por píxel de cada nivel; el mundo de teselas tiene `512 * 2^z * tileMPerPx[z]` metros de lado.
  final List<double> tileMPerPx;

  double tileSizeM(int z) => 512 * tileMPerPx[z];
}

/// Todo lo que la app carga al arrancar: el sitio, la rejilla de costos, el modelo y los objetivos de ejemplo.
///
/// Coordenadas locales en metros: x al este, y al sur, desde la esquina noroeste del recuadro.
class SiteData {
  SiteData._({
    required this.site,
    required this.params,
    required this.grid,
    required this.model,
    required this.objectives,
    required this.curiosity,
    required this.sizeM,
    required this.habitatX,
    required this.habitatY,
    required this.originE,
    required this.originN,
    required this.radiusM,
    required this.tileMPerPx,
    required this.tileCount,
    required this.environment,
    required this.envConfig,
    required this.roverPhotos,
    required this.assetDir,
    this.vectors = const SiteVectors(),
    this.zonePhotos = const [],
    this.context,
    this.base,
  });

  /// Carga el sitio de la carpeta `assets/<assetDir>/` (por defecto, Gale).
  static Future<SiteData> load([String assetDir = 'site_gale']) async {
    Future<Map<String, dynamic>> json(String name) async =>
        jsonDecode(await rootBundle.loadString('assets/$assetDir/$name')) as Map<String, dynamic>;
    final site = await json('site.json');
    final params = await json('params.json');
    final objectives = await json('objectives.json');
    final waypoints = await json('curiosity_waypoints.json');
    final environment = EnvironmentData.fromJson(await json('environment.json'));
    final photos = await json('rover_photos.json');
    // Fotos de la zona: la carpeta de assets que nombra `zone_photos` en site.json (solo los sitios de Endeavour).
    var zonePhotos = const <ZonePhoto>[];
    final zoneDir = site['zone_photos'] as String?;
    if (zoneDir != null) {
      final raw = jsonDecode(await rootBundle.loadString('assets/$zoneDir/zone_photos.json')) as List;
      zonePhotos = [for (final j in raw) ZonePhoto.fromJson(j as Map<String, dynamic>, zoneDir)];
    }
    var vectors = const SiteVectors();
    try {
      vectors = SiteVectors.fromJson(await json('vectors.json'));
    } catch (_) {
      // el sitio no trae capas vectoriales (Gale)
    }

    Future<Uint8List> bin(String name) async => (await rootBundle.load('assets/$assetDir/grid/$name')).buffer.asUint8List();
    final g = site['grid'] as Map<String, dynamic>;
    final h = site['habitat'] as Map<String, dynamic>;
    final model = RoutingModel.fromParams(params);
    final grid = RouteGrid.fromBytes(
      slopeBytes: await bin('slope.bin'),
      roughBytes: await bin('rough.bin'),
      forbiddenBytes: await bin('forbidden.bin'),
      elevBytes: await bin('elev.bin'),
      components: g['components'] as Map<String, dynamic>,
      baseWidth: g['width'] as int,
      baseHeight: g['height'] as int,
      baseCellM: (g['cell_m'] as num).toDouble(),
      habitatRow: h['row'] as int,
      habitatCol: h['col'] as int,
      cellM: model.cellM,
    );
    final geo = site['georeference'] as Map<String, dynamic>;
    final tiles = site['tiles'] as Map<String, dynamic>;
    final points = <CuriosityPoint>[
      for (final p in waypoints['points'] as List)
        CuriosityPoint(
          sol: (p['sol'] as num).toInt(),
          x: (p['x_m'] as num).toDouble(),
          y: (p['y_m'] as num).toDouble(),
          elev: (p['elev_m'] as num).toDouble(),
          campaign: p['boxwork_campaign'] as bool,
        ),
    ]..sort((a, b) => a.sol.compareTo(b.sol));
    return SiteData._(
      site: site,
      params: params,
      grid: grid,
      model: model,
      objectives: [for (final o in objectives['objectives'] as List) Objective.fromJson(o as Map<String, dynamic>)],
      curiosity: points,
      sizeM: ((site['frame'] as Map<String, dynamic>)['size_m'] as num).toDouble(),
      habitatX: (h['x_m'] as num).toDouble(),
      habitatY: (h['y_m'] as num).toDouble(),
      originE: (geo['origin_easting_m'] as num).toDouble(),
      originN: (geo['origin_northing_m'] as num).toDouble(),
      radiusM: (geo['radius_m'] as num).toDouble(),
      tileMPerPx: [for (final m in tiles['m_per_px'] as List) (m as num).toDouble()],
      tileCount: ((tiles['max_zoom'] as num).toInt()) + 1,
      environment: environment,
      envConfig: EnvConfig.fromParams(params),
      roverPhotos: {
        for (final e in photos.entries)
          e.key: RoverPhoto(
            sol: ((e.value as Map<String, dynamic>)['sol'] as num).toInt(),
            camera: (e.value as Map<String, dynamic>)['camera'] as String,
            dateTaken: (e.value as Map<String, dynamic>)['date_taken'] as String,
            credit: (e.value as Map<String, dynamic>)['credit'] as String,
            file: (e.value as Map<String, dynamic>)['file'] as String,
            assetDir: assetDir,
          ),
      },
      assetDir: assetDir,
      vectors: vectors,
      zonePhotos: zonePhotos,
      context: site['context'] == null ? null : ContextTiles.fromJson(site['context'] as Map<String, dynamic>),
      base: site['base'] == null ? null : ContextTiles.fromJson(site['base'] as Map<String, dynamic>),
    );
  }

  /// Carpeta de assets de este sitio, dentro de `assets/`.
  final String assetDir;

  /// Minerales, zonas, cráteres, nombres y geología (vacío si el sitio no los trae).
  final SiteVectors vectors;

  /// Marco de contexto alrededor de la ventana, o null.
  final ContextTiles? context;

  /// Mapa base de toda la región (40 m por píxel), compartido entre sitios, o null.
  final ContextTiles? base;

  /// Ruta de un archivo del sitio, por ejemplo `assetPath('layers/slope.png')`.
  String assetPath(String rel) => 'assets/$assetDir/$rel';

  /// Ids de las capas que el sitio declara en `site.json`; vacío si no declara ninguna.
  List<String> get layerIds => [for (final l in (site['layers'] as List? ?? const [])) (l as Map<String, dynamic>)['id'] as String];

  final Map<String, dynamic> site;
  final Map<String, dynamic> params;
  final RouteGrid grid;
  final RoutingModel model;
  final List<Objective> objectives;
  final List<CuriosityPoint> curiosity;
  final double sizeM;
  final double habitatX;
  final double habitatY;
  final double originE;
  final double originN;
  final double radiusM;

  /// Metros por píxel de cada nivel de teselas.
  final List<double> tileMPerPx;
  final int tileCount;

  /// Radiación y clima reales de Curiosity, por sol.
  final EnvironmentData environment;

  /// Umbrales de GO / NO-GO.
  final EnvConfig envConfig;

  /// Fotos reales de Curiosity por id de objetivo de demostración.
  final Map<String, RoverPhoto> roverPhotos;

  /// Fotos reales de la zona (Opportunity en Endeavour); vacío en los sitios que no las traen.
  final List<ZonePhoto> zonePhotos;

  /// Tamaño del lado de una tesela en metros.
  double tileSizeM(int z) => 512 * tileMPerPx[z];

  /// Longitud y latitud (grados planetocéntricos, este positivo) de un punto local.
  (double, double) lonLat(double x, double y) =>
      ((originE + x) / radiusM * 180 / math.pi, (originN - y) / radiusM * 180 / math.pi);

  bool _inside(double x, double y) => x >= 0 && y >= 0 && x < sizeM && y < sizeM;

  double? elevationAt(double x, double y) => _inside(x, y) ? grid.z[grid.cellOf(x, y)] : null;

  double? slopeAt(double x, double y) => _inside(x, y) ? grid.slopeReal[grid.cellOf(x, y)] : null;

  bool isBlocked(double x, double y) => !_inside(x, y) || grid.blocked[grid.cellOf(x, y)] != 0;
}
