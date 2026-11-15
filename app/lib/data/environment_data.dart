enum CheckLevel { go, caution, noGo, pending }

class EnvConfig {
  const EnvConfig({
    this.evaStartLmstH = 9.0,
    this.radCautionRatio = 1.5,
    this.radNoGoRatio = 3.0,
    this.airCautionC = -60.0,
    this.airNoGoC = -80.0,
  });

  final double evaStartLmstH;
  final double radCautionRatio;
  final double radNoGoRatio;
  final double airCautionC;
  final double airNoGoC;

  factory EnvConfig.fromParams(Map<String, dynamic> params) {
    final env = params['environment'] as Map<String, dynamic>? ?? const {};
    final rad = env['radiation'] as Map<String, dynamic>? ?? const {};
    final weather = env['weather'] as Map<String, dynamic>? ?? const {};
    return EnvConfig(
      evaStartLmstH: (env['eva_start_lmst_h'] as num? ?? 9.0).toDouble(),
      radCautionRatio: (rad['caution_ratio'] as num? ?? 1.5).toDouble(),
      radNoGoRatio: (rad['nogo_ratio'] as num? ?? 3.0).toDouble(),
      airCautionC: (weather['caution_min_air_c'] as num? ?? -60.0).toDouble(),
      airNoGoC: (weather['nogo_min_air_c'] as num? ?? -80.0).toDouble(),
    );
  }
}

class RadSol {
  const RadSol({
    required this.sol,
    required this.utcStart,
    required this.n,
    required this.eMean,
    required this.eMax,
    required this.bRtgMean,
  });

  final int sol;
  final String utcStart;
  final int n;
  final double eMean;
  final double eMax;
  final double bRtgMean;

  factory RadSol.fromJson(Map<String, dynamic> j) => RadSol(
        sol: (j['sol'] as num).toInt(),
        utcStart: j['utc_start'] as String? ?? '',
        n: (j['n'] as num? ?? 0).toInt(),
        eMean: (j['dose_e_mean_ugy_day'] as num).toDouble(),
        eMax: (j['dose_e_max_ugy_day'] as num).toDouble(),
        bRtgMean: (j['dose_b_rtg_mean_ugy_day'] as num).toDouble(),
      );
}

class HourPoint {
  const HourPoint({
    required this.hour,
    this.airC,
    this.groundC,
    this.pressurePa,
    this.uvWm2,
    this.humidityPct,
    this.samples = 0,
  });

  final int hour;
  final double? airC;
  final double? groundC;
  final double? pressurePa;
  final double? uvWm2;
  final double? humidityPct;
  final int samples;

  factory HourPoint.fromJson(Map<String, dynamic> j) => HourPoint(
        hour: (j['lmst_hour'] as num).toInt(),
        airC: (j['air_c'] as num?)?.toDouble(),
        groundC: (j['ground_c'] as num?)?.toDouble(),
        pressurePa: (j['pressure_pa'] as num?)?.toDouble(),
        uvWm2: (j['uv_abc_wm2'] as num?)?.toDouble(),
        humidityPct: (j['humidity_pct'] as num?)?.toDouble(),
        samples: (j['samples'] as num? ?? 0).toInt(),
      );
}

class WeatherSol {
  const WeatherSol({
    required this.sol,
    required this.utcStart,
    required this.utcStop,
    required this.hoursWithAir,
    this.airMinC,
    this.airMaxC,
    this.groundMinC,
    this.groundMaxC,
    this.pressureMinPa,
    this.pressureMaxPa,
    this.uvPeak,
    this.humidityMaxPct,
    this.hourly = const [],
  });

  final int sol;
  final String utcStart;
  final String utcStop;
  final int hoursWithAir;
  final double? airMinC;
  final double? airMaxC;
  final double? groundMinC;
  final double? groundMaxC;
  final double? pressureMinPa;
  final double? pressureMaxPa;
  final double? uvPeak;
  final double? humidityMaxPct;
  final List<HourPoint> hourly;

  factory WeatherSol.fromJson(Map<String, dynamic> j) {
    final hourly = [
      for (final h in (j['hourly'] as List? ?? const []))
        HourPoint.fromJson(h as Map<String, dynamic>),
    ];
    double? humMax = (j['humidity_max_pct'] as num?)?.toDouble();
    if (humMax == null) {
      for (final h in hourly) {
        if (h.humidityPct != null && (humMax == null || h.humidityPct! > humMax)) {
          humMax = h.humidityPct;
        }
      }
    }
    return WeatherSol(
      sol: (j['sol'] as num).toInt(),
      utcStart: j['utc_start'] as String? ?? '',
      utcStop: j['utc_stop'] as String? ?? '',
      hoursWithAir: (j['hours_with_air'] as num? ?? 0).toInt(),
      airMinC: (j['air_min_c'] as num?)?.toDouble(),
      airMaxC: (j['air_max_c'] as num?)?.toDouble(),
      groundMinC: (j['ground_min_c'] as num?)?.toDouble(),
      groundMaxC: (j['ground_max_c'] as num?)?.toDouble(),
      pressureMinPa: (j['pressure_min_pa'] as num?)?.toDouble(),
      pressureMaxPa: (j['pressure_max_pa'] as num?)?.toDouble(),
      uvPeak: (j['uv_abc_peak_wm2'] as num?)?.toDouble(),
      humidityMaxPct: humMax,
      hourly: hourly,
    );
  }
}

class WeatherCheck {
  const WeatherCheck({
    required this.level,
    required this.hoursInWindow,
    this.minAirC,
  });

  final CheckLevel level;
  final int hoursInWindow;
  final double? minAirC;
}

class EnvironmentData {
  const EnvironmentData({
    required this.referenceSol,
    this.baselineE,
    this.rad = const [],
    this.weather = const [],
  });

  static const EnvironmentData empty = EnvironmentData(referenceSol: 0);

  final int referenceSol;
  final double? baselineE;
  final List<RadSol> rad;
  final List<WeatherSol> weather;

  int get firstWeatherSol => weather.isEmpty ? referenceSol : weather.first.sol;

  RadSol? radFor(int sol) {
    for (final r in rad) {
      if (r.sol == sol) return r;
    }
    return null;
  }

  WeatherSol? weatherFor(int sol) {
    for (final w in weather) {
      if (w.sol == sol) return w;
    }
    return null;
  }

  double? radiationRatio(int sol) {
    final r = radFor(sol);
    if (r == null || baselineE == null || baselineE! <= 0) return null;
    return r.eMean / baselineE!;
  }

  CheckLevel radiationLevel(int sol, EnvConfig cfg) {
    final ratio = radiationRatio(sol);
    if (ratio == null) return CheckLevel.pending;
    if (ratio >= cfg.radNoGoRatio) return CheckLevel.noGo;
    if (ratio >= cfg.radCautionRatio) return CheckLevel.caution;
    return CheckLevel.go;
  }

  WeatherCheck weatherCheck(int sol, EnvConfig cfg, double windowLmstH) {
    final w = weatherFor(sol);
    if (w == null || windowLmstH <= 0) {
      return const WeatherCheck(level: CheckLevel.pending, hoursInWindow: 0);
    }
    final startH = cfg.evaStartLmstH.floor();
    final endH = (cfg.evaStartLmstH + windowLmstH).ceil();
    final span = (endH - startH).clamp(1, 24);
    final validHours = <int>{
      for (var i = 0; i < span; i++) (startH + i) % 24,
    };

    var count = 0;
    double? minAir;
    for (final h in w.hourly) {
      if (validHours.contains(h.hour) && h.airC != null) {
        count++;
        if (minAir == null || h.airC! < minAir) {
          minAir = h.airC;
        }
      }
    }

    if (minAir == null) {
      return WeatherCheck(level: CheckLevel.pending, hoursInWindow: count);
    }
    final CheckLevel lvl;
    if (minAir <= cfg.airNoGoC) {
      lvl = CheckLevel.noGo;
    } else if (minAir <= cfg.airCautionC) {
      lvl = CheckLevel.caution;
    } else {
      lvl = CheckLevel.go;
    }
    return WeatherCheck(level: lvl, hoursInWindow: count, minAirC: minAir);
  }

  factory EnvironmentData.fromJson(Map<String, dynamic> j) {
    final refSol = (j['reference_sol'] as num? ?? 0).toInt();
    final radMap = j['radiation'] as Map<String, dynamic>?;
    final weatherMap = j['weather'] as Map<String, dynamic>?;

    final baselineE = (radMap?['baseline_e_median_ugy_day'] as num?)?.toDouble();
    final radList = [
      for (final r in (radMap?['per_sol'] as List? ?? const []))
        RadSol.fromJson(r as Map<String, dynamic>),
    ];
    final weatherList = [
      for (final w in (weatherMap?['sols'] as List? ?? const []))
        WeatherSol.fromJson(w as Map<String, dynamic>),
    ];

    return EnvironmentData(
      referenceSol: refSol,
      baselineE: baselineE,
      rad: radList,
      weather: weatherList,
    );
  }
}
