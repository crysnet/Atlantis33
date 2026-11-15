import 'package:flutter/material.dart';

/// Colores del prototipo de Stitch: fondo carbón cálido, naranja óxido de acento, cian para ciencia;
/// verde, ámbar y rojo solo para estado.
class AppColors {
  static const bg = Color(0xFF0E0C0B);
  static const panel = Color(0xFF151210);
  static const panel2 = Color(0xFF1A1614);
  static const panel3 = Color(0xFF231F1C);
  static const hairline = Color(0xFF2A2521);
  static const orange = Color(0xFFE2622B);
  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF2ECC71);
  static const amber = Color(0xFFF39C12);
  static const red = Color(0xFFE74C3C);
  static const text = Color(0xFFECE7E1);
  static const textDim = Color(0xFFA78B81);
  static const textMute = Color(0xFF6F625B);

  // Clases de pendiente: los mismos colores de `config/params.json`, para que la leyenda coincida con la capa.
  static const slopeNominal = Color(0xFF3DAA5C);
  static const slopeCaution = Color(0xFFE6AA28);
  static const slopeHigh = Color(0xFFE6702A);
  static const slopeForbidden = Color(0xFFD23232);

  // Color de cada ruta en el mapa.
  static const routeSafe = Color(0xFFECE7E1);
  static const routeFast = orange;
  static const routeScience = cyan;
}

/// Minerales desde órbita que se dibujan, con su color (mapa y leyenda). La capa de acuosos muestra solo los de más
/// probabilidad de biofirmas (filosilicatos y carbonatos); los sulfatos están en los datos pero no se dibujan.
const Map<String, Color> kMineralColors = {
  'phyllosilicate': Color(0xFFD63DA8),
  'carbonate': Color(0xFF5DBB63),
  'hydrous': AppColors.cyan,
};

/// Redes de valles (Hynek 2010).
const Color kValleyColor = Color(0xFF4A90E2);

/// Estilos de texto: Space Grotesk para títulos, Inter (sustituye a IBM Plex Sans) para texto
/// y JetBrains Mono para etiquetas y números.
class AppText {
  static TextStyle head(double size, {FontWeight weight = FontWeight.w700, Color color = AppColors.text, double? height}) =>
      TextStyle(fontFamily: 'SpaceGrotesk', fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: -0.2);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color color = AppColors.text, double? height}) =>
      TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle mono(double size, {FontWeight weight = FontWeight.w500, Color color = AppColors.text, double? height}) =>
      TextStyle(fontFamily: 'JetBrainsMono', fontSize: size, fontWeight: weight, color: color, height: height);

  /// Etiqueta en mayúsculas, 10 px, con espaciado.
  static TextStyle label({Color color = AppColors.textDim, FontWeight weight = FontWeight.w600}) =>
      TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, fontWeight: weight, color: color, letterSpacing: 0.8, height: 1.2);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.orange,
      secondary: AppColors.cyan,
      surface: AppColors.panel,
      error: AppColors.red,
      onSurface: AppColors.text,
    ),
    dividerColor: AppColors.hairline,
    textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: AppColors.text, displayColor: AppColors.text),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      activeTrackColor: AppColors.orange,
      inactiveTrackColor: AppColors.panel3,
      thumbColor: AppColors.orange,
      overlayShape: SliderComponentShape.noOverlay,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      trackShape: const RectangularSliderTrackShape(),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppColors.textDim, width: 1),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.orange : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(AppColors.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      visualDensity: VisualDensity.compact,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2), side: const BorderSide(color: AppColors.hairline)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.panel3, border: Border.all(color: AppColors.hairline)),
      textStyle: AppText.mono(10),
    ),
  );
}
