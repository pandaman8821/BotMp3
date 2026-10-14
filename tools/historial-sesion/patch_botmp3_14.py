"""BotMp3 v1.3.2 — reescribe el indicador de la barra con AnimatedPositioned.

El test de widgets reprodujo el fallo del usuario: el indicador solo animaba en
el PRIMER cambio de pestaña (0→1) y se quedaba quieto en los siguientes
(1→2, 2→3…), porque la animación dependía de un `AnimationController` con
`didUpdateWidget`.

Solución: el indicador se posiciona directamente con `widget.index` mediante
`AnimatedPositioned`, que interpola en cada cambio de índice sin controladores
ni callbacks: imposible que se quede sin animar.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")

REL = "lib/widgets/glass.dart"

nuevo = """class _GlassNavBarState extends State<GlassNavBar> {
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
          return SizedBox(
            height: 58,
            child: Stack(
              children: <Widget>[
                // Indicador líquido. `AnimatedPositioned` interpola en CADA
                // cambio de pestaña: no depende de controladores ni callbacks,
                // así que el deslizamiento ocurre siempre.
                AnimatedPositioned(
                  key: const ValueKey<String>('glass-nav-indicator'),
                  duration: Duration(milliseconds: _durationMs),
                  curve: Curves.easeOutBack,
                  left: itemWidth * widget.index,
                  top: 3,
                  bottom: 3,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.aiViolet.withAlpha(120),
                            AppColors.aiViolet.withAlpha(48),
                          ],
                        ),
                        border: Border.all(color: Colors.white.withAlpha(64)),
                      ),
                    ),
                  ),
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
          Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: 23,
            color: color,
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

/// Tarjeta de cristal con título opcional."""


def main() -> int:
    path = os.path.join(PROJ, REL)
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()

    pattern = re.compile(
        r"class _GlassNavBarState.*?\n\n/// Tarjeta de cristal con título opcional\.",
        re.DOTALL,
    )
    nuevo_texto, n = pattern.subn(lambda _m: nuevo, text, count=1)
    if not n:
        print("FALLO: no se encontró el bloque de la barra de navegación")
        return 1

    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(nuevo_texto)

    print("APLICADO: lib/widgets/glass.dart — indicador con AnimatedPositioned")
    return 0


sys.exit(main())
