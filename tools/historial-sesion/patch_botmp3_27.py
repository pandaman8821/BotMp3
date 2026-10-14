"""BotMp3 v1.4.4 — el ranking ya no cuenta reproducciones falsas.

Fallo: al pulsar «Reproducción aleatoria de todo», la lista cargaba la cola con
`autoPlay: false` y `_loadQueueIntoPlayer` llamaba a `onSongStarted` de todos
modos, así que la PRIMERA canción de la cola sumaba una reproducción (y en
ocasiones dos: también la contaba el cambio de índice de la sesión).

Arreglo:
  · La reproducción se cuenta **solo cuando el audio suena de verdad**, una vez
    por canción, mediante `playerStateStream` + deduplicación.
  · Nuevo botón en el ranking para **reiniciar las estadísticas** (los datos ya
    inflados no se pueden reconstruir, así que se pueden empezar de cero).
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


PLAYER = "lib/services/player_service.dart"

# 1) Campo para deduplicar
patch(PLAYER,
      r"  void _registrarError\(String mensaje\) \{",
      "  /// Última canción cuya reproducción ya se contó para el ranking\n"
      "  /// (evita duplicados al preparar colas o al cambiar de pista).\n"
      "  String? _ultimaReproduccionRegistrada;\n\n"
      "  /// Cuenta una reproducción **solo si el audio está sonando**, una vez por\n"
      "  /// canción. Así, cargar una cola o pulsar «aleatorio» sin arrancar no\n"
      "  /// infla el ranking.\n"
      "  void _registrarInicioDeReproduccion() {\n"
      "    if (!_player.playing) return;\n"
      "    final int indice = _player.currentIndex ?? _currentIndex;\n"
      "    if (indice < 0 || indice >= _queue.length) return;\n"
      "    final Song cancion = _queue[indice];\n"
      "    if (_ultimaReproduccionRegistrada == cancion.id) return;\n"
      "    _ultimaReproduccionRegistrada = cancion.id;\n"
      "    if (_currentIndex != indice) {\n"
      "      _currentIndex = indice;\n"
      "      _playOrderIndex = _playOrder.indexOf(indice);\n"
      "      if (_playOrderIndex < 0) _playOrderIndex = 0;\n"
      "      currentSong.value = cancion;\n"
      "    }\n"
      "    onSongStarted?.call(cancion);\n"
      "  }\n\n"
      "  void _registrarError(String mensaje) {",
      label="registro con deduplicación")

# 2) Contar al empezar a sonar de verdad
patch(PLAYER,
      r"    _player\.playerStateStream\.listen\(\(PlayerState state\) \{\n"
      r"      _syncWakelock\(state\.playing\);\n"
      r"    \}\);",
      "    _player.playerStateStream.listen((PlayerState state) {\n"
      "      _syncWakelock(state.playing);\n"
      "      // Se cuenta la reproducción cuando el audio suena de verdad.\n"
      "      if (state.playing) _registrarInicioDeReproduccion();\n"
      "    });",
      label="contar solo al sonar")

# 3) Cargar la cola ya no cuenta nada
patch(PLAYER,
      r"      if \(autoPlay\) unawaited\(_player\.play\(\)\);\n"
      r"      onSongStarted\?\.call\(_queue\[start\]\);\n"
      r"    \} catch \(error\) \{\n"
      r"      debugPrint\('No se pudo cargar la cola: \$error'\);",
      "      // No se cuenta aquí: lo hará el estado del reproductor cuando suene.\n"
      "      if (autoPlay) unawaited(_player.play());\n"
      "    } catch (error) {\n"
      "      debugPrint('No se pudo cargar la cola: $error');",
      label="cargar cola sin contar")

# 4) Cambio de pista de la sesión
patch(PLAYER,
      r"    currentSong\.value = _queue\[sequenceIndex\];\n"
      r"    onSongStarted\?\.call\(_queue\[sequenceIndex\]\);\n"
      r"  \}",
      "    currentSong.value = _queue[sequenceIndex];\n"
      "    _registrarInicioDeReproduccion();\n"
      "  }",
      label="cambio de pista con recuento seguro")

# 5) Salto dentro de la cola ya cargada
patch(PLAYER,
      r"        await _player\.seek\(Duration\.zero, index: queueIndex\);\n"
      r"        if \(autoPlay && !_player\.playing\) unawaited\(_player\.play\(\)\);\n"
      r"        onSongStarted\?\.call\(song\);\n"
      r"        return;",
      "        await _player.seek(Duration.zero, index: queueIndex);\n"
      "        if (autoPlay && !_player.playing) {\n"
      "          unawaited(_player.play());\n"
      "        } else {\n"
      "          // Si ya estaba sonando, el cambio de pista no emite un nuevo\n"
      "          // «reproduciendo»: se cuenta aquí, una vez por canción.\n"
      "          _registrarInicioDeReproduccion();\n"
      "        }\n"
      "        return;",
      label="salto dentro de la cola")

# 6) Reiniciar estadísticas (servicio)
patch("lib/services/library_service.dart",
      r"  /// Canciones ordenadas por número de reproducciones\.",
      "  /// Borra el historial y reinicia los contadores de reproducciones.\n"
      "  Future<void> resetPlayStats() async {\n"
      "    for (int i = 0; i < _songs.length; i++) {\n"
      "      _songs[i] = _songs[i].copyWith(playCount: 0, lastPlayedAt: null);\n"
      "    }\n"
      "    _playLog.clear();\n"
      "    _historialCargado = true;\n"
      "    await _persist();\n"
      "    await _persistirHistorial();\n"
      "  }\n\n"
      "  /// Canciones ordenadas por número de reproducciones.",
      label="reset de estadísticas")

# 7) Proveedor: acceso directo
patch("lib/providers/library_provider.dart",
      r"  Future<void> registerPlay\(String id\) async \{",
      "  /// Reinicia el ranking (contadores e historial).\n"
      "  Future<void> resetPlayStats() async {\n"
      "    await _service.resetPlayStats();\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  Future<void> registerPlay(String id) async {",
      label="reset en el proveedor")

# 8) Botón en la pantalla de ranking
patch("lib/screens/ranking_screen.dart",
      r"        actions: <Widget>\[\n          if \(canciones\.isNotEmpty\)",
      "        actions: <Widget>[\n"
      "          IconButton(\n"
      "            tooltip: 'Reiniciar estadísticas',\n"
      "            icon: const Icon(Icons.restart_alt),\n"
      "            onPressed: () async {\n"
      "              final bool? confirmar = await showDialog<bool>(\n"
      "                context: context,\n"
      "                builder: (BuildContext dialogContext) => AlertDialog(\n"
      "                  title: const Text('Reiniciar el ranking'),\n"
      "                  content: const Text(\n"
      "                    'Se pondrán a cero las reproducciones de todas las canciones '\n"
      "                    'y el historial. Útil si el contador se infló en versiones '\n"
      "                    'anteriores.\\n\\nEsta acción no se puede deshacer.',\n"
      "                  ),\n"
      "                  actions: <Widget>[\n"
      "                    TextButton(\n"
      "                      onPressed: () => Navigator.of(dialogContext).pop(false),\n"
      "                      child: const Text('Cancelar'),\n"
      "                    ),\n"
      "                    FilledButton(\n"
      "                      onPressed: () => Navigator.of(dialogContext).pop(true),\n"
      "                      child: const Text('Reiniciar'),\n"
      "                    ),\n"
      "                  ],\n"
      "                ),\n"
      "              );\n"
      "              if (confirmar != true || !context.mounted) return;\n"
      "              await context.read<LibraryProvider>().resetPlayStats();\n"
      "              if (!context.mounted) return;\n"
      "              ScaffoldMessenger.of(context).showSnackBar(\n"
      "                const SnackBar(content: Text('Ranking reiniciado')),\n"
      "              );\n"
      "            },\n"
      "          ),\n"
      "          if (canciones.isNotEmpty)",
      label="botón de reinicio en el ranking")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
