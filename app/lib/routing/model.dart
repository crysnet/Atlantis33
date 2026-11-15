import 'dart:math' as math;

/// Pesos de un perfil de ruta. Mismo algoritmo, pesos distintos.
class Profile {
  const Profile({
    required this.wSlope,
    required this.wRough,
    required this.wSand,
    required this.wTime,
    required this.slopeLimitDeg,
    this.roughMaxCm = double.infinity,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        wSlope: (j['w_slope'] as num).toDouble(),
        wRough: (j['w_rough'] as num).toDouble(),
        wSand: (j['w_sand'] as num).toDouble(),
        wTime: (j['w_time'] as num).toDouble(),
        slopeLimitDeg: (j['slope_limit_deg'] as num).toDouble(),
      );

  final double wSlope;
  final double wRough;
  final double wSand;
  final double wTime;
  final double slopeLimitDeg;

  /// Rugosidad máxima en cm; solo el perfil del vehículo la limita.
  final double roughMaxCm;

  /// El mismo perfil para el vehículo: pendiente y rugosidad limitadas a las del rover.
  Profile forVehicle(RoverParams r) => Profile(
        wSlope: wSlope,
        wRough: wRough,
        wSand: wSand,
        wTime: wTime,
        slopeLimitDeg: math.min(slopeLimitDeg, r.slopeLimitDeg),
        roughMaxCm: r.roughMaxCm,
      );
}

/// Supuestos del modo con rover (`rover` en `params.json`). Referencias de la NASA y supuestos en `RECURSOS.md`.
class RoverParams {
  const RoverParams({required this.speedMPerH, required this.slopeLimitDeg, required this.roughMaxCm, required this.o2Rate, required this.transferH, required this.dispatchH});

  factory RoverParams.fromJson(Map<String, dynamic> j) => RoverParams(
        speedMPerH: (j['speed_kmh'] as num).toDouble() * 1000.0,
        slopeLimitDeg: (j['slope_limit_deg'] as num).toDouble(),
        roughMaxCm: (j['rough_max_cm'] as num).toDouble(),
        o2Rate: (j['o2_rate'] as num).toDouble(),
        transferH: (j['transfer_min'] as num).toDouble() / 60.0,
        dispatchH: (j['support_dispatch_min'] as num).toDouble() / 60.0,
      );

  final double speedMPerH;
  final double slopeLimitDeg;
  final double roughMaxCm;

  /// Gasto de oxígeno sobre el rover, como fracción del ritmo nominal.
  final double o2Rate;

  /// Horas que cuesta subir o bajar del rover.
  final double transferH;

  /// Horas entre el aviso de una emergencia y la salida del rover de apoyo.
  final double dispatchH;
  double get speedKmh => speedMPerH / 1000.0;
}

/// Parámetros del modelo, leídos de `params.json` (copia de `config/params.json`).
///
/// Todos los valores son supuestos del equipo, no estándares de la NASA.
/// Referencia: `tools/routing.py`, clase `Modelo`. Los dos deben dar el mismo resultado.
class RoutingModel {
  RoutingModel({
    required this.cellM,
    required this.slopeRefDeg,
    required this.roughRefCm,
    required this.profiles,
    required this.flatSpeedMPerH,
    required this.toblerK,
    required this.minSpeedFactor,
    required this.maxEvaH,
    required this.o2CapacityH,
    required this.o2Reserve,
    required this.o2Uphill,
    required this.o2StopRate,
    required this.doseUGyPerDay,
    required this.slopeNominalMax,
    required this.slopeCautionMax,
    required this.hazard,
    required this.success,
    required this.scienceKeepComfort,
    required this.safeFastByProfile,
    required this.rover,
    required this.pairMaxSeparationM,
    required this.pairSampleH,
  }) : maxSpeedFactor = math.exp(toblerK * 0.05);

  factory RoutingModel.fromParams(Map<String, dynamic> p, {double? cellM}) {
    final r = p['routing'] as Map<String, dynamic>;
    final m = p['mobility'] as Map<String, dynamic>;
    final c = p['consumables'] as Map<String, dynamic>;
    final s = p['slope'] as Map<String, dynamic>;
    return RoutingModel(
      cellM: cellM ?? (r['cell_m'] as num).toDouble(),
      slopeRefDeg: (r['slope_exponent_ref_deg'] as num).toDouble(),
      roughRefCm: (r['roughness_ref_cm'] as num).toDouble(),
      profiles: {
        for (final e in (r['profiles'] as Map<String, dynamic>).entries)
          e.key: Profile.fromJson(e.value as Map<String, dynamic>),
      },
      flatSpeedMPerH: (m['flat_speed_kmh'] as num).toDouble() * 1000.0,
      toblerK: (m['tobler_k'] as num).toDouble(),
      minSpeedFactor: (m['min_speed_factor'] as num).toDouble(),
      maxEvaH: (m['max_eva_h'] as num).toDouble(),
      o2CapacityH: (c['o2_capacity_h'] as num).toDouble(),
      o2Reserve: (c['o2_reserve_min_frac'] as num).toDouble(),
      o2Uphill: (c['o2_uphill_factor'] as num).toDouble(),
      o2StopRate: (c['o2_stop_rate'] as num).toDouble(),
      doseUGyPerDay: ((p['radiation'] as Map<String, dynamic>)['dose_rate_ugy_per_day'] as num).toDouble(),
      slopeNominalMax: (s['nominal_max_deg'] as num).toDouble(),
      slopeCautionMax: (s['caution_max_deg'] as num).toDouble(),
      hazard: p['hazard'] as Map<String, dynamic>,
      success: p['success'] as Map<String, dynamic>,
      scienceKeepComfort: (r['science_keep_comfort'] as bool?) ?? false,
      safeFastByProfile: r['safe_fast_targets'] == 'by_profile',
      rover: RoverParams.fromJson(p['rover'] as Map<String, dynamic>),
      pairMaxSeparationM: ((p['pair'] as Map<String, dynamic>)['max_separation_m'] as num).toDouble(),
      pairSampleH: ((p['pair'] as Map<String, dynamic>)['sample_min'] as num).toDouble() / 60.0,
    );
  }

  final double cellM;
  final double slopeRefDeg;
  final double roughRefCm;
  final Map<String, Profile> profiles;
  final double flatSpeedMPerH;
  final double toblerK;
  final double minSpeedFactor;
  final double maxEvaH;
  final double o2CapacityH;
  final double o2Reserve;
  final double o2Uphill;
  final double o2StopRate;
  final double doseUGyPerDay;
  final double slopeNominalMax;
  final double slopeCautionMax;
  final Map<String, dynamic> hazard;
  final Map<String, dynamic> success;
  final bool scienceKeepComfort;

  /// `safe_fast_targets: by_profile`: la ruta segura y la rápida eligen cada una su objetivo (en vez del de mayor prioridad).
  final bool safeFastByProfile;

  /// Supuestos del modo con rover.
  final RoverParams rover;

  /// Modo en pareja: separación máxima entre los dos astronautas y cada cuánto se comprueba (horas).
  final double pairMaxSeparationM;
  final double pairSampleH;

  /// Velocidad máxima relativa: la de una bajada leve (tan = -0.05).
  final double maxSpeedFactor;

  /// Factor de velocidad según la pendiente en el sentido del paso (función de Tobler, escalada).
  double speedFactor(double tan) {
    final g = math.exp(-toblerK * ((tan + 0.05).abs() - 0.05));
    return g > minSpeedFactor ? g : minSpeedFactor;
  }
}
