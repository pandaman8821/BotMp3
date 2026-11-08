import 'package:flutter/material.dart';

/// Fondo decorativo de un tema (se pinta detras de toda la app).
enum BotBackdrop { plain, neonGlow, vintagePaper, glassBlur, zenWaves, animeLines, gothicArches, cinemaBars }

/// Estilo del ecualizador / ondas sonoras segun el tema.
enum BotEqStyle { simple, neonBars, vintageNeedle, glassSoft, zenWave, animeBeat, gothicFlame, cinemaVu }

/// Tokens de un estilo visual de BotMp3.
///
/// Un tema NO reimplementa pantallas: solo define tokens (colores, tipografia,
/// radios, sombras, fondo, animacion y estilo de ecualizador) que el resto de
/// la app consume a traves de [AppColors] y de este objeto.
@immutable
class BotTokens {
  const BotTokens({
    required this.id,
    required this.dark,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.text,
    required this.textDim,
    required this.onPrimary,
    required this.coverColors,
    this.radius = 18,
    this.fontFamily,
    this.titleFontFamily,
    this.titleWeight = FontWeight.w700,
    this.titleSpacing = 0,
    this.uppercaseTitles = false,
    this.backdrop = BotBackdrop.plain,
    this.eqStyle = BotEqStyle.simple,
    this.glow = false,
    this.motionMs = 240,
    this.letterbox = false,
    this.cardElevation = 0,
    this.light,
  });

  final String id;
  final bool dark;

  // Colores base
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color text;
  final Color textDim;
  final Color onPrimary;
  final List<Color> coverColors;

  // Forma y tipografia
  final double radius;
  final String? fontFamily;
  final String? titleFontFamily;
  final FontWeight titleWeight;
  final double titleSpacing;
  final bool uppercaseTitles;

  // Efectos y movimiento (motionMs = 0 => sin animaciones)
  final BotBackdrop backdrop;
  final BotEqStyle eqStyle;
  final bool glow;
  final int motionMs;
  final bool letterbox;
  final double cardElevation;

  /// Variante clara opcional (para los estilos que respetan modo claro).
  final BotTokens? light;

  bool get reduceMotion => motionMs <= 0;

  LinearGradient get coverFallback => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: coverColors,
      );

  LinearGradient get aiGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[secondary, accent],
      );

  TextStyle get titleStyle => TextStyle(
        fontFamily: titleFontFamily ?? fontFamily,
        fontWeight: titleWeight,
        letterSpacing: titleSpacing,
        color: text,
      );

  /// Tema Material 3 construido solo con tokens: ninguna pantalla necesita
  /// saber de que estilo se trata.
  ThemeData materialTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      onSurface: text,
      outline: outline,
      surfaceContainerHighest: surfaceHigh,
    );
    final Color outlineSoft = outline.withAlpha(125);
    final TextStyle baseText = TextStyle(fontFamily: fontFamily, color: text);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: glow ? InkRipple.splashFactory : InkSparkle.splashFactory,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      textTheme: TextTheme(bodyMedium: baseText, bodyLarge: baseText),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleStyle.copyWith(fontSize: 22),
        iconTheme: IconThemeData(color: text, size: 26),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: text,
        textColor: text,
        minVerticalPadding: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.9)),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: outlineSoft),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.9)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, minimumSize: const Size(64, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide(color: outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: TextStyle(color: textDim, fontFamily: fontFamily),
        hintStyle: TextStyle(color: textDim, fontFamily: fontFamily),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.7)),
        side: BorderSide(color: outlineSoft),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: outline,
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withAlpha(230),
        indicatorColor: primary.withAlpha(46),
        height: 68,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontFamily: fontFamily, fontSize: 12, color: textDim, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected) ? primary : textDim,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: TextStyle(color: text, fontFamily: fontFamily),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.8)),
      ),
      dividerTheme: DividerThemeData(color: outlineSoft, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}