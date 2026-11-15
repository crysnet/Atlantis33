import 'package:flutter/material.dart';

/// Formato de números según el idioma: coma decimal en español, punto en inglés.
class Fmt {
  const Fmt(this.locale);

  final Locale locale;

  bool get _es => locale.languageCode == 'es';

  String num(double v, [int digits = 1]) {
    final s = v.toStringAsFixed(digits);
    return _es ? s.replaceAll('.', ',') : s;
  }

  /// Texto fijo con decimales (p. ej. `HiRISE 0.25 m`): en español cambia el punto decimal por coma.
  String text(String s) => _es ? s.replaceAllMapped(RegExp(r'(\d)\.(\d)'), (m) => '${m[1]},${m[2]}') : s;

  /// Hora del día `HH:MM` a partir de horas decimales (da la vuelta a las 24 h).
  String clock(double h) {
    final total = (h * 60).round() % 1440;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(total ~/ 60)}:${two(total % 60)}';
  }

  String km(double meters, [int digits = 1]) => '${num(meters / 1000, digits)} km';

  String meters(double m) => '${num(m, 0)} m';

  /// Horas decimales como `3h 24m`.
  String hours(double h) {
    final total = (h * 60).round();
    return '${total ~/ 60}h ${(total % 60).toString().padLeft(2, '0')}m';
  }

  String percent(double frac, [int digits = 0]) => '${num(frac * 100, digits)}%';

  /// Oxígeno restante: nunca un porcentaje bajo 0; si no alcanza, el texto [depleted] (p. ej. «agotado»).
  String o2(double frac, String depleted) => frac < 0 ? depleted : percent(frac);

  /// Fecha y hora cortas, p. ej. `2026-11-14 16:21`.
  String dateTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  /// Latitud y longitud con hemisferio, p. ej. `4.8047° S, 137.3823° E`.
  String latLon(double lon, double lat) =>
      '${num(lat.abs(), 4)}° ${lat < 0 ? 'S' : 'N'}, ${num(lon.abs(), 4)}° ${lon < 0 ? 'W' : 'E'}';
}
