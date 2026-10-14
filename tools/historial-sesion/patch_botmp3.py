"""Parches de compatibilidad de BotMp3 con Flutter 3.47 / just_audio 0.10.6.

Corrige los errores de compilación detectados en el primer build real:
  1. Song.lastPlayedAt no se inicializaba en el constructor.
  2. `RepeatMode` ambiguo (mi enum vs. el de Flutter y el de just_audio).
  3. `SingleChildWidget` no es un tipo visible en app.dart.
  4. `CupertinoPageTransitionsBuilder` ya no existe en theme.dart.
  5. just_audio 0.10 eliminó `AudioPlayer.setAudioContext`.
  6. LibraryProvider no exponía `playlistById`.
  7. Falta el import de core/constants.dart (extensión AiProviderInfo.label).
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")

changes: list[str] = []
problems: list[str] = []


def patch(rel_path: str, pattern: str, replacement: str, *, count: int = 1,
          required: bool = True, flags: int = 0) -> None:
    path = os.path.join(PROJ, rel_path)
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    new_text, replaced = re.subn(pattern, replacement, text, count=count, flags=flags)
    if replaced:
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(new_text)
        changes.append(f"{rel_path}: {replaced} cambio(s)")
    elif required:
        problems.append(f"{rel_path}: no se encontró el patrón -> {pattern[:60]}")


# 1) Song: inicializar el campo lastPlayedAt
patch(
    "lib/models/song.dart",
    r"(\n\s*)DateTime\? lastPlayedAt,(\r?\n\s*this\.isFavorite = false,)",
    r"\1this.lastPlayedAt,\2",
)

# 2) RepeatMode ambiguo: ocultar el de Flutter y el de just_audio
patch(
    "lib/providers/settings_provider.dart",
    r"import 'package:flutter/material\.dart';",
    "import 'package:flutter/material.dart' hide RepeatMode;",
)
patch(
    "lib/screens/player_screen.dart",
    r"import 'package:flutter/material\.dart';",
    "import 'package:flutter/material.dart' hide RepeatMode;",
)
patch(
    "lib/services/player_service.dart",
    r"import 'package:just_audio/just_audio\.dart';",
    "import 'package:just_audio/just_audio.dart' hide RepeatMode;",
)
patch(
    "lib/providers/player_provider.dart",
    r"import 'package:just_audio/just_audio\.dart';",
    "import 'package:just_audio/just_audio.dart' hide RepeatMode;",
)

# 3) app.dart: tipo inferido para la lista de providers
patch(
    "lib/app.dart",
    r"providers: <SingleChildWidget>\[",
    "providers: [",
)

# 4) theme.dart: la transición iOS de Cupertino ya no está disponible
patch(
    "lib/core/theme.dart",
    r"\n\s*TargetPlatform\.iOS: CupertinoPageTransitionsBuilder\(\),",
    "",
)

# 5) just_audio 0.10: setAudioContext ya no existe (la sesión se configura sola)
patch(
    "lib/services/player_service.dart",
    r"\n\s*// La sesión de audio se configura una sola vez \(música, ducking correcto\)\."
    r".*?_player\.setAudioContext\(.*?\n\s*\);\n",
    "\n",
    flags=re.DOTALL,
)

# 6) LibraryProvider: exponer playlistById
patch(
    "lib/providers/library_provider.dart",
    r"(\n\s*/// Canciones más escuchadas)",
    "\n  /// Lista por id (usada por la pantalla de detalle).\n"
    "  Playlist? playlistById(String id) => _service.playlistById(id);\n\\1",
)

# 7) player_screen.dart: importar constants (extensión AiProviderInfo.label)
patch(
    "lib/screens/player_screen.dart",
    r"import '\.\./core/formatters\.dart';",
    "import '../core/constants.dart';\nimport '../core/formatters.dart';",
)

print("CAMBIOS:")
for item in changes:
    print("  -", item)
if problems:
    print("PROBLEMAS:")
    for item in problems:
        print("  !", item)
    sys.exit(1)
print("Parcheo completado.")
