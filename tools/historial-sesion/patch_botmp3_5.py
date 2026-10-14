"""Simplifica la edición: autocompletado con IA y carátulas en un toque."""

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


def patch(rel: str, pattern: str, replacement: str, *, label: str = "") -> None:
    text = read(rel)
    new, n = re.subn(pattern, replacement, text, count=1)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


EDIT = "lib/screens/song_edit_screen.dart"
COVER = "lib/screens/cover_editor_screen.dart"

# --- imports necesarios ------------------------------------------------------
edit_text = read(EDIT)
imports = ""
if "providers/ai_provider.dart" not in edit_text:
    imports += "import '../providers/ai_provider.dart';\n"
if "services/media_scanner.dart" not in edit_text:
    imports += "import '../services/media_scanner.dart';\n"
if imports:
    patch(EDIT, r"(import '\.\./providers/library_provider\.dart';\n)",
          r"\1" + imports, label="imports IA/MediaScanner")

# --- 1. Botón "Autocompletar con IA" en la barra superior --------------------
patch(EDIT,
      r"(        actions: <Widget>\[\n)",
      r"\1"
      "          IconButton(\n"
      "            tooltip: 'Autocompletar con IA',\n"
      "            icon: const Icon(Icons.auto_awesome),\n"
      "            onPressed: _saving ? null : () => _autocompletarConIa(song),\n"
      "          ),\n",
      label="botón autocompletar IA")

# --- 2. Botón "Carátula del álbum" junto al editor de carátula ---------------
patch(EDIT,
      r"(\n\s+label: const Text\('Editar carátula'\),\n\s+\),\n)",
      r"\1"
      "                      const SizedBox(height: 8),\n"
      "                      OutlinedButton.icon(\n"
      "                        onPressed: () => _usarCaratulaDelAlbum(song),\n"
      "                        icon: const Icon(Icons.album_outlined),\n"
      "                        label: const Text('Carátula del álbum'),\n"
      "                      ),\n",
      label="botón carátula del álbum")

# --- 3. Métodos de autocompletado y carátula ---------------------------------
patch(EDIT,
      r"  Future<void> _save\(Song song\) async \{",
      "  /// Rellena el formulario con los datos corregidos por la IA (un solo toque).\n"
      "  Future<void> _autocompletarConIa(Song song) async {\n"
      "    final AiAssistantProvider ai = context.read<AiAssistantProvider>();\n"
      "    ScaffoldMessenger.of(context).showSnackBar(\n"
      "      const SnackBar(content: Text('Pidiendo los datos a la IA…')),\n"
      "    );\n"
      "    final Map<String, String>? sugerencia = await ai.suggestMetadata(song);\n"
      "    if (!mounted) return;\n"
      "    if (sugerencia == null) {\n"
      "      ScaffoldMessenger.of(context).showSnackBar(\n"
      "        const SnackBar(\n"
      "          content: Text('No pude autocompletar. Revisa la API key en Ajustes ▸ IA.'),\n"
      "        ),\n"
      "      );\n"
      "      return;\n"
      "    }\n"
      "    setState(() {\n"
      "      final String titulo = sugerencia['titulo'] ?? '';\n"
      "      final String artista = sugerencia['artista'] ?? '';\n"
      "      final String album = sugerencia['album'] ?? '';\n"
      "      final String anio = sugerencia['anio'] ?? '';\n"
      "      final String genero = sugerencia['genero'] ?? '';\n"
      "      final String tags = sugerencia['tags'] ?? '';\n"
      "      if (titulo.isNotEmpty) _title.text = titulo;\n"
      "      if (artista.isNotEmpty) _artist.text = artista;\n"
      "      if (album.isNotEmpty) _album.text = album;\n"
      "      if (anio.isNotEmpty) {\n"
      "        _year.text = RegExp(r'\\d{4}').firstMatch(anio)?.group(0) ?? _year.text;\n"
      "      }\n"
      "      if (genero.isNotEmpty) _genre = GenreCatalog.normalize(genero);\n"
      "      if (tags.isNotEmpty) {\n"
      "        _tags = tags\n"
      "            .split(RegExp(r'[,\\s]+'))\n"
      "            .where((String tag) => tag.isNotEmpty)\n"
      "            .toSet()\n"
      "            .toList();\n"
      "      }\n"
      "    });\n"
      "    ScaffoldMessenger.of(context).showSnackBar(\n"
      "      const SnackBar(content: Text('Datos completados ✨ Revisa y guarda')),\n"
      "    );\n"
      "  }\n\n"
      "  /// Aplica como carátula la imagen original del álbum del dispositivo.\n"
      "  Future<void> _usarCaratulaDelAlbum(Song song) async {\n"
      "    final LibraryProvider library = context.read<LibraryProvider>();\n"
      "    final String? path = await MediaScanner.albumArtForTrack(song.id);\n"
      "    if (!mounted) return;\n"
      "    if (path == null) {\n"
      "      ScaffoldMessenger.of(context).showSnackBar(\n"
      "        const SnackBar(content: Text('Ese álbum no tiene carátula en el dispositivo')),\n"
      "      );\n"
      "      return;\n"
      "    }\n"
      "    await library.setCover(song.id, path);\n"
      "    if (!mounted) return;\n"
      "    ScaffoldMessenger.of(context).showSnackBar(\n"
      "      const SnackBar(content: Text('Carátula del álbum aplicada 🖼️')),\n"
      "    );\n"
      "  }\n\n"
      "  Future<void> _save(Song song) async {",
      label="métodos de autocompletado y carátula")

# --- 4. Acciones rápidas en el editor de carátulas --------------------------
cover_text = read(COVER)
chips: list[str] = []
if "quarterTurns" in cover_text:
    chips.append(
        "                              ActionChip(\n"
        "                                avatar: const Icon(Icons.rotate_right, size: 16),\n"
        "                                label: const Text('Rotar 90°'),\n"
        "                                onPressed: () => _update(_state.copyWith(\n"
        "                                      quarterTurns: (_state.quarterTurns + 1) % 4,\n"
        "                                    )),\n"
        "                              ),\n"
    )
if "brightness" in cover_text and "contrast" in cover_text:
    chips.append(
        "                              ActionChip(\n"
        "                                avatar: const Icon(Icons.auto_fix_high, size: 16),\n"
        "                                label: const Text('Mejorar'),\n"
        "                                onPressed: () => _update(_state.copyWith(\n"
        "                                      brightness: 0.06,\n"
        "                                      contrast: 0.14,\n"
        "                                    )),\n"
        "                              ),\n"
    )
chips.append(
    "                              ActionChip(\n"
    "                                avatar: const Icon(Icons.restart_alt, size: 16),\n"
    "                                label: const Text('Original'),\n"
    "                                onPressed: () => _update(const CoverEditState()),\n"
    "                              ),\n"
)

if chips:
    block = (
        "\\1"
        "                          _sectionTitle('Acciones rápidas'),\n"
        "                          Wrap(\n"
        "                            spacing: 8,\n"
        "                            runSpacing: 8,\n"
        "                            children: <Widget>[\n"
        + "".join(chips) +
        "                            ],\n"
        "                          ),\n"
    )
    patch(COVER, r"(\n(\s+)_sectionTitle\('Proporción'\),)", block,
          label="chips de acciones rápidas")
else:
    fail.append(f"{COVER}: sin identificadores verificados para las acciones rápidas")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
