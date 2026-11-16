import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';

/// Cabeza de robot animada que acompaña al logo de BotMp3.
///
/// Se dibuja entera con código (sin imágenes) y con los colores del tema:
/// parpadea, mira de lado a lado, la antena late y, mientras suena música, la
/// boca se convierte en un pequeño ecualizador que baila.
///
/// El repintado está aislado (RepaintBoundary + `repaint:` del painter): la
/// animación solo redibuja estos pocos píxeles, no la barra entera. Con
/// "reducir movimiento" queda quieta.
class CabezaRobot extends StatefulWidget {
  const CabezaRobot({super.key, this.tamano = 28, this.sonando = false});

  final double tamano;

  /// Hay música sonando: la boca se vuelve un ecualizador.
  final bool sonando;

  @override
  State<CabezaRobot> createState() => _CabezaRobotState();
}

class _CabezaRobotState extends State<CabezaRobot> with SingleTickerProviderStateMixin {
  // Ciclo de 4 s: un parpadeo por ciclo, mirada y antena lentas.
  late final AnimationController _reloj =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    if (!Motion.reducir) _reloj.repeat();
  }

  @override
  void didUpdateWidget(covariant CabezaRobot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (Motion.reducir && _reloj.isAnimating) {
      _reloj.stop();
      _reloj.value = 0;
    } else if (!Motion.reducir && !_reloj.isAnimating) {
      _reloj.repeat();
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool oscuro = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'BotMp3',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.tamano),
          painter: _RobotPainter(
            reloj: _reloj,
            sonando: widget.sonando,
            colores: <Color>[AppColors.green, AppColors.aiCyan, AppColors.aiViolet],
            pantalla: oscuro ? const Color(0xF20A0F1A) : const Color(0xF2141B2B),
          ),
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({
    required this.reloj,
    required this.sonando,
    required this.colores,
    required this.pantalla,
  }) : super(repaint: reloj);

  final Animation<double> reloj;
  final bool sonando;
  final List<Color> colores;
  final Color pantalla;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final double t = reloj.value;
    final double w = 2 * math.pi * t;
    final Color brillo = colores[1];

    // --- Antena: varilla y bombilla que late.
    final Offset base = Offset(s * 0.5, s * 0.24);
    final Offset punta = Offset(s * 0.5, s * 0.1);
    canvas.drawLine(
      base,
      punta,
      Paint()
        ..color = colores[2]
        ..strokeWidth = s * 0.06
        ..strokeCap = StrokeCap.round,
    );
    final double latido = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(w * 2));
    canvas.drawCircle(
      punta,
      s * 0.12,
      Paint()
        ..color = brillo.withAlpha((90 * latido).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
    );
    canvas.drawCircle(punta, s * 0.07, Paint()..color = Color.lerp(brillo, Colors.white, 0.35 * latido)!);

    // --- Orejas.
    final Paint oreja = Paint()..color = colores[2];
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.02, s * 0.48, s * 0.1, s * 0.22), Radius.circular(s * 0.04)),
      oreja,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.88, s * 0.48, s * 0.1, s * 0.22), Radius.circular(s * 0.04)),
      oreja,
    );

    // --- Cabeza con el degradado del logo y un reflejo de cristal arriba.
    final Rect cabeza = Rect.fromLTRB(s * 0.09, s * 0.24, s * 0.91, s * 0.96);
    final RRect formaCabeza = RRect.fromRectAndRadius(cabeza, Radius.circular(s * 0.24));
    canvas.drawRRect(
      formaCabeza,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colores,
        ).createShader(cabeza),
    );
    canvas.drawRRect(
      formaCabeza,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: <Color>[Colors.white.withAlpha(90), Colors.white.withAlpha(0)],
        ).createShader(cabeza),
    );

    // --- Pantalla de la cara.
    final Rect cara = Rect.fromLTRB(s * 0.2, s * 0.38, s * 0.8, s * 0.86);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cara, Radius.circular(s * 0.15)),
      Paint()..color = pantalla,
    );

    // --- Ojos: miran de lado a lado y parpadean una vez por ciclo.
    final double mirada = math.sin(w) * s * 0.035;
    final double parpadeo = _parpadeo(t);
    final Paint ojo = Paint()..color = Color.lerp(brillo, Colors.white, 0.25)!;
    final Paint halo = Paint()
      ..color = brillo.withAlpha(110)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04);
    for (final double x in <double>[0.37, 0.63]) {
      final Rect r = Rect.fromCenter(
        center: Offset(s * x + mirada, s * 0.56),
        width: s * 0.13,
        height: s * 0.15 * parpadeo,
      );
      canvas.drawOval(r.inflate(s * 0.02), halo);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.07)), ojo);
    }

    // --- Boca: ecualizador si suena música; si no, una sonrisa.
    final Paint boca = Paint()
      ..color = colores[0]
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.055;
    if (sonando) {
      for (int i = 0; i < 3; i++) {
        final double alto = s * (0.04 + 0.07 * (0.5 + 0.5 * math.sin(w * 6 + i * 1.7)));
        final double x = s * (0.42 + i * 0.08);
        canvas.drawLine(Offset(x, s * 0.76 - alto), Offset(x, s * 0.76), boca);
      }
    } else {
      final Path sonrisa = Path()
        ..moveTo(s * 0.4, s * 0.72)
        ..quadraticBezierTo(s * 0.5, s * 0.79, s * 0.6, s * 0.72);
      canvas.drawPath(sonrisa, boca..style = PaintingStyle.stroke);
    }
  }

  /// 1 = ojos abiertos; baja a 0.15 un instante cerca del final del ciclo.
  double _parpadeo(double t) {
    const double inicio = 0.9;
    const double fin = 0.96;
    if (t < inicio || t > fin) return 1;
    final double fase = (t - inicio) / (fin - inicio); // 0..1
    return 1 - 0.85 * math.sin(math.pi * fase);
  }

  @override
  bool shouldRepaint(covariant _RobotPainter old) =>
      old.sonando != sonando || old.pantalla != pantalla || !_mismos(old.colores, colores);

  static bool _mismos(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
