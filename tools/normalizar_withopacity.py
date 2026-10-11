"""
BotMp3 - compatibilidad de la API de color entre versiones de Flutter.

`Color.withOpacity` está obsoleto en Flutter 3.27+ y puede desaparecer en
versiones nuevas, mientras que `Color.withValues` no existe en Flutter 3.24.
`Color.withAlpha` funciona en TODAS las versiones, así que se normaliza el código
a esa forma.

Uso:
    python tools/normalizar_withopacity.py
"""

from __future__ import annotations

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "lib")
PATTERN = re.compile(r"\.withOpacity\(\s*([0-9]*\.?[0-9]+)\s*\)")


def convert(path: str) -> int:
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    new_text, count = PATTERN.subn(
        lambda match: f".withAlpha((({match.group(1)}) * 255).round())", text
    )
    if count:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(new_text)
    return count


def main() -> int:
    total = 0
    for base, _dirs, names in os.walk(LIB):
        for name in names:
            if name.endswith(".dart"):
                path = os.path.join(base, name)
                count = convert(path)
                if count:
                    print(f"  {os.path.relpath(path, ROOT)}: {count} cambios")
                    total += count
    print(f"Total: {total} llamadas normalizadas a withAlpha")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
