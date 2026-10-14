"""BotMp3 v1.3.1 — corrige la reproducción al tocar y el efecto entre pestañas.

Bug 1 (reproducción): la lista de canciones pasaba SIEMPRE `onSelected`, y el
toque del mosaico lo interpretaba como selección múltiple: la canción no sonaba
hasta pulsar «Reproducir selección». Ahora tocar reproduce al instante y la
selección múltiple se activa con una pulsación larga.
Además `setQueue` arrancaba siempre por la PRIMERA canción de la cola en vez de
por la elegida.

Bug 2 (transición): al cambiar de pestaña el contenido saltaba sin animación
(IndexedStack) y el indicador de la barra no se fijaba con exactitud. Ahora hay
una transición visible en TODAS las pestañas y el indicador siempre termina en
su sitio.
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


# ============================================ 1. Tocar una canción = reproducir
patch("lib/widgets/song_tile.dart",
      r"      onTap: onTap \?\?\n"
      r"          \(\) \{\n"
      r"            if \(onSelected != null\) \{\n"
      r"              onSelected!\(!selected\);\n"
      r"            \} else \{\n"
      r"              player\.playSong\(current, context: queueContext\);\n"
      r"            \}\n"
      r"          \},",
      "      // Tocar reproduce de inmediato; la selección múltiple se activa con\n"
      "      // una pulsación larga (o cuando la pantalla ya está en ese modo).\n"
      "      onTap: onTap ?? () => player.playSong(current, context: queueContext),",
      label="toque = reproducir ahora")

# ============================================ 2. Selección solo en modo selección
patch("lib/screens/songs_screen.dart",
      r"                          selected: _selected\.contains\(song\.id\),\n"
      r"                          onSelected:",
      "                          selected: _selected.contains(song.id),\n"
      "                          // Solo en modo selección el toque marca/desmarca.\n"
      "                          onTap: _selectionMode\n"
      "                              ? () => setState(() {\n"
      "                                    if (_selected.contains(song.id)) {\n"
      "                                      _selected.remove(song.id);\n"
      "                                    } else {\n"
      "                                      _selected.add(song.id);\n"
      "                                    }\n"
      "                                    if (_selected.isEmpty) _selectionMode = false;\n"
      "                                  })\n"
      "                              : null,\n"
      "                          onSelected:",
      label="toque selectivo en modo selección")

# ============================================ 3. setQueue arranca por la elegida
patch("lib/services/player_service.dart",
      r"    _rebuildPlayOrder\(anchorIndex: startIndex\.clamp\(0, _queue\.length - 1\)\);\n"
      r"    await _loadIndex\(_playOrder\.first, autoPlay: autoPlay\);",
      "    final int start = startIndex.clamp(0, _queue.length - 1);\n"
      "    _rebuildPlayOrder(anchorIndex: start);\n"
      "    // Se arranca por la canción ELEGIDA (antes siempre por la primera).\n"
      "    await _loadIndex(_playOrder[_playOrderIndex], autoPlay: autoPlay);",
      label="arrancar por la canción elegida")

# ============================================ 4. El indicador siempre encaja
patch("lib/widgets/glass.dart",
      r"    if \(oldWidget\.index != widget\.index\) \{\n"
      r"      _controller\.animateTo\(\n"
      r"        widget\.index\.toDouble\(\),\n"
      r"        duration: const Duration\(milliseconds: 520\),\n"
      r"        curve: Curves\.easeOutBack,\n"
      r"      \);\n"
      r"    \}",
      "    if (oldWidget.index != widget.index) {\n"
      "      _controller\n"
      "          .animateTo(\n"
      "            widget.index.toDouble(),\n"
      "            duration: const Duration(milliseconds: 520),\n"
      "            curve: Curves.easeOutBack,\n"
      "          )\n"
      "          .whenComplete(() {\n"
      "        // Garantiza que el indicador quede exactamente en su pestaña.\n"
      "        if (mounted) _controller.value = widget.index.toDouble();\n"
      "      });\n"
      "    }",
      label="indicador exacto al terminar")

# ============================================ 5. Transición en TODAS las pestañas
patch("lib/screens/home_shell.dart",
      r"class _HomeShellState extends State<HomeShell> \{\n  int _index = 0;",
      "class _HomeShellState extends State<HomeShell>\n"
      "    with SingleTickerProviderStateMixin {\n"
      "  int _index = 0;\n\n"
      "  /// Animación de entrada del contenido al cambiar de pestaña.\n"
      "  late final AnimationController _tabTransition = AnimationController(\n"
      "    vsync: this,\n"
      "    duration: const Duration(milliseconds: 320),\n"
      "    value: 1,\n"
      "  );\n\n"
      "  @override\n"
      "  void dispose() {\n"
      "    _tabTransition.dispose();\n"
      "    super.dispose();\n"
      "  }\n\n"
      "  /// Cambia de pestaña animando la entrada del contenido (en todas).\n"
      "  void _changeTab(int value) {\n"
      "    if (value == _index) return;\n"
      "    setState(() => _index = value);\n"
      "    if (!MediaQuery.disableAnimationsOf(context)) {\n"
      "      _tabTransition.forward(from: 0);\n"
      "    }\n"
      "  }",
      label="estado de transición de pestañas")

patch("lib/screens/home_shell.dart",
      r"      body: IndexedStack\(index: _index, children: _screens\),",
      "      body: AnimatedBuilder(\n"
      "        animation: _tabTransition,\n"
      "        builder: (BuildContext context, Widget? child) {\n"
      "          // Aparición suave (deslizamiento + opacidad) al entrar en la pestaña.\n"
      "          final double t = Curves.easeOutCubic.transform(_tabTransition.value);\n"
      "          return Opacity(\n"
      "            opacity: 0.30 + 0.70 * t,\n"
      "            child: Transform.translate(\n"
      "              offset: Offset(0, 14 * (1 - t)),\n"
      "              child: child,\n"
      "            ),\n"
      "          );\n"
      "        },\n"
      "        child: IndexedStack(index: _index, children: _screens),\n"
      "      ),",
      label="transición de contenido")

patch("lib/screens/home_shell.dart",
      r"                  onChanged: \(int value\) => setState\(\(\) => _index = value\),",
      "                  onChanged: _changeTab,",
      label="usar _changeTab en la barra")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
