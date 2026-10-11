import 'package:flutter/material.dart';

/// Paleta de BotMp3: tema oscuro tipo Spotify con acentos de IA.
class AppColors {
  const AppColors._();

  // Marca
  static const Color green = Color(0xFF1DB954); // reproducción / positivo
  static const Color greenDim = Color(0xFF14833B);
  static const Color aiViolet = Color(0xFF7C4DFF); // IA
  static const Color aiCyan = Color(0xFF00E0C6); // bot / ondas sonoras

  // Oscuro
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF14141C);
  static const Color darkSurfaceHigh = Color(0xFF1D1D28);
  static const Color darkOutline = Color(0xFF2A2A38);
  static const Color darkText = Color(0xFFF2F3F7);
  static const Color darkTextDim = Color(0xFF9AA0B4);

  // Claro
  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFEDEFF6);
  static const Color lightText = Color(0xFF14141C);
  static const Color lightTextDim = Color(0xFF5C6172);

  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  /// Degradado para carátulas sin imagen y cabeceras.
  static const LinearGradient coverFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1DB954), Color(0xFF00E0C6), Color(0xFF7C4DFF)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E0C6)],
  );
}

/// Tema Material 3 de BotMp3 (oscuro por defecto, claro opcional o automático).
///
/// Se usan solo APIs disponibles desde Flutter 3.24 para que el proyecto
/// compile tanto en versiones 3.24 como en las más recientes.
class AppTheme {
  const AppTheme._();

  /// Radios y tamaños pensados para el POCO X7 Pro (6.67", 1220x2712, 120 Hz):
  /// objetivos táctiles grandes para manejar la app con una sola mano.
  static const double radius = 18;
  static const double minTouchTarget = 56;

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.green,
      secondary: AppColors.aiViolet,
      tertiary: AppColors.aiCyan,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      outline: AppColors.darkOutline,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
    );

    return _base(scheme, AppColors.darkBg, AppColors.darkTextDim);
  }

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.greenDim,
      secondary: AppColors.aiViolet,
      tertiary: AppColors.aiCyan,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      surfaceContainerHighest: AppColors.lightSurfaceHigh,
    );

    return _base(scheme, AppColors.lightBg, AppColors.lightTextDim);
  }

  static ThemeData _base(ColorScheme scheme, Color background, Color textDim) {
    final Color outlineSoft = scheme.outline.withAlpha(((0.4) * 255).round());

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.comfortable,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 26),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: outlineSoft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 6,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withAlpha(((0.18) * 255).round()),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 12, color: textDim, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected) ? scheme.primary : textDim,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: outlineSoft, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
