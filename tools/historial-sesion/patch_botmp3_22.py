"""BotMp3 v1.4.1 — arregla la tarjeta de tendencias de la pestaña IA.

La tarjeta usaba un `Row` con `Expanded` dentro de la superficie de cristal; en
ese contexto el `Expanded` se quedaba sin ancho y el texto se partía letra a
letra, estirando la tarjeta hasta ocupar la pantalla.

Solución: el acceso a Tendencias pasa a ser un **chip** en la barra de acciones
rápidas (donde ya hay otros), que se dimensiona por contenido y no puede romper
el layout de la pantalla.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
REL = "lib/screens/ai_screen.dart"

ok: list[str] = []
fail: list[str] = []


def read() -> str:
    with open(os.path.join(PROJ, REL), "r", encoding="utf-8") as handle:
        return handle.read()


def write(text: str) -> None:
    with open(os.path.join(PROJ, REL), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def patch(pattern: str, replacement: str, *, flags: int = 0, label: str = "") -> None:
    text = read()
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1, flags=flags)
    if n:
        write(new)
        ok.append(label)
    else:
        fail.append(f"NO ENCONTRADO -> {label}")


# 1) Quitar la tarjeta del cuerpo de la pantalla.
patch(
    r"          _trendsCard\(context\),\n          _executedActions\(ai\),",
    "          _executedActions(ai),",
    label="quitar la tarjeta rota de la pantalla",
)

# 2) Eliminar el método de la tarjeta (ya no se usa).
patch(
    r"  /// Acceso a las tendencias de internet \(con opción de avisos\)\.\n"
    r"  Widget _trendsCard\(BuildContext context\) \{.*?\n  \}\n\n"
    r"  /// Chips con las últimas órdenes que la IA ejecutó sobre la app\.",
    "  /// Chips con las últimas órdenes que la IA ejecutó sobre la app.",
    flags=re.DOTALL,
    label="eliminar el método de la tarjeta",
)

# 3) Añadir el chip de Tendencias a las acciones rápidas.
patch(
    r"        children: <Widget>\[\n          _action\('Recomiéndame', Icons\.auto_awesome,",
    "        children: <Widget>[\n"
    "          // Acceso directo a las canciones en tendencia.\n"
    "          _action('Tendencias 🔥', Icons.local_fire_department, () async {\n"
    "            await Navigator.of(context).push(\n"
    "              MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),\n"
    "            );\n"
    "          }),\n"
    "          _action('Recomiéndame', Icons.auto_awesome,",
    label="chip de tendencias en las acciones rápidas",
)

# 4) Quitar el import de cristal si ya no se usa en este fichero.
texto = read()
if "GlassCard(" not in texto and "GlassSurface(" not in texto and "GlassChip(" not in texto:
    patch(
        r"import '\.\./widgets/glass\.dart';\n",
        "",
        label="quitar import de cristal sin uso",
    )

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
