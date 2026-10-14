"""BotMp3 v1.4.2 — arregla los controles de la pantalla de bloqueo (2ª parte).

Causas probables corregidas:
  1. `androidStopForegroundOnPause: true` hacía que el servicio dejase de ser
     primer plano al pausar: en varios fabricantes (Xiaomi/HyperOS) el sistema
     mata entonces el servicio y TODOS los botones dejan de responder. Ahora el
     servicio permanece vivo mientras haya cola.
  2. `MetadataService.readDurationMs` creaba un SEGUNDO `AudioPlayer`, algo que
     `just_audio_background` no admite («single AudioPlayer instance»): al
     crearse, el plugin pasaba a controlar ese reproductor temporal y los
     controles quedaban conectados a un reproductor ya liberado.
  3. La cola ahora se sanea (fuera entradas sin ruta válida) y se registran los
     últimos errores de reproducción para poder diagnosticarlos en la app.
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
          label: str = "", skip_if: str = "") -> None:
    text = read(rel)
    if skip_if and skip_if in text:
        ok.append(f"{rel}: {label} (ya aplicado)")
        return
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


# =============== 1. El servicio en primer plano NO se detiene al pausar
patch("lib/main.dart",
      r"    androidStopForegroundOnPause: true,",
      "    // Se mantiene en primer plano al pausar: si el servicio baja de\n"
      "    // prioridad, HyperOS/MIUI lo mata y los controles dejan de responder.\n"
      "    androidStopForegroundOnPause: false,",
      label="servicio vivo al pausar")

# =============== 2. Un solo reproductor (regla del plugin)
patch("lib/services/metadata_service.dart",
      r"  /// Duración real del audio \(just_audio usa el decodificador del sistema\)\.\n"
      r"  Future<int> readDurationMs\(String path\) async \{.*?\n  \}",
      "  /// Duración del audio.\n"
      "  ///\n"
      "  /// **Importante:** no se crea un `AudioPlayer` temporal aquí.\n"
      "  /// `just_audio_background` solo admite UN reproductor por app; un segundo\n"
      "  /// reproductor (aunque sea temporal) pasa a ser el que controla la sesión\n"
      "  /// multimedia y los botones de la pantalla de bloqueo dejan de responder.\n"
      "  /// La duración real la informa el propio reproductor al empezar a sonar.\n"
      "  Future<int> readDurationMs(String path) async => 0;",
      flags=re.DOTALL,
      label="quitar reproductor temporal")

# =============== 3. Errores registrados + fuentes saneadas
patch("lib/services/player_service.dart",
      r"  /// La biblioteca registra aquí la reproducción para las estadísticas\.\n"
      r"  void Function\(Song song\)\? onSongStarted;",
      "  /// La biblioteca registra aquí la reproducción para las estadísticas.\n"
      "  void Function(Song song)? onSongStarted;\n\n"
      "  /// Últimos errores de reproducción (se muestran en el diagnóstico).\n"
      "  final List<String> ultimosErrores = <String>[];\n\n"
      "  void _registrarError(String mensaje) {\n"
      "    ultimosErrores.insert(0, mensaje);\n"
      "    if (ultimosErrores.length > 6) ultimosErrores.removeLast();\n"
      "  }",
      label="registro de errores")

patch("lib/services/player_service.dart",
      r"  List<AudioSource> _buildSources\(\) =>\n"
      r"      _queue\.map\(\(Song song\) => _sourceFor\(song\)\)\.toList\(\);",
      "  List<AudioSource> _buildSources() => _queue\n"
      "      // Se descartan entradas sin fuente utilizable: una sola mala evitaba\n"
      "      // que se cargase la cola entera.\n"
      "      .map((Song song) => song.path.trim())\n"
      "      .where((String path) => path.isNotEmpty)\n"
      "      .map((String path) => _sourceFor(_queue.firstWhere((Song song) => song.path == path)))\n"
      "      .toList();",
      label="saneado de fuentes")

patch("lib/services/player_service.dart",
      r"      debugPrint\('No se pudo cargar la cola: \$error'\);",
      "      debugPrint('No se pudo cargar la cola: $error');\n"
      "      _registrarError('Cola: $error');",
      label="registrar error de cola")

patch("lib/services/player_service.dart",
      r"        debugPrint\('No se pudo reproducir \$\{_queue\[start\]\.path\}: \$innerError'\);",
      "        debugPrint('No se pudo reproducir ${_queue[start].path}: $innerError');\n"
      "        _registrarError('Cancion: $innerError');",
      label="registrar error de canción")

# =============== 4. Diagnóstico en Ajustes
patch("lib/screens/settings_screen.dart",
      r"          ListTile\(\n            leading: const Icon\(Icons\.leaderboard_outlined\),",
      "          ListTile(\n"
      "            leading: const Icon(Icons.health_and_safety_outlined),\n"
      "            title: const Text('Diagnóstico de reproducción'),\n"
      "            subtitle: const Text(\n"
      "              'Comprueba por qué no responden los controles en el bloqueo.',\n"
      "            ),\n"
      "            trailing: const Icon(Icons.chevron_right),\n"
      "            onTap: () => Navigator.of(context).push(\n"
      "              MaterialPageRoute<void>(builder: (_) => const DiagnosticsScreen()),\n"
      "            ),\n"
      "          ),\n"
      "          ListTile(\n            leading: const Icon(Icons.leaderboard_outlined),",
      label="entrada de diagnóstico")

settings_text = read("lib/screens/settings_screen.dart")
if "diagnostics_screen.dart" not in settings_text:
    patch("lib/screens/settings_screen.dart",
          r"(import 'ranking_screen\.dart';)",
          r"\1\nimport 'diagnostics_screen.dart';",
          label="import del diagnóstico")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
