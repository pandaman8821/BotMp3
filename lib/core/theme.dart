import 'package:flutter/material.dart';

import 'theme/catalog.dart';
import 'theme/theme_manager.dart';
import 'theme/tokens.dart';

/// Paleta de BotMp3: ahora es una FACHADA de los tokens del tema activo.
///
/// Se mantienen los mismos nombres de siempre (green, darkBg...) para que las
/// pantallas existentes no cambien, pero cada color se resuelve contra el tema
/// elegido por el usuario, por lo que el cambio es instantaneo.
class AppColors {
  const AppColors._();

  static BotTokens get _t => ThemeManager.instance.tokens;

  // Marca
  static Color get green => _t.primary;
  static Color get greenDim => _t.primaryDark;
  static Color get aiViolet => _t.secondary;
  static Color get aiCyan => _t.accent;

  // Superficies y texto (mismos nombres para todas las pantallas)
  static Color get darkBg => _t.background;
  static Color get darkSurface => _t.surface;
  static Color get darkSurfaceHigh => _t.surfaceHigh;
  static Color get darkOutline => _t.outline;
  static Color get darkText => _t.text;
  static Color get darkTextDim => _t.textDim;

  static Color get lightBg => _t.background;
  static Color get lightSurface => _t.surface;
  static Color get lightSurfaceHigh => _t.surfaceHigh;
  static Color get lightText => _t.text;
  static Color get lightTextDim => _t.textDim;

  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  /// Degradado de caratulas sin imagen y cabeceras (definido por el tema).
  static LinearGradient get coverFallback => _t.coverFallback;
  static LinearGradient get aiGradient => _t.aiGradient;
}

/// Tema Material 3 construido a partir del estilo elegido.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() => ThemeManager.instance.tokens.materialTheme();

  static ThemeData light() {
    final BotTokens alterno = ThemeManager.instance.tokens.light ?? ThemeManager.instance.tokens;
    return alterno.materialTheme();
  }

  static double get radius => ThemeManager.instance.tokens.radius;
  static double get minTouchTarget => 56;

  /// Id del tema actual (util para depuracion y pruebas).
  static String get temaId => themeById(ThemeManager.instance.temaId).id;
}