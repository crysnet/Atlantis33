/// Datos reales de radiación (RAD) y clima (REMS) de Curiosity, por sol.
///
/// Los genera `tools/06_clima_radiacion.py` a partir de archivos de la NASA y quedan en `environment.json`.
/// Referencia de las columnas: PDS MSL-M-REMS-5-MODRDR-V1.0 y CDAWeb MSL_RAD_OBS-L2.
library;

/// Resultado de una verificación de salida.
enum CheckLevel { go, caution, noGo, pending }

class HourPoint {
  const HourPoint({required this.hour, this.airC, this.groundC, this.pressurePa, this.uvAbc, this.humidityPct, required this.samples});

  factory HourPoint.fromJson(Map<String, dynamic> j) => HourPoint(
        hour: (j['lmst_hour'] as num).toInt(),
        airC: (j['air_c'] as num?)?.toDouble(),
        groundC: (j['ground_c'] as num?)?.toDouble(),
        pressurePa: (j['pressure_pa'] as num?)?.toDouble(),
        uvAbc: (j['uv_abc_wm2'] as num?)?.toDouble(),
        humidityPct: (j['humidity_pct'] as num?)?.toDouble(),
        samples: (j['samples'] as num).toInt(),
      );

  /// Hora de tiempo solar medio local (LMST), de 0 a 23.
  final int hour;
  final double? airC;
  final double? groundC;
  final double? pressurePa;
  final double? uvAbc;
  final double? humidityPct;
  final int samples;
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
    required this.hourly,
  });

  factory WeatherSol.fromJson(Map<String, dynamic> j) => WeatherSol(
        sol: (j['sol'] as num).toInt(),
        utcStart: j['utc_start'] as String,
        utcStop: j['utc_stop'] as String,
        hoursWithAir: (j['hours_with_air_data'] as num).toInt(),
        airMinC: (j['air_min_c'] as num?)?.toDouble(),
        airMaxC: (j['air_max_c'] as num?)?.toDouble(),
        groundMinC: (j['ground_min_c'] as num?)?.toDouble(),
        groundMaxC: (j['ground_max_c'] as num?)?.toDouble(),
        pressureMinPa: (j['pressure_min_pa'] as num?)?.toDouble(),
        pressureMaxPa: (j['pressure_max_pa'] as num?)?.toDouble(),
        uvPeak: (j['uv_abc_peak_wm2'] as num?)?.toDouble(),
        hourly: [for (final h in j['hourly'] as List) HourPoint.fromJson(h as Map<String, dynamic>)],
      );

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
  final List<HourPoint> hourly;

  /// Humedad relativa máxima de las horas con dato, o null si no hay.
  double? get humidityMaxPct {
    double? m;
    for (final h in hourly) {
      if (h.humidityPct != null && (m == null || h.humidityPct! > m)) m = h.humidityPct;
    }
    return m;
  }
}

class RadSol {
  const RadSol({required this.sol, required this.utcStart, required this.n, required this.eMean, required this.eMax, required this.bRtgMean});

  factory RadSol.fromJson(Map<String, dynamic> j) => RadSol(
        sol: (j['sol'] as num).toInt(),
        utcStart: j['utc_start'] as String,
        n: (j['n'] as num).toInt(),
        eMean: (j['dose_e_mean_ugy_day'] as num).toDouble(),
        eMax: (j['dose_e_max_ugy_day'] as num).toDouble(),
        bRtgMean: (j['dose_b_rtg_mean_ugy_day'] as num).toDouble(),
      );

  final int sol;
  final String utcStart;

  /// Cantidad de mediciones del sol.
  final int n;

  /// Dosis absorbida media del detector E (plástico equivalente a tejido), en uGy por día.
  final double eMean;
  final double eMax;
  final double bRtgMean;
}

/// Umbrales de GO / NO-GO. Son supuestos del equipo (`params.json`, sección `environment`).
class EnvConfig {
  const EnvConfig({
    required this.evaStartLmstH,
    required this.radCautionRatio,
    required this.radNoGoRatio,
    required this.airCautionC,
    required this.airNoGoC,
  });

  factory EnvConfig.fromParams(Map<String, dynamic> p) {
    final e = p['environment'] as Map<String, dynamic>;
    final r = e['radiation'] as Map<String, dynamic>;
    final w = e['weather'] as Map<String, dynamic>;
    return EnvConfig(
      evaStartLmstH: (e['eva_start_lmst_h'] as num).toDouble(),
      radCautionRatio: (r['caution_ratio'] as num).toDouble(),
      radNoGoRatio: (r['nogo_ratio'] as num).toDouble(),
      airCautionC: (w['caution_min_air_c'] as num).toDouble(),
      airNoGoC: (w['nogo_min_air_c'] as num).toDouble(),
    );
  }

  final double evaStartLmstH;
  final double radCautionRatio;
  final double radNoGoRatio;
  final double airCautionC;
  final double airNoGoC;
}

/// Resultado de la verificación de clima para una salida.
class WeatherCheck {
  const WeatherCheck({required this.level, this.minAirC, required this.hoursInWindow});

  final CheckLevel level;
  final double? minAirC;
  final int hoursInWindow;
}

class EnvironmentData {
  const EnvironmentData({
    required this.referenceSol,
    required this.baselineE,
    required this.rad,
    required this.weather,
    required this.radSource,
    required this.weatherSource,
  });

  factory EnvironmentData.fromJson(Map<String, dynamic> j) {
    final rad = j['radiation'] as Map<String, dynamic>;
    final wx = j['weather'] as Map<String, dynamic>;
    return EnvironmentData(
      referenceSol: (j['reference_sol'] as num).toInt(),
      baselineE: (rad['baseline_e_median_ugy_day'] as num?)?.toDouble(),
      rad: [for (final r in rad['per_sol'] as List) RadSol.fromJson(r as Map<String, dynamic>)],
      weather: [for (final w in wx['sols'] as List) WeatherSol.fromJson(w as Map<String, dynamic>)],
      radSource: rad['source'] as String,
      weatherSource: wx['source'] as String,
    );
  }

  /// Último sol con datos de REMS publicados en el PDS.
  final int referenceSol;

  /// Mediana de las dosis diarias del detector E en los 60 sols previos al periodo de REMS.
  final double? baselineE;
  final List<RadSol> rad;
  final List<WeatherSol> weather;
  final String radSource;
  final String weatherSource;

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

  int get firstWeatherSol => weather.isEmpty ? referenceSol : weather.first.sol;

  /// Cociente entre la dosis del sol y la línea base.
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

  /// Verifica la temperatura del aire en la ventana de la salida: empieza a `evaStartLmstH` y dura [windowLmstHours].
  WeatherCheck weatherCheck(int sol, EnvConfig cfg, double windowLmstHours) {
    final w = weatherFor(sol);
    if (w == null) return const WeatherCheck(level: CheckLevel.pending, hoursInWindow: 0);
    final start = cfg.evaStartLmstH;
    final end = start + windowLmstHours;
    double? minAir;
    var hours = 0;
    for (final h in w.hourly) {
      // La hora h cubre de h a h + 1.
      if (h.hour + 1 > start && h.hour < end && h.airC != null) {
        hours++;
        if (minAir == null || h.airC! < minAir) minAir = h.airC;
      }
    }
    if (minAir == null) return WeatherCheck(level: CheckLevel.pending, hoursInWindow: hours);
    final level = minAir <= cfg.airNoGoC ? CheckLevel.noGo : (minAir <= cfg.airCautionC ? CheckLevel.caution : CheckLevel.go);
    return WeatherCheck(level: level, minAirC: minAir, hoursInWindow: hours);
  }
}
