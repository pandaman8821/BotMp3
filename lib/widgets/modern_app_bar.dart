import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../providers/player_provider.dart';
import 'robot_head.dart';

/// Titulo de la app con degradado de marca (verde, cian y violeta).
///
/// Ocupa poco ancho y siempre se ve completo: no se corta con "...".
class TituloBotMp3 extends StatelessWidget {
  const TituloBotMp3({super.key, this.tamano = 24, this.robot = true});

  final double tamano;

  /// Muestra la cabeza de robot animada delante del nombre.
  final bool robot;

  @override
  Widget build(BuildContext context) {
    final Widget nombre = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect limites) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[AppColors.green, AppColors.aiCyan, AppColors.aiViolet],
      ).createShader(limites),
      child: Text(
        'BotMp3',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: tamano,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );
    if (!robot) return nombre;
    // Solo se reconstruye el robot cuando cambia "suena / no suena".
    final bool sonando = context.select<PlayerProvider, bool>((PlayerProvider p) => p.playing);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CabezaRobot(tamano: tamano * 1.35, sonando: sonando),
        SizedBox(width: tamano * 0.3),
        nombre,
      ],
    );
  }
}

/// Animación propia de cada icono al tocarlo.
enum AnimacionIcono {
  /// Crece y vuelve con rebote.
  rebote,

  /// Da media vuelta (orden, aleatorio).
  giro,

  /// Avanza y vuelve (coche).
  deslizar,

  /// Late dos veces (filtros).
  pulso,

  /// Pega un salto (trofeo del ranking).
  saltar,
}

/// Botón de acción moderno: píldora redonda de cristal, entrada escalonada al
/// abrir la pantalla, una animación propia al tocarlo y una onda de luz.
class BotonAccion extends StatefulWidget {
  const BotonAccion({
    super.key,
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.activo = false,
    this.tamano = 22,
    this.anchoAlto = 42,
    this.animacion = AnimacionIcono.rebote,
    this.orden = 0,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;
  final bool activo;
  final double tamano;
  final double anchoAlto;
  final AnimacionIcono animacion;

  /// Posición en la fila: retrasa un poco su entrada (efecto cascada).
  final int orden;

  @override
  State<BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<BotonAccion> with SingleTickerProviderStateMixin {
  bool _pulsado = false;
  late final AnimationController _toque =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 560));

  @override
  void dispose() {
    _toque.dispose();
    super.dispose();
  }

  void _cambiar(bool valor) {
    if (_pulsado == valor) return;
    setState(() => _pulsado = valor);
  }

  void _tocar() {
    Hapticos.toque();
    if (!Motion.reducir) _toque.forward(from: 0);
    widget.onPressed();
  }

  /// Transforma el icono según su animación (t va de 0 a 1 tras el toque).
  Widget _animar(double t, Widget icono) {
    if (t == 0 || t == 1) return icono;
    switch (widget.animacion) {
      case AnimacionIcono.rebote:
        return Transform.scale(scale: 1 + 0.32 * math.sin(math.pi * t) * (1 - t * 0.5), child: icono);
      case AnimacionIcono.giro:
        return Transform.rotate(angle: Curves.easeOutBack.transform(t) * math.pi, child: icono);
      case AnimacionIcono.deslizar:
        return Transform.translate(offset: Offset(7 * math.sin(math.pi * t), 0), child: icono);
      case AnimacionIcono.pulso:
        return Transform.scale(scale: 1 + 0.22 * math.sin(2 * math.pi * t).abs() * (1 - t), child: icono);
      case AnimacionIcono.saltar:
        return Transform.translate(
          offset: Offset(0, -7 * math.sin(math.pi * t)),
          child: Transform.rotate(angle: 0.25 * math.sin(2 * math.pi * t) * (1 - t), child: icono),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme esquema = Theme.of(context).colorScheme;
    final Color color = widget.activo ? AppColors.green : esquema.onSurface;
    final double lado = widget.anchoAlto;

    final Widget boton = AnimatedScale(
      scale: _pulsado ? 0.86 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: Motion.ajustar(const Duration(milliseconds: 220)),
        width: lado,
        height: lado,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Cristal: relleno muy suave y borde de luz; el activo se tiñe.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.activo
                ? <Color>[AppColors.green.withAlpha(80), AppColors.aiCyan.withAlpha(36)]
                : <Color>[esquema.onSurface.withAlpha(_pulsado ? 40 : 20), esquema.onSurface.withAlpha(6)],
          ),
          border: Border.all(
            color: widget.activo ? AppColors.green.withAlpha(150) : esquema.onSurface.withAlpha(34),
          ),
          boxShadow: widget.activo
              ? <BoxShadow>[BoxShadow(color: AppColors.green.withAlpha(60), blurRadius: 10)]
              : null,
        ),
        child: AnimatedBuilder(
          animation: _toque,
          builder: (BuildContext context, Widget? icono) {
            final double t = _toque.value;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                // Onda de luz que se expande al tocar.
                if (t > 0 && t < 1)
                  IgnorePointer(
                    child: Container(
                      width: lado * (0.6 + 0.8 * t),
                      height: lado * (0.6 + 0.8 * t),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.aiCyan.withAlpha((160 * (1 - t)).round()),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                _animar(t, icono!),
              ],
            );
          },
          child: Icon(widget.icono, size: widget.tamano, color: color),
        ),
      ),
    );

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => _cambiar(true),
          onTapCancel: () => _cambiar(false),
          onTapUp: (_) => _cambiar(false),
          onTap: _tocar,
          // Entrada en cascada: cada botón aparece un poco después del anterior.
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: Motion.reducir ? 1 : 0, end: 1),
            duration: Motion.ajustar(Duration(milliseconds: 360 + 70 * widget.orden)),
            curve: Curves.easeOutBack,
            builder: (BuildContext context, double v, Widget? hijo) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - v)),
                child: Transform.scale(scale: 0.6 + 0.4 * v, child: hijo),
              ),
            ),
            child: boton,
          ),
        ),
      ),
    );
  }
}

/// Boton de menu (tres puntos) con el mismo estilo animado.
class BotonMenu extends StatefulWidget {
  const BotonMenu({super.key, required this.items, required this.tooltip, this.onSelected});

  final List<PopupMenuEntry<String>> items;
  final String tooltip;
  final ValueChanged<String>? onSelected;

  @override
  State<BotonMenu> createState() => _BotonMenuState();
}

class _BotonMenuState extends State<BotonMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: widget.tooltip,
      onSelected: widget.onSelected,
      icon: const Icon(Icons.more_horiz_rounded, size: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.darkSurface,
      itemBuilder: (BuildContext context) => widget.items,
    );
  }
}

/// Titulo de las demas pestanas: mismo caracter que el logo de BotMp3 pero
/// con el nombre de la seccion y un subrayado degradado sutil.
class TituloPantalla extends StatelessWidget {
  const TituloPantalla({super.key, required this.text, this.tamano = 21});

  final String text;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tamano,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: <Color>[AppColors.green, AppColors.aiCyan],
            ),
          ),
        ),
      ],
    );
  }
}
