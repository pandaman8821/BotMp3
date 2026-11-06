import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme_manager.dart';
import 'tokens.dart';

/// Fondo decorativo de la app segun el tema activo.
///
/// Se dibuja con un unico painter barato (sin imagenes ni blur real) para no
/// afectar la reproduccion de audio. Respeta "reducir movimiento": si esta
/// activo, todo queda estatico.
class ThemeBackdrop extends StatefulWidget {
  const ThemeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeBackdrop> createState() => _ThemeBackdropState();
}

class _ThemeBackdropState extends State<ThemeBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18));
    _sincronizar();
  }

  void _sincronizar() {
    final ThemeManager gestor = ThemeManager.instance;
    final bool animar = gestor.motionMs > 0 &&
        (gestor.tokens.backdrop == BotBackdrop.zenWaves ||
            gestor.tokens.backdrop == BotBackdrop.neonGlow ||
            gestor.tokens.backdrop == BotBackdrop.gothicArches);
    if (animar && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!animar && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BotTokens t = ThemeManager.instance.tokens;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (BuildContext context, Widget? _) {
              return CustomPaint(
                painter: _BackdropPainter(tokens: t, t: _ctrl.value),
                size: Size.infinite,
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.tokens, required this.t});

  final BotTokens tokens;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    switch (tokens.backdrop) {
      case BotBackdrop.plain:
        _degradado(canvas, area, <Color>[tokens.background, tokens.surface]);
      case BotBackdrop.neonGlow:
        _degradado(canvas, area, <Color>[tokens.background, const Color(0xFF0B0420)]);
        _brillo(canvas, area, tokens.primary, const Alignment(-0.8, -0.9), 0.55);
        _brillo(canvas, area, tokens.secondary, const Alignment(0.9, 0.2), 0.45);
        _rejilla(canvas, area);
      case BotBackdrop.vintagePaper:
        _degradado(canvas, area, <Color>[tokens.background, tokens.surfaceHigh]);
        _papel(canvas, area);
      case BotBackdrop.glassBlur:
        _degradado(canvas, area, <Color>[tokens.background, tokens.surface]);
        _brillo(canvas, area, tokens.primary, const Alignment(-0.7, -0.6), 0.35);
        _brillo(canvas, area, tokens.secondary, const Alignment(0.8, 0.7), 0.28);
      case BotBackdrop.zenWaves:
        _degradado(canvas, area, <Color>[tokens.background, tokens.surfaceHigh]);
        _ondas(canvas, area);
      case BotBackdrop.animeLines:
        _degradado(canvas, area, <Color>[tokens.background, tokens.surfaceHigh]);
        _lineasVelocidad(canvas, area);
      case BotBackdrop.gothicArches:
        _degradado(canvas, area, <Color>[tokens.background, const Color(0xFF120A16)]);
        _arcos(canvas, area);
        _niebla(canvas, area);
      case BotBackdrop.cinemaBars:
        _degradado(canvas, area, <Color>[tokens.background, const Color(0xFF0C0B08)]);
        _letterbox(canvas, area);
        _grano(canvas, area);
    }
  }

  void _degradado(Canvas c, Rect r, List<Color> colores) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colores,
        ).createShader(r),
    );
  }

  void _brillo(Canvas c, Rect r, Color color, Alignment alineacion, double radio) {
    final Offset centro = alineacion.alongSize(r.size) + r.topLeft;
    final double lado = math.max(r.width, r.height) * radio;
    c.drawCircle(
      centro,
      lado,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color.withAlpha(46), color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: centro, radius: lado)),
    );
  }

  void _rejilla(Canvas c, Rect r) {
    final Paint p = Paint()
      ..color = tokens.primary.withAlpha(14)
      ..strokeWidth = 1;
    const double paso = 48;
    for (double x = 0; x <= r.width; x += paso) {
      c.drawLine(Offset(x, 0), Offset(x, r.height), p);
    }
    for (double y = 0; y <= r.height; y += paso) {
      c.drawLine(Offset(0, y), Offset(r.width, y), p);
    }
  }

  void _papel(Canvas c, Rect r) {
    final Paint p = Paint()
      ..color = tokens.outline.withAlpha(28)
      ..strokeWidth = 1;
    for (double y = 6; y < r.height; y += 7) {
      c.drawLine(Offset(0, y), Offset(r.width, y), p);
    }
  }

  void _ondas(Canvas c, Rect r) {
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (int i = 0; i < 3; i++) {
      final Path camino = Path();
      final double amplitud = 18.0 + i * 10;
      final double base = r.height * (0.34 + i * 0.16);
      final double fase = t * 2 * math.pi + i * 1.2;
      for (double x = 0; x <= r.width; x += 12) {
        final double y = base + math.sin((x / r.width) * 2 * math.pi * 1.6 + fase) * amplitud;
        if (x == 0) {
          camino.moveTo(x, y);
        } else {
          camino.lineTo(x, y);
        }
      }
      p.color = <Color>[tokens.primary, tokens.secondary, tokens.accent][i].withAlpha(30);
      c.drawPath(camino, p);
    }
  }

  void _lineasVelocidad(Canvas c, Rect r) {
    final Offset centro = r.center;
    final Paint p = Paint()..strokeWidth = 2;
    const int lineas = 42;
    for (int i = 0; i < lineas; i++) {
      final double ang = (i / lineas) * 2 * math.pi + t * 0.25;
      final Color color = i.isEven ? tokens.primary : tokens.secondary;
      p.color = color.withAlpha(i.isEven ? 16 : 12);
      final double radio = r.longestSide * 0.5;
      c.drawLine(
        centro + Offset(math.cos(ang), math.sin(ang)) * radio * 0.28,
        centro + Offset(math.cos(ang), math.sin(ang)) * radio,
        p,
      );
    }
    c.drawCircle(centro, r.shortestSide * 0.22, Paint()..color = tokens.surfaceHigh.withAlpha(70));
  }

  void _arcos(Canvas c, Rect r) {
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (int i = 0; i < 3; i++) {
      final double ancho = r.width * (0.42 + i * 0.16);
      final double alto = r.height * (0.5 + i * 0.12);
      final double arriba = r.height * 0.28 - alto * 0.5;
      final Rect arco = Rect.fromCenter(
        center: Offset(r.width * 0.5, arriba + alto * 0.5),
        width: ancho,
        height: alto,
      );
      p.color = (i.isEven ? tokens.secondary : tokens.accent).withAlpha(22);
      c.drawArc(arco, math.pi, math.pi, false, p);
    }
  }

  void _niebla(Canvas c, Rect r) {
    final Rect abajo = Rect.fromLTWH(0, r.height * 0.55, r.width, r.height * 0.45);
    c.drawRect(
      abajo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[tokens.secondary.withAlpha(0), tokens.secondary.withAlpha(34)],
        ).createShader(abajo),
    );
  }

  void _letterbox(Canvas c, Rect r) {
    final double alto = r.height * 0.055;
    final Paint negro = Paint()..color = const Color(0xFF000000);
    c.drawRect(Rect.fromLTWH(0, 0, r.width, alto), negro);
    c.drawRect(Rect.fromLTWH(0, r.height - alto, r.width, alto), negro);
  }

  void _grano(Canvas c, Rect r) {
    final math.Random azar = math.Random(7);
    final Paint p = Paint();
    for (int i = 0; i < 420; i++) {
      final Offset punto = Offset(azar.nextDouble() * r.width, azar.nextDouble() * r.height);
      p.color = Colors.white.withAlpha(azar.nextInt(10));
      c.drawCircle(punto, azar.nextDouble() * 1.4, p);
    }
    final Rect vineta = Rect.fromCenter(center: r.center, width: r.width * 1.25, height: r.height * 1.25);
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.transparent, Colors.black.withAlpha(120)],
          stops: const <double>[0.62, 1],
        ).createShader(vineta),
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.t != t || old.tokens != tokens;
}