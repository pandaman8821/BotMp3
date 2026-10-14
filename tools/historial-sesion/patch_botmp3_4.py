"""Corrige los dos parches fallidos (etiqueta de `seek` y `suggestMetadata`)."""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")

ok: list[str] = []
fail: list[str] = []


def patch(rel: str, pattern: str, replacement: str, *, count: int = 1, label: str = "") -> None:
    path = os.path.join(PROJ, rel)
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    new, n = re.subn(pattern, replacement, text, count=count)
    if n:
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


patch("lib/services/ai/ai_actions.dart",
      r"(      case AiActionType\.repeatOne:\n        return 'Repetir esta canción';\n)",
      r"\1      case AiActionType.seek:\n        return 'Saltar a ${value ?? ''} s';\n",
      label="etiqueta de seek")

patch("lib/services/ai/ai_orchestrator.dart",
      r"  String _catalogContext\(\{int limit = 70\}\) \{",
      "  /// Corrige y completa los metadatos de una canción (editor simplificado).\n"
      "  Future<Map<String, String>?> suggestMetadata(Song song) async {\n"
      "    final String fileName = song.path.split(RegExp(r'[\\\\/]')).last;\n"
      "    final String prompt = '''\n"
      "Canción de mi biblioteca local:\n"
      "- archivo: $fileName\n"
      "- título actual: ${song.title}\n"
      "- artista actual: ${song.artist}\n"
      "- álbum actual: ${song.album}\n"
      "- año actual: ${song.year}\n"
      "- género actual: ${song.genre}\n\n"
      "Devuelve SOLO un JSON con este formato:\n"
      '{"titulo":"...","artista":"...","album":"...","anio":2020,"genero":"...","tags":["..."]}\n'
      "Corrige mayúsculas y erratas y usa un género de esta lista si encaja:\n"
      "${GenreCatalog.all.join(', ')}.\n"
      "Si no estás seguro de un dato, repite el valor actual. No inventes años.\n"
      "''';\n"
      "    final String raw = await client.complete(\n"
      "      <AiMessage>[\n"
      "        AiMessage(role: 'user', content: prompt, createdAt: DateTime.now()),\n"
      "      ],\n"
      "      systemPrompt: '$_system\\n$_actionProtocol',\n"
      "      json: true,\n"
      "    );\n"
      "    final String? block = extractJsonBlock(raw);\n"
      "    if (block == null) return null;\n"
      "    try {\n"
      "      final dynamic decoded = jsonDecode(block);\n"
      "      if (decoded is! Map) return null;\n"
      "      final Map<dynamic, dynamic> map = decoded;\n"
      "      String pick(List<String> keys) {\n"
      "        for (final String key in keys) {\n"
      "          final Object? value = map[key];\n"
      "          if (value != null && value.toString().trim().isNotEmpty) {\n"
      "            return value.toString().trim();\n"
      "          }\n"
      "        }\n"
      "        return '';\n"
      "      }\n\n"
      "      return <String, String>{\n"
      "        'titulo': pick(<String>['titulo', 'title']),\n"
      "        'artista': pick(<String>['artista', 'artist']),\n"
      "        'album': pick(<String>['album']),\n"
      "        'anio': pick(<String>['anio', 'año', 'year']),\n"
      "        'genero': pick(<String>['genero', 'género', 'genre']),\n"
      "        'tags': map['tags'] is List\n"
      "            ? (map['tags'] as List).join(', ')\n"
      "            : pick(<String>['tags']),\n"
      "      };\n"
      "    } catch (_) {\n"
      "      return null;\n"
      "    }\n"
      "  }\n\n"
      "  String _catalogContext({int limit = 70}) {",
      label="suggestMetadata")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
