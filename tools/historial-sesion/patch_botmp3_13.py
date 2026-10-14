"""BotMp3 v1.3.2 — transición visible y verificable en TODAS las pestañas.

  1. El indicador de la barra se identifica con una clave (para poder medirlo).
  2. Duración proporcional a la distancia recorrida: antes, saltar de la primera
     a la última pestaña recorría 4 huecos en el mismo tiempo que 1, y el ojo lo
     percibía como un salto sin animación.
  3. Transición de contenido más marcada: aparece desde transparente con
     deslizamiento y un leve aumento de escala, en todas las pestañas.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")

ok: list[str] = []
fail: list[str] = []


def read(rel: str) -> str:
    with open(os.path.join(PROJ, rel), "r", encoding="utf-8") as handle:
        return handle.read()


def write(rel: str, text: str) -> None:
    with open(os.path.join(PROJ, rel), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def patch(rel: str, pattern: str, replacement: str, *, flags: int = 0,
          label: str = "") -> None:
    text = read(rel)
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


# ================================ 1. Clave del indicador (medible en los tests)
patch("lib/widgets/glass.dart",
      r"                    Positioned\(\n"
      r"                      left: itemWidth \* _controller\.value,",
      "                    Positioned(\n"
      "                      key: const ValueKey<String>('glass-nav-indicator'),\n"
      "                      left: itemWidth * _controller.value,",
      label="clave del indicador")

# ================================ 2. Duración según la distancia recorrida
patch("lib/widgets/glass.dart",
      r"    if \(oldWidget\.index != widget\.index\) \{\n"
      r"      _controller\n"
      r"          \.animateTo\(\n"
      r"            widget\.index\.toDouble\(\),\n"
      r"            duration: const Duration\(milliseconds: 520\),\n"
      r"            curve: Curves\.easeOutBack,\n"
      r"          \)\n"
      r"          \.whenComplete\(\(\) \{\n"
      r"        // Garantiza que el indicador quede exactamente en su pestaña\.\n"
      r"        if \(mounted\) _controller\.value = widget\.index\.toDouble\(\);\n"
      r"      \}\);\n"
      r"    \}",
      "    if (oldWidget.index != widget.index) {\n"
      "      _animateToIndex(widget.index);\n"
      "    }",
      label="didUpdateWidget usa la animación por distancia")

patch("lib/widgets/glass.dart",
      r"  @override\n  void dispose\(\) \{\n    _controller\.dispose\(\);",
      "  /// Anima el indicador con una duración proporcional a la distancia:\n"
      "  /// saltar una pestaña es rápido; saltar cuatro se ve como un recorrido\n"
      "  /// continuo en lugar de un salto instantáneo.\n"
      "  void _animateToIndex(int index) {\n"
      "    final double distance = (index - _controller.value).abs();\n"
      "    final int milliseconds =\n"
      "        (320 + (120 * distance)).round().clamp(320, 820);\n"
      "    _controller\n"
      "        .animateTo(\n"
      "          index.toDouble(),\n"
      "          duration: Duration(milliseconds: milliseconds),\n"
      "          curve: Curves.easeOutBack,\n"
      "        )\n"
      "        .whenComplete(() {\n"
      "      // Garantiza que el indicador quede exactamente en su pestaña.\n"
      "      if (mounted) _controller.value = index.toDouble();\n"
      "    });\n"
      "  }\n\n"
      "  @override\n  void dispose() {\n    _controller.dispose();",
      label="método de animación por distancia")

# ================================ 3. Transición de contenido más visible
patch("lib/screens/home_shell.dart",
      r"          final double t = Curves\.easeOutCubic\.transform\(_tabTransition\.value\);\n"
      r"          return Opacity\(\n"
      r"            opacity: 0\.30 \+ 0\.70 \* t,\n"
      r"            child: Transform\.translate\(\n"
      r"              offset: Offset\(0, 14 \* \(1 - t\)\),\n"
      r"              child: child,\n"
      r"            \),\n"
      r"          \);",
      "          final double t = Curves.easeOutCubic.transform(_tabTransition.value);\n"
      "          // La pestaña entra desde transparente, deslizándose y creciendo\n"
      "          // ligeramente: el cambio se percibe en TODAS las pestañas.\n"
      "          return Opacity(\n"
      "            opacity: t,\n"
      "            child: Transform.translate(\n"
      "              offset: Offset(0, 26 * (1 - t)),\n"
      "              child: Transform.scale(\n"
      "                scale: 0.965 + 0.035 * t,\n"
      "                child: child,\n"
      "              ),\n"
      "            ),\n"
      "          );",
      label="transición de contenido marcada")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
