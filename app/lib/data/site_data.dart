import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../routing/routing.dart';
import 'environment_data.dart';
import 'vectors.dart';

export 'environment_data.dart';
export 'vectors.dart';

class CuriosityPoint {
  const CuriosityPoint({
    required this.sol,
    required this.x,
    required this.y,
    required this.elevM,
    required this.campaign,
  });

  final int sol;
  final double x;
  final double y;
  final double elevM;
  final bool campaign;

  factory CuriosityPoint.fromJson(Map<String, dynamic> j) => CuriosityPoint(
        sol: (j['sol'] as num).toInt(),
        x: (j['x_m'] as num).toDouble(),
        y: (j['y_m'] as num).toDouble(),
        elevM: (j['elev_m'] as num? ?? 0).toDouble(),
        campaign: j['boxwork_campaign'] as bool? ?? false,
      );
}

class RoverPhoto {
  const RoverPhoto({
    required this.sol,
    required this.camera,
    required this.dateTaken,
    required this.credit,
    required this.file,
    required this.asset,
  });

  final int sol;
  final String camera;
  final String dateTaken;
  final String credit;
  final String file;
  final String asset;

  factory RoverPhoto.fromJson(Map<String, dynamic> j, String assetDir) {
    final file = j['file'] as String? ?? '';
    return RoverPhoto(
      sol: (j['sol'] as num? ?? 0).toInt(),
      camera: j['camera'] as String? ?? '',
      dateTaken: j['date_taken'] as String? ?? '',
      credit: j['credit'] as String? ?? '',
      file: file,
      asset: 'assets/$assetDir/rover/$file',
    );
  }
}

class ContextTiles {
  const ContextTiles({
    this.assetDir,
    required this.x,
    required this.y,
    required this.sizeM,
    required this.tilePx,
    required this.maxZoom,
    required this.worldSizeM,
    required this.tileMPerPx,
  });

  final String? assetDir;
  final double x;
  final double y;
  final double sizeM;
  final int tilePx;
  final int maxZoom;
  final double worldSizeM;
  final List<double> tileMPerPx;

  double tileSizeM(int z) => worldSizeM / (1 << z);

  factory ContextTiles.fromJson(Map<String, dynamic> j) => ContextTiles(
        assetDir: j['asset_dir'] as String?,
        x: (j['x_m'] as num).toDouble(),
        y: (j['y_m'] as num).toDouble(),
        sizeM: (j['size_m'] as num).toDouble(),
        tilePx: (j['tile_px'] as num? ?? 512).toInt(),
        maxZoom: (j['max_zoom'] as num? ?? 0).toInt(),
        worldSizeM: (j['world_size_m'] as num).toDouble(),
        tileMPerPx: [
          for (final v in (j['m_per_px'] as List? ?? const []))
            (v as num).toDouble(),
        ],
      );
}

class SiteData {
  const SiteData({
    required this.assetDir,
    required this.site,
    required this.params,
    required this.grid,
    required this.model,
    required this.objectives,
    required this.curiosity,
    required this.roverPhotos,
    required this.environment,
    required this.envConfig,
    required this.vectors,
    this.context,
    this.base,
  });

  final String assetDir;
  final Map<String, dynamic> site;
  final Map<String, dynamic> params;
  final RouteGrid grid;
  final RoutingModel model;
  final List<Objective> objectives;
  final List<CuriosityPoint> curiosity;
  final Map<String, RoverPhoto> roverPhotos;
  final EnvironmentData environment;
  final EnvConfig envConfig;
  final SiteVectors vectors;
  final ContextTiles? context;
  final ContextTiles? base;

  String assetPath(String rel) => 'assets/$assetDir/$rel';

  String tileAssetPath(int z, int tx, int ty) {
    final tiles = site['tiles'] as Map<String, dynamic>;
    final dir = tiles['asset_dir'] as String?;
    return dir != null
        ? 'assets/$dir/$z/$tx/$ty.jpg'
        : assetPath('ortho/$z/$tx/$ty.jpg');
  }

  double get sizeM =>
      ((site['frame'] as Map<String, dynamic>)['size_m'] as num).toDouble();

  Rect? get validBounds {
    final b = (site['frame'] as Map<String, dynamic>)['bounds_m'] as List?;
    if (b == null || b.length != 4) return null;
    return Rect.fromLTRB(
      (b[0] as num).toDouble(),
      (b[1] as num).toDouble(),
      (b[2] as num).toDouble(),
      (b[3] as num).toDouble(),
    );
  }

  double get habitatX =>
      ((site['habitat'] as Map<String, dynamic>)['x_m'] as num).toDouble();

  double get habitatY =>
      ((site['habitat'] as Map<String, dynamic>)['y_m'] as num).toDouble();

  List<double> get tileMPerPx => [
        for (final v
            in ((site['tiles'] as Map<String, dynamic>)['m_per_px'] as List))
          (v as num).toDouble(),
      ];

  int get tileCount => tileMPerPx.length;

  double tileSizeM(int z) {
    final tiles = site['tiles'] as Map<String, dynamic>;
    final worldSizeM = (tiles['world_size_m'] as num).toDouble();
    return worldSizeM / (1 << z);
  }

  (double, double) lonLat(double xM, double yM) {
    final geo = site['georeference'] as Map<String, dynamic>;
    final x0 = (geo['origin_easting_m'] as num).toDouble();
    final y0 = (geo['origin_northing_m'] as num).toDouble();
    final r = (geo['radius_m'] as num).toDouble();
    final easting = x0 + xM;
    final northing = y0 - yM;
    final lon = (easting / r) * (180.0 / math.pi);
    final lat = (northing / r) * (180.0 / math.pi);
    return (lon, lat);
  }

  bool _inBounds(double xM, double yM) =>
      xM >= 0 && yM >= 0 && xM <= sizeM && yM <= sizeM;

  bool isBlocked(double xM, double yM) {
    if (!_inBounds(xM, yM)) return true;
    return grid.blocked[grid.cellOf(xM, yM)] != 0;
  }

  double? elevationAt(double xM, double yM) {
    if (!_inBounds(xM, yM)) return null;
    final v = grid.z[grid.cellOf(xM, yM)];
    return v.isNaN ? null : v;
  }

  double? slopeAt(double xM, double yM) {
    if (!_inBounds(xM, yM)) return null;
    final v = grid.slopeReal[grid.cellOf(xM, yM)];
    return v.isNaN ? null : v;
  }

  static Future<String?> _tryLoadString(String key) async {
    try {
      return await rootBundle.loadString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _loadBytes(String key) async {
    final bd = await rootBundle.load(key);
    return bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
  }

  static Future<SiteData> load([String assetDir = 'site_gale']) async {
    String path(String rel) => 'assets/$assetDir/$rel';

    final siteRaw = await rootBundle.loadString(path('site.json'));
    final paramsRaw = await rootBundle.loadString(path('params.json'));
    final objRaw = await rootBundle.loadString(path('objectives.json'));

    final site = jsonDecode(siteRaw) as Map<String, dynamic>;
    final params = jsonDecode(paramsRaw) as Map<String, dynamic>;
    final objJson = jsonDecode(objRaw) as Map<String, dynamic>;

    final model = RoutingModel.fromParams(params);
    final envConfig = EnvConfig.fromParams(params);

    final g = site['grid'] as Map<String, dynamic>;
    final h = site['habitat'] as Map<String, dynamic>;

    final results = await Future.wait([
      _loadBytes(path('grid/slope.bin')),
      _loadBytes(path('grid/rough.bin')),
      _loadBytes(path('grid/forbidden.bin')),
      _loadBytes(path('grid/elev.bin')),
    ]);

    final grid = RouteGrid.fromBytes(
      slopeBytes: results[0],
      roughBytes: results[1],
      forbiddenBytes: results[2],
      elevBytes: results[3],
      components: g['components'] as Map<String, dynamic>,
      baseWidth: (g['width'] as num).toInt(),
      baseHeight: (g['height'] as num).toInt(),
      baseCellM: (g['cell_m'] as num).toDouble(),
      habitatRow: (h['row'] as num).toInt(),
      habitatCol: (h['col'] as num).toInt(),
      cellM: model.cellM,
    );

    final objectives = [
      for (final o in (objJson['objectives'] as List? ?? const []))
        Objective.fromJson(o as Map<String, dynamic>),
    ];

    final curRaw = await _tryLoadString(path('curiosity_waypoints.json'));
    final curiosity = <CuriosityPoint>[
      if (curRaw != null)
        for (final p
            in ((jsonDecode(curRaw) as Map<String, dynamic>)['points']
                    as List? ??
                const []))
          CuriosityPoint.fromJson(p as Map<String, dynamic>),
    ];

    final roverRaw = await _tryLoadString(path('rover_photos.json'));
    final roverPhotos = <String, RoverPhoto>{};
    if (roverRaw != null) {
      final rMap = jsonDecode(roverRaw) as Map<String, dynamic>;
      for (final entry in rMap.entries) {
        if (entry.value is Map<String, dynamic>) {
          roverPhotos[entry.key] = RoverPhoto.fromJson(
            entry.value as Map<String, dynamic>,
            assetDir,
          );
        }
      }
    }

    final envRaw = await _tryLoadString(path('environment.json'));
    final environment = envRaw != null
        ? EnvironmentData.fromJson(jsonDecode(envRaw) as Map<String, dynamic>)
        : EnvironmentData.empty;

    final vecRaw = await _tryLoadString(path('vectors.json'));
    final vectors = vecRaw != null
        ? SiteVectors.fromJson(jsonDecode(vecRaw) as Map<String, dynamic>)
        : SiteVectors.empty;

    final ctxMap = site['context'] as Map<String, dynamic>?;
    final baseMap = site['base'] as Map<String, dynamic>?;

    return SiteData(
      assetDir: assetDir,
      site: site,
      params: params,
      grid: grid,
      model: model,
      objectives: objectives,
      curiosity: curiosity,
      roverPhotos: roverPhotos,
      environment: environment,
      envConfig: envConfig,
      vectors: vectors,
      context: ctxMap != null ? ContextTiles.fromJson(ctxMap) : null,
      base: baseMap != null ? ContextTiles.fromJson(baseMap) : null,
    );
  }
}
