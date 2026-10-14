"""Correcciones tras el análisis estático: cadenas rotas, imports y nombres."""

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
          label: str = "", count: int = 0) -> None:
    text = read(rel)
    new, n = re.subn(pattern, lambda _m: replacement, text, count=count, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label} ({n})")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


# --------------------------------------------------- media_scanner: orEmpty
for campo in ("title", "artist", "album"):
    patch("lib/services/media_scanner.dart",
          r"\(map\['" + campo + r"'\] as String\?\)\?\.trim\(\)\.orEmpty\(\)",
          f"((map['{campo}'] as String?) ?? '').trim()",
          label=f"orEmpty -> fallback ({campo})")

# --------------------------------------------- ai_orchestrator: import y cadenas
if "core/constants.dart" not in read("lib/services/ai/ai_orchestrator.dart"):
    patch("lib/services/ai/ai_orchestrator.dart",
          r"(import '[^']+';)\n\nclass AiOrchestrator",
          "\\1\nimport '../../core/constants.dart';\n\nclass AiOrchestrator"
          .replace("\\1", r"\1"),
          label="import constants")

patch("lib/services/ai/ai_orchestrator.dart",
      r"systemPrompt: '\$_system\s*\$_actionProtocol\s*BIBLIOTECA DEL USUARIO \(JSON\):\s*",
      "systemPrompt: '$_system\\n$_actionProtocol\\n\\nBIBLIOTECA DEL USUARIO (JSON):\\n",
      flags=re.DOTALL,
      label="cadena del chat")

patch("lib/services/ai/ai_orchestrator.dart",
      r"systemPrompt: '\$_system\s*\$_actionProtocol',",
      "systemPrompt: '$_system\\n$_actionProtocol',",
      flags=re.DOTALL,
      label="cadena de suggestMetadata")

patch("lib/services/ai/ai_orchestrator.dart",
      r"song\.path\.split\(RegExp\(r'\[\\/\]'\)\)",
      "song.path.split(RegExp(r'[\\\\/]'))",
      label="regex de separador de ruta")

# --------------------------------------------------- ai_provider: join roto
patch("lib/providers/ai_provider.dart",
      r"\.join\('\s*'\)",
      ".join(\"\\n\")",
      flags=re.DOTALL,
      label="join con salto de línea")

# ----------------------------------------------------------- ai_screen: color
patch("lib/screens/ai_screen.dart",
      r"AppColors\.green : AppColors\.warn,",
      "AppColors.green : Theme.of(context).colorScheme.error,",
      label="color de error")

# ------------------------------------------------------- home_shell: import
if "providers/library_provider.dart" not in read("lib/screens/home_shell.dart"):
    patch("lib/screens/home_shell.dart",
          r"import '\.\./providers/settings_provider\.dart';",
          "import '../providers/library_provider.dart';\nimport '../providers/settings_provider.dart';",
          label="import LibraryProvider")

# ------------------------------------- action_executor: formato de velocidad
patch("lib/services/ai/action_executor.dart",
      r"Formatters\.speedLabel\(percent / 100\)",
      "${(percent / 100).toStringAsFixed(2)}x",
      label="formato de velocidad")

# ------------------------------------ song_edit: métodos (definición real)
metodos = """  /// Rellena el formulario con los datos corregidos por la IA (un solo toque).
  Future<void> _autocompletarConIa(Song song) async {
    final AiAssistantProvider ai = context.read<AiAssistantProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pidiendo los datos a la IA…')),
    );
    final Map<String, String>? sugerencia = await ai.suggestMetadata(song);
    if (!mounted) return;
    if (sugerencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pude autocompletar. Revisa la API key en Ajustes ▸ IA.'),
        ),
      );
      return;
    }
    setState(() {
      final String titulo = sugerencia['titulo'] ?? '';
      final String artista = sugerencia['artista'] ?? '';
      final String album = sugerencia['album'] ?? '';
      final String anio = sugerencia['anio'] ?? '';
      final String genero = sugerencia['genero'] ?? '';
      final String tags = sugerencia['tags'] ?? '';
      if (titulo.isNotEmpty) _title.text = titulo;
      if (artista.isNotEmpty) _artist.text = artista;
      if (album.isNotEmpty) _album.text = album;
      if (anio.isNotEmpty) {
        _year.text = RegExp(r'\\d{4}').firstMatch(anio)?.group(0) ?? _year.text;
      }
      if (genero.isNotEmpty) _genre = GenreCatalog.normalize(genero);
      if (tags.isNotEmpty) {
        _tags = tags
            .split(RegExp(r'[,\\s]+'))
            .where((String tag) => tag.isNotEmpty)
            .toSet()
            .toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos completados ✨ Revisa y guarda')),
    );
  }

  /// Aplica como carátula la imagen original del álbum del dispositivo.
  Future<void> _usarCaratulaDelAlbum(Song song) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final String? path = await MediaScanner.albumArtForTrack(song.id);
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese álbum no tiene carátula en el dispositivo')),
      );
      return;
    }
    await library.setCover(song.id, path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carátula del álbum aplicada 🖼️')),
    );
  }

  Future<void> _save(Song song) async {"""

if "Future<void> _autocompletarConIa(Song song) async {" in read("lib/screens/song_edit_screen.dart"):
    ok.append("lib/screens/song_edit_screen.dart: métodos (ya definidos)")
else:
    patch("lib/screens/song_edit_screen.dart",
          r"  Future<void> _save\(Song song\) async \{",
          metodos,
          label="métodos autocompletar + carátula")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
