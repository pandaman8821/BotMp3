"""Últimos dos arreglos: interpolación duplicada e import de constantes."""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
ok: list[str] = []


def patch(rel: str, pattern: str, replacement: str, *, label: str = "") -> None:
    path = os.path.join(PROJ, rel)
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1)
    if n:
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(new)
        ok.append(f"{rel}: {label}")
    else:
        ok.append(f"{rel}: SIN CAMBIOS (posiblemente ya corregido) -> {label}")


patch("lib/services/ai/action_executor.dart",
      r"\$\{\$\{\(percent / 100\)\.toStringAsFixed\(2\)\}x\}",
      "${(percent / 100).toStringAsFixed(2)}x",
      label="interpolación de velocidad")

patch("lib/services/ai/ai_orchestrator.dart",
      r"import '\.\./\.\./core/formatters\.dart';\n",
      "import '../../core/constants.dart';\nimport '../../core/formatters.dart';\n",
      label="import Constants")

print("APLICADOS:")
for item in ok:
    print("  +", item)
sys.exit(0)
