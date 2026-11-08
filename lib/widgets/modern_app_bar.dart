import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Titulo de la app con degradado de marca (verde, cian y violeta).
///
/// Ocupa poco ancho y siempre se ve completo: no se corta con "...".
class TituloBotMp3 extends StatelessWidget {
  const TituloBotMp3({super.key, this.tamano = 24});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
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
  }
}

/// Boton de accion animado: se hunde al pulsarlo y deja un halo suave.
///
/// Da sensacion moderna sin cambiar ninguna funcionalidad.
class BotonAccion extends StatefulWidget {
  const BotonAccion({
    super.key,
    required this.icono,
    required this.tooltip,
    required this.onPressed,
    this.activo = false,
    this.tamano = 22,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onPressed;
  final bool activo;
  final double tamano;

  @override
  State<BotonAccion> createState() => _BotonAccionState();
}

class _BotonAccionState extends State<BotonAccion> {
  bool _pulsado = false;

  void _cambiar(bool valor) {
    if (_pulsado == valor) return;
    setState(() => _pulsado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.activo ? AppColors.green : AppColors.darkText;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => _cambiar(true),
          onTapCancel: () => _cambiar(false),
          onTapUp: (_) => _cambiar(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pulsado ? 0.82 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pulsado
                    ? color.withAlpha(38)
                    : (widget.activo ? color.withAlpha(22) : Colors.transparent),
                border: Border.all(
                  color: widget.activo ? color.withAlpha(90) : Colors.transparent,
                ),
              ),
              child: Icon(widget.icono, size: widget.tamano, color: color),
            ),
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