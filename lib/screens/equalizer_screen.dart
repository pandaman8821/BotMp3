import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/equalizer_service.dart';
import '../widgets/glass.dart';

/// Ecualizador con el lenguaje Liquid Glass de la app: curva de respuesta
/// luminosa, deslizadores por banda y estilos como chips de cristal. Sigue los
/// colores del tema elegido (antes era una pantalla nativa con colores fijos).
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  /// Nombre traducido de un preset.
  static String nombrePreset(AppLocalizations loc, String id) => switch (id) {
        'flat' => loc.eqpFlat,
        'rock' => loc.eqpRock,
        'pop' => loc.eqpPop,
        'jazz' => loc.eqpJazz,
        'classical' => loc.eqpClassical,
        'rap' => loc.eqpRap,
        'reggaeton' => loc.eqpReggaeton,
        'cumbia' => loc.eqpCumbia,
        'electronic' => loc.eqpElectronic,
        'heavy' => loc.eqpHeavy,
        'vocal' => loc.eqpVocal,
        'bass' => loc.eqpBass,
        'treble' => loc.eqpTreble,
        _ => loc.eqCustom,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final GlassQuality calidad = context.watch<SettingsProvider>().glassQuality;
    final Ecualizador eq = Ecualizador.instance;

    return Scaffold(
      appBar: AppBar(title: Text(loc.equalizer)),
      body: ListenableBuilder(
        listenable: eq,
        builder: (BuildContext context, Widget? _) {
          return GlassGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
              children: <Widget>[
                _Cabecera(eq: eq, calidad: calidad),
                if (!eq.disponible)
                  _Aviso(texto: loc.eqNotAvailable, calidad: calidad)
                else if (!eq.listo)
                  _Aviso(texto: loc.eqWaitingSong, calidad: calidad)
                else ...<Widget>[
                  GlassCard(
                    quality: calidad,
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                    child: SizedBox(
                      height: 150,
                      child: _CurvaAnimada(eq: eq),
                    ),
                  ),
                  GlassCard(
                    quality: calidad,
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                    child: _Bandas(eq: eq),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: Text(
                    loc.eqPresetsTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final PresetEq p in Ecualizador.presets)
                        GlassChip(
                          label: nombrePreset(loc, p.id),
                          icon: p.id == eq.preset ? Icons.check_rounded : null,
                          selected: p.id == eq.preset,
                          quality: calidad,
                          onTap: eq.disponible ? () => eq.aplicarPreset(p) : null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.eq, required this.calidad});

  final Ecualizador eq;
  final GlassQuality calidad;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final String detalle = eq.listo
        ? loc.eqBandsInfo(
            eq.frecuencias.length,
            eq.minDb.toStringAsFixed(0),
            '+${eq.maxDb.toStringAsFixed(0)}',
          )
        : loc.eqDescGlass;
    return GlassCard(
      quality: calidad,
      glowColor: eq.activo ? AppColors.aiCyan : null,
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: Motion.ajustar(const Duration(milliseconds: 300)),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: eq.activo
                    ? <Color>[AppColors.green, AppColors.aiCyan, AppColors.aiViolet]
                    : <Color>[Colors.grey.shade700, Colors.grey.shade800],
              ),
            ),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  EqualizerScreen.nombrePreset(loc, eq.preset),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(detalle, style: TextStyle(fontSize: 12, color: AppColors.darkTextDim)),
              ],
            ),
          ),
          Switch(
            value: eq.activo,
            onChanged: eq.disponible ? eq.setActivo : null,
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.calidad});

  final String texto;
  final GlassQuality calidad;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      quality: calidad,
      child: Row(
        children: <Widget>[
          Icon(Icons.music_note_rounded, color: AppColors.aiCyan),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

/// Interpola dos listas de ganancias (para animar la curva al cambiar de estilo).
class _ListaTween extends Tween<List<double>> {
  _ListaTween({super.end});

  @override
  List<double> lerp(double t) {
    final List<double> a = begin ?? end!;
    final List<double> b = end!;
    if (a.length != b.length) return b;
    return <double>[for (int i = 0; i < b.length; i++) a[i] + (b[i] - a[i]) * t];
  }
}

class _CurvaAnimada extends StatelessWidget {
  const _CurvaAnimada({required this.eq});

  final Ecualizador eq;

  @override
  Widget build(BuildContext context) {
    final ColorScheme esquema = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<List<double>>(
      tween: _ListaTween(end: eq.ganancias),
      duration: Motion.ajustar(const Duration(milliseconds: 450)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, List<double> valores, Widget? _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _CurvaPainter(
            ganancias: valores,
            minDb: eq.minDb,
            maxDb: eq.maxDb,
            activo: eq.activo,
            colores: <Color>[AppColors.green, AppColors.aiCyan, AppColors.aiViolet],
            linea: esquema.onSurface,
          ),
        );
      },
    );
  }
}

/// Curva de respuesta: trazo suave con degradado y brillo, relleno translúcido
/// y la línea de 0 dB como referencia.
class _CurvaPainter extends CustomPainter {
  _CurvaPainter({
    required this.ganancias,
    required this.minDb,
    required this.maxDb,
    required this.activo,
    required this.colores,
    required this.linea,
  });

  final List<double> ganancias;
  final double minDb;
  final double maxDb;
  final bool activo;
  final List<Color> colores;
  final Color linea;

  @override
  void paint(Canvas canvas, Size size) {
    if (ganancias.isEmpty || size.isEmpty) return;
    final Rect area = Offset.zero & size;
    double y(double db) => size.height * (1 - (db - minDb) / (maxDb - minDb));
    final double paso = ganancias.length == 1 ? 0 : size.width / (ganancias.length - 1);
    final List<Offset> puntos = <Offset>[
      for (int i = 0; i < ganancias.length; i++) Offset(paso * i, y(ganancias[i])),
    ];

    // Línea de 0 dB.
    final double cero = y(0);
    final Paint guia = Paint()
      ..color = linea.withAlpha(40)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, cero), Offset(math.min(x + 5, size.width), cero), guia);
    }

    // Trazo suave (Catmull-Rom convertido a curvas Bézier).
    final Path curva = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (int i = 0; i < puntos.length - 1; i++) {
      final Offset p0 = i == 0 ? puntos[i] : puntos[i - 1];
      final Offset p1 = puntos[i];
      final Offset p2 = puntos[i + 1];
      final Offset p3 = i + 2 < puntos.length ? puntos[i + 2] : p2;
      final Offset c1 = p1 + (p2 - p0) / 6;
      final Offset c2 = p2 - (p3 - p1) / 6;
      curva.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final int alfa = activo ? 255 : 90;
    final Shader degradado = LinearGradient(
      colors: colores.map((Color c) => c.withAlpha(alfa)).toList(),
    ).createShader(area);

    // Relleno bajo la curva.
    final Path relleno = Path.from(curva)
      ..lineTo(puntos.last.dx, size.height)
      ..lineTo(puntos.first.dx, size.height)
      ..close();
    canvas.drawPath(
      relleno,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[colores[1].withAlpha(activo ? 70 : 20), colores[1].withAlpha(0)],
        ).createShader(area),
    );

    // Brillo y trazo.
    if (activo) {
      canvas.drawPath(
        curva,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..shader = degradado
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      curva,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = degradado,
    );

    // Puntos de cada banda.
    for (final Offset p in puntos) {
      canvas.drawCircle(p, 4.5, Paint()..color = Colors.white.withAlpha(activo ? 235 : 110));
    }
  }

  @override
  bool shouldRepaint(covariant _CurvaPainter old) =>
      old.activo != activo ||
      old.minDb != minDb ||
      old.maxDb != maxDb ||
      old.linea != linea ||
      !_iguales(old.ganancias, ganancias);

  static bool _iguales(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Bandas extends StatelessWidget {
  const _Bandas({required this.eq});

  final Ecualizador eq;

  static String _hz(double f) {
    if (f < 1000) return '${f.round()}';
    final double k = f / 1000;
    return '${k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }

  @override
  Widget build(BuildContext context) {
    final List<double> frecuencias = eq.frecuencias;
    final List<double> ganancias = eq.ganancias;
    final ColorScheme esquema = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        for (int i = 0; i < ganancias.length && i < frecuencias.length; i++)
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  '${ganancias[i] > 0 ? '+' : ''}${ganancias[i].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    color: ganancias[i].abs() < 0.5
                        ? AppColors.darkTextDim
                        : (ganancias[i] > 0 ? AppColors.green : esquema.error),
                  ),
                ),
                SizedBox(
                  height: 170,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: eq.activo ? AppColors.aiCyan : esquema.outline,
                        inactiveTrackColor: esquema.onSurface.withAlpha(30),
                        thumbColor: Colors.white,
                        overlayColor: AppColors.aiCyan.withAlpha(40),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 3),
                      ),
                      child: Slider(
                        min: eq.minDb,
                        max: eq.maxDb,
                        value: ganancias[i].clamp(eq.minDb, eq.maxDb),
                        onChanged: (double v) => eq.setBanda(i, v),
                        onChangeEnd: (_) => eq.confirmarBandas(),
                      ),
                    ),
                  ),
                ),
                Text(_hz(frecuencias[i]), style: TextStyle(fontSize: 11, color: AppColors.darkTextDim)),
              ],
            ),
          ),
      ],
    );
  }
}
