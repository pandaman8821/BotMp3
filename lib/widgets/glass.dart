import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';
import '../core/theme.dart';

/// Sistema de cristal («Liquid Glass») de BotMp3.
///
/// Replica las piezas del material de Apple que sí son posibles en Android:
/// desenfoque real del fondo, tinte adaptativo, luz especular orientable,
/// brillo de borde (Fresnel), bisel interior y respuesta táctil con muelle.
///
/// Se implementa solo con APIs del SDK de Flutter (`BackdropFilter`, gradientes
/// y animaciones), sin dependencias externas ni shaders que puedan fallar en un
/// dispositivo concreto.
///
/// Regla de oro del lenguaje: **cristal en la navegación y los controles,
/// contenido opaco**.

/// Cantidad de efecto aplicada a una superficie.
enum GlassQuality {
  /// Sin desenfoque: superficie sólida (ahorro de batería).
  off,

  /// Desenfoque + tinte, sin capas decorativas.
  light,

  /// Desenfoque, tinte, especular y bisel (recomendado).
  standard,

  /// Todo lo anterior con más profundidad y brillo de borde.
  high;

bool get usesBlur => this != GlassQuality.off;

    /// Intensidad global (0..1) que fija Ajustes. Hace el efecto CONTINUO: el
    /// deslizador cambia el desenfoque de verdad, no solo entre tres niveles.
    static double intensidadGlobal = 0.75;

  double get blurSigma => switch (this) {
        GlassQuality.off => 0,
        GlassQuality.light => 11,
        GlassQuality.standard => 19,
        GlassQuality.high => 32,
      };

  double get decoration => switch (this) {
        GlassQuality.off => 0,
        GlassQuality.light => 0.35,
        GlassQuality.standard => 1,
        GlassQuality.high => 1.3,
      };

  bool get isFlat => this == GlassQuality.off;
}

/// Paleta del cristal resuelta por brillo del tema.
class GlassTheme {
  const GlassTheme({
    required this.tint,
    required this.tintAccent,
    required this.rim,
    required this.innerShade,
    required this.specular,
    required this.fallback,
  });

  final Color tint;
  final Color tintAccent;
  final Color rim;
  final Color innerShade;
  final Color specular;
  final Color fallback;

  static GlassTheme of(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = AppColors.aiViolet;
    if (dark) {
      return GlassTheme(
        tint: const Color(0x14FFFFFF),
        tintAccent: accent.withAlpha(38),
        rim: const Color(0x4DFFFFFF),
        innerShade: const Color(0x40000000),
        specular: const Color(0x2EFFFFFF),
        fallback: AppColors.darkSurfaceHigh,
      );
    }
    return GlassTheme(
      tint: const Color(0x57FFFFFF),
      tintAccent: accent.withAlpha(24),
      rim: const Color(0xB3FFFFFF),
      innerShade: const Color(0x1A000000),
      specular: const Color(0x8CFFFFFF),
      fallback: AppColors.lightSurfaceHigh,
    );
  }
}

/// Superficie de cristal reutilizable (paneles, barras, tarjetas, hojas).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24,
    this.quality = GlassQuality.standard,
    this.specularAngle,
    this.width,
    this.height,
    this.glowColor,
    this.shadow = true,
    this.accentTint = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final GlassQuality quality;

  /// Ángulo (radianes) de la luz especular; por defecto, arriba-izquierda.
  final double? specularAngle;

  final double? width;
  final double? height;

  /// Resplandor exterior (por ejemplo el color dominante de la carátula).
  final Color? glowColor;
  final bool shadow;
  final bool accentTint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final GlassTheme glass = GlassTheme.of(context);
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    final double decoration = quality.decoration;
    final double angle = specularAngle ?? -0.7;

    Widget surface = _buildSurface(context, glass, radius, decoration, angle);

    if (onTap != null) {
      surface = _PressableGlass(onTap: onTap!, child: surface);
    }

    return Padding(
      padding: margin,
      child: SizedBox(width: width, height: height, child: surface),
    );
  }

  Widget _buildSurface(
    BuildContext context,
    GlassTheme glass,
    BorderRadius radius,
    double decoration,
    double angle,
  ) {
    final Widget tint = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accentTint ? glass.tintAccent : glass.tint,
            glass.tint,
          ],
        ),
      ),
    );

    final Widget specular = IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment(math.cos(angle), math.sin(angle)),
            end: Alignment(-math.cos(angle), -math.sin(angle)),
            colors: <Color>[
              glass.specular.withAlpha((glass.specular.a * 255 * 0.55 * decoration).round().clamp(0, 255)),
              const Color(0x00FFFFFF),
              const Color(0x00FFFFFF),
            ],
            stops: const <double>[0.0, 0.45, 1.0],
          ),
        ),
      ),
    );

    final Widget bevel = IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0x1AFFFFFF),
              const Color(0x00FFFFFF),
              glass.innerShade,
            ],
            stops: const <double>[0.0, 0.32, 1.0],
          ),
        ),
      ),
    );

    // El contenido (no posicionado) define el tamaño; las capas decorativas se
    // estiran con `Positioned.fill`.
    Widget content = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: tint),
          if (decoration > 0.4) Positioned.fill(child: specular),
          if (decoration > 0.4) Positioned.fill(child: bevel),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (quality.usesBlur) {
      final double sigma = quality.blurSigma * (0.3 + GlassQuality.intensidadGlobal);
      final ui.ImageFilter blur = ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.clamp,
      );
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // «Vibrancia»: el cristal de Apple no solo desenfoca, tambien satura
          // un poco lo que hay detras para que los colores se lean vivos y no
          // lavados. Es una matriz de color estandar (sin shaders propios).
          filter: decoration > 0.4
              ? ui.ImageFilter.compose(
                  outer: ui.ColorFilter.matrix(_matrizSaturacion(1 + 0.28 * decoration)),
                  inner: blur,
                )
              : blur,
          child: content,
        ),
      );
    }

    // Borde de luz (Fresnel): brillante del lado de la luz, casi invisible en
    // el centro y con un rebote suave en el lado opuesto, mas una linea
    // especular fina justo por dentro del borde superior.
    if (decoration > 0) {
      content = CustomPaint(
        foregroundPainter: _BordeCristalPainter(
          radius: borderRadius,
          angle: angle,
          rim: glass.rim,
          fuerza: decoration,
        ),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: decoration > 0 ? null : Border.all(color: Colors.black.withAlpha(18)),
        boxShadow: <BoxShadow>[
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withAlpha(70),
              blurRadius: 30,
              spreadRadius: -6,
            ),
          if (shadow)
            BoxShadow(
              color: Colors.black.withAlpha(quality.isFlat ? 18 : 62),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
        ],
      ),
      child: content,
    );
  }
}

/// Matriz 5x4 de saturación (1 = sin cambio). Pesos de luminancia Rec. 709.
List<double> _matrizSaturacion(double s) {
  const double r = 0.2126;
  const double g = 0.7152;
  const double b = 0.0722;
  final double i = 1 - s;
  return <double>[
    r * i + s, g * i, b * i, 0, 0,
    r * i, g * i + s, b * i, 0, 0,
    r * i, g * i, b * i + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// Pinta el borde del cristal con luz direccional (en lugar de un borde plano
/// del mismo color en todo el contorno) y una línea especular interior.
class _BordeCristalPainter extends CustomPainter {
  const _BordeCristalPainter({
    required this.radius,
    required this.angle,
    required this.rim,
    required this.fuerza,
  });

  final double radius;
  final double angle;
  final Color rim;
  final double fuerza;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect rect = Offset.zero & size;
    final double rad = math.min(radius, size.shortestSide / 2);
    final RRect contorno = RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(rad));
    final int a = (rim.a * 255).round();
    final double f = fuerza.clamp(0.0, 1.3);

    // 1) Borde direccional: fuerte donde da la luz, rebote tenue enfrente.
    final Paint borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment(math.cos(angle), math.sin(angle)),
        end: Alignment(-math.cos(angle), -math.sin(angle)),
        colors: <Color>[
          rim.withAlpha((a * (0.85 * f)).round().clamp(0, 255)),
          rim.withAlpha((a * 0.18).round().clamp(0, 255)),
          rim.withAlpha((a * 0.12).round().clamp(0, 255)),
          rim.withAlpha((a * (0.42 * f)).round().clamp(0, 255)),
        ],
        stops: const <double>[0.0, 0.38, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRRect(contorno, borde);

    // 2) Línea especular: un hilo de luz por dentro del borde superior que se
    // desvanece hacia los lados (la "lámina" de cristal vista de canto).
    if (size.height >= 24 && f > 0.4) {
      final RRect interior = RRect.fromRectAndRadius(
        rect.deflate(1.6),
        Radius.circular(math.max(0, rad - 1.2)),
      );
      final Paint hilo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withAlpha((70 * f).round().clamp(0, 255)),
            Colors.white.withAlpha(0),
          ],
          stops: const <double>[0.0, 0.22],
        ).createShader(rect);
      canvas.drawRRect(interior, hilo);
    }
  }

  @override
  bool shouldRepaint(covariant _BordeCristalPainter old) =>
      old.radius != radius || old.angle != angle || old.rim != rim || old.fuerza != fuerza;
}

/// Respuesta táctil: se encoge al pulsar y vuelve con un rebote suave.
class _PressableGlass extends StatefulWidget {
  const _PressableGlass({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableGlass> createState() => _PressableGlassState();
}

class _PressableGlassState extends State<_PressableGlass> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Agrupa varias superficies de cristal para que compartan **una sola lectura
/// del fondo por fotograma** (clave para mantener los 120 Hz).
class GlassGroup extends StatelessWidget {
  const GlassGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => BackdropGroup(child: child);
}

/// Destino de la barra de navegación de cristal.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Traduce los ajustes del usuario a una calidad de cristal concreta.
GlassQuality glassQualityFor({
  required bool enabled,
  required double intensity,
  bool batterySaver = false,
}) {
  if (!enabled) return GlassQuality.off; // El ahorro de bateria ya no lo apaga: mandaba el interruptor en silencio
  if (intensity < 0.4) return GlassQuality.light;
  if (intensity < 0.85) return GlassQuality.standard;
  return GlassQuality.high;
}

/// Barra de navegación inferior flotante de cristal con indicador que se
/// desliza con rebote y respuesta háptica.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.destinations,
    this.quality = GlassQuality.standard,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final List<GlassNavDestination> destinations;
  final GlassQuality quality;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> {
  /// Duración del deslizamiento, proporcional a la distancia recorrida.
  int _durationMs = 420;

  @override
  void didUpdateWidget(covariant GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final int distance = (widget.index - oldWidget.index).abs();
      _durationMs = (300 + 80 * distance).clamp(300, 620);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.destinations.length;

    return GlassSurface(
      quality: widget.quality,
      borderRadius: 30,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double itemWidth = constraints.maxWidth / count;
          final double destino = widget.index.toDouble();
          // Dos bordes con tiempos distintos: la "cabeza" llega antes que la
          // "cola", así la gota se estira hacia la pestaña nueva y luego se
          // recoge con rebote. Con "reducir movimiento" el salto es directo.
          final Duration rapida =
              Motion.ajustar(Duration(milliseconds: (_durationMs * 0.5).round()));
          final Duration lenta = Motion.ajustar(Duration(milliseconds: _durationMs));
          return SizedBox(
            height: 58,
            child: Stack(
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: destino),
                  duration: rapida,
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double cabeza, Widget? _) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: destino),
                      duration: lenta,
                      curve: Curves.easeOutBack,
                      builder: (BuildContext context, double cola, Widget? gota) {
                        final double izquierda =
                            (math.min(cabeza, cola) * itemWidth).clamp(0.0, constraints.maxWidth);
                        final double derecha = ((math.max(cabeza, cola) + 1) * itemWidth)
                            .clamp(izquierda, constraints.maxWidth);
                        // Al estirarse, la gota adelgaza un poco (volumen constante).
                        final double estirada = (cabeza - cola).abs().clamp(0.0, 1.0);
                        final double vertical = 3 + 4 * estirada;
                        return Positioned(
                          // Lo usan las pruebas para seguir el indicador.
                          key: const ValueKey<String>('glass-nav-indicator'),
                          left: izquierda,
                          width: derecha - izquierda,
                          top: vertical,
                          bottom: vertical,
                          child: gota!,
                        );
                      },
                      child: const _GotaIndicador(),
                    );
                  },
                ),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < count; i++)
                      Expanded(
                        child: _GlassNavItem(
                          destination: widget.destinations[i],
                          selected: i == widget.index,
                          onTap: () {
                            if (i == widget.index) return;
                            HapticFeedback.selectionClick();
                            widget.onChanged(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Gota de cristal tintado que marca la pestaña activa.
class _GotaIndicador extends StatelessWidget {
  const _GotaIndicador();

  @override
  Widget build(BuildContext context) {
    // Se lee del tema (no de AppColors) para que se repinte al cambiar de estilo.
    final Color acento = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: CustomPaint(
        foregroundPainter: const _BordeCristalPainter(
          radius: 22,
          angle: -1.2,
          rim: Color(0xCCFFFFFF),
          fuerza: 0.9,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[acento.withAlpha(128), acento.withAlpha(46)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(color: acento.withAlpha(70), blurRadius: 16, spreadRadius: -4),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: Motion.ajustar(const Duration(milliseconds: 280)),
            curve: Curves.easeOutBack,
            child: Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 23,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de cristal con título opcional.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.title,
    this.quality = GlassQuality.standard,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.glowColor,
  });

  final Widget child;
  final String? title;
  final GlassQuality quality;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassSurface(
      quality: quality,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      glowColor: glowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

/// Chip de cristal para órdenes de la IA, filtros y etiquetas.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.quality = GlassQuality.standard,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GlassSurface(
      quality: quality,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      accentTint: selected,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Superficie para hojas modales y diálogos (cristal más profundo).
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.quality = GlassQuality.high,
  });

  final Widget child;
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      quality: quality,
      borderRadius: 28,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: child,
    );
  }
}

/// Panel de cristal anclado a la parte inferior (controles de reproducción).
class GlassBottomPanel extends StatelessWidget {
  const GlassBottomPanel({
    super.key,
    required this.child,
    this.quality = GlassQuality.high,
    this.glowColor,
  });

  final Widget child;
  final GlassQuality quality;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      quality: quality,
      borderRadius: 30,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      glowColor: glowColor,
      child: child,
    );
  }
}
