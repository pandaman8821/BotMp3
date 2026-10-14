"""Segunda parte del parche de edición (reemplazos literales, sin escapes)."""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
EDIT = "lib/screens/song_edit_screen.dart"
COVER = "lib/screens/cover_editor_screen.dart"

ok: list[str] = []
fail: list[str] = []


def read(rel: str) -> str:
    with open(os.path.join(PROJ, rel), "r", encoding="utf-8") as handle:
        return handle.read()


def write(rel: str, text: str) -> None:
    with open(os.path.join(PROJ, rel), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def patch(rel: str, pattern: str, replacement: str, *, label: str = "",
          skip_if: str = "") -> None:
    text = read(rel)
    if skip_if and skip_if in text:
        ok.append(f"{rel}: {label} (ya aplicado)")
        return
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


# --- imports de IA en la pantalla de edición ---------------------------------
edit_text = read(EDIT)
if "providers/ai_provider.dart" not in edit_text:
    patch(EDIT, r"(import '\.\./services/media_scanner\.dart';\n)",
          "import '../providers/ai_provider.dart';\n\\1".replace("\\1", r"\1"),
          label="import AiAssistantProvider")
    # Si AiAssistantProvider ya estaba, el patrón anterior no hace nada dañino.

# --- métodos de autocompletado y carátula del álbum --------------------------
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

patch(EDIT, r"  Future<void> _save\(Song song\) async \{", metodos,
      label="métodos autocompletar + carátula", skip_if="_autocompletarConIa")

# --- acciones rápidas en el editor de carátulas ------------------------------
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

block = (
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
      label="chips de acciones rápidas", skip_if="Acciones rápidas")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
