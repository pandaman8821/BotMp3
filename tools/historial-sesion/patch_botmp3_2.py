"""Integra en BotMp3: importación automática (MediaStore) y motor de acciones de IA.

Aplica parches quirúrgicos ya verificados contra el código actual. Si algún
patrón no aparece, lo reporta en lugar de dejar el fichero a medias.
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


def patch(rel: str, pattern: str, replacement: str, *, count: int = 1,
          flags: int = 0, label: str = "") -> None:
    text = read(rel)
    new, n = re.subn(pattern, replacement, text, count=count, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label or pattern[:40]}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label or pattern[:70]}")


# ---------------------------------------------------------------- 1. ai_actions
patch("lib/services/ai/ai_actions.dart",
      r"  repeatOne,\n  playQuery,",
      "  repeatOne,\n  seek,\n  playQuery,", label="enum seek")

patch("lib/services/ai/ai_actions.dart",
      r"(      case AiActionType\.repeatOne:\n        return 'Repetir esta canción 🔂';\n)",
      r"\1      case AiActionType.seek:\n        return 'Saltar a ${value ?? ''} s';\n",
      label="label seek")

# ------------------------------------------------------------- 2. player_service
patch("lib/services/player_service.dart",
      r"        AudioSource\.uri\(Uri\.file\(song\.path\), tag: mediaItem\),",
      "        AudioSource.uri(\n"
      "          song.path.startsWith('content://')\n"
      "              ? Uri.parse(song.path)\n"
      "              : Uri.file(song.path),\n"
      "          tag: mediaItem,\n"
      "        ),",
      label="soporte content:// (MediaStore)")

# ----------------------------------------------------------- 3. settings_service
prefs_check = "_prefs" in read("lib/services/settings_service.dart")
if prefs_check:
    patch("lib/services/settings_service.dart",
          r"  ThemeMode get themeMode \{",
          "  /// Importa automáticamente la música del dispositivo al abrir la app.\n"
          "  bool get autoImport => _prefs.getBool('auto_import') ?? true;\n\n"
          "  Future<void> setAutoImport(bool value) async {\n"
          "    await _prefs.setBool('auto_import', value);\n"
          "  }\n\n"
          "  ThemeMode get themeMode {",
          label="autoImport en SettingsService")
else:
    fail.append("settings_service.dart: no se encontró el campo _prefs (ajustar a mano)")

# ---------------------------------------------------------- 4. settings_provider
patch("lib/providers/settings_provider.dart",
      r"import '\.\./core/constants\.dart';",
      "import '../core/constants.dart';\nimport '../services/ai/ai_bridge.dart';",
      label="import AiBridge")

patch("lib/providers/settings_provider.dart",
      r"  SettingsProvider\(this\._service\);",
      "  SettingsProvider(this._service) {\n    AiBridge.settings = this;\n  }",
      label="auto-registro en AiBridge")

patch("lib/providers/settings_provider.dart",
      r"  ThemeMode get themeMode => _service\.themeMode;",
      "  ThemeMode get themeMode => _service.themeMode;\n"
      "  bool get autoImport => _service.autoImport;",
      label="getter autoImport")

patch("lib/providers/settings_provider.dart",
      r"  Future<void> setPreferredProvider\(AiProvider provider\) async \{",
      "  Future<void> setAutoImport(bool value) async {\n"
      "    await _service.setAutoImport(value);\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  Future<void> setPreferredProvider(AiProvider provider) async {",
      label="setter autoImport")

# ------------------------------------------------------------ 5. library_service
has_index = "_searchIndex" in read("lib/services/library_service.dart")
index_line = "      _searchIndex[song.id] = song.searchBlob;\n" if has_index else ""
patch("lib/services/library_service.dart",
      r"  Future<void> upsertSong\(Song song\) async \{",
      "  /// Importa en bloque las pistas detectadas en MediaStore.\n"
      "  /// Devuelve solo las canciones realmente nuevas (sin duplicados).\n"
      "  Future<List<Song>> importScannedTracks(List<Song> tracks) async {\n"
      "    if (tracks.isEmpty) return <Song>[];\n"
      "    final Set<String> knownIds = _songs.map((Song song) => song.id).toSet();\n"
      "    final Set<String> knownPaths = _songs.map((Song song) => song.path).toSet();\n"
      "    final List<Song> added = <Song>[];\n"
      "    for (final Song song in tracks) {\n"
      "      if (knownIds.contains(song.id) || knownPaths.contains(song.path)) continue;\n"
      "      _songs.add(song);\n"
      + index_line +
      "      knownIds.add(song.id);\n"
      "      knownPaths.add(song.path);\n"
      "      added.add(song);\n"
      "    }\n"
      "    if (added.isNotEmpty) await _persist();\n"
      "    return added;\n"
      "  }\n\n"
      "  /// Aplica varias carátulas de golpe (una sola escritura en disco).\n"
      "  Future<void> setCoversBulk(Map<String, String> coversBySongId) async {\n"
      "    if (coversBySongId.isEmpty) return;\n"
      "    bool changed = false;\n"
      "    for (final MapEntry<String, String> entry in coversBySongId.entries) {\n"
      "      final int index = _songs.indexWhere((Song song) => song.id == entry.key);\n"
      "      if (index < 0) continue;\n"
      "      _songs[index] = _songs[index].copyWith(coverPath: entry.value);\n"
      "      changed = true;\n"
      "    }\n"
      "    if (changed) await _persist();\n"
      "  }\n\n"
      "  Future<void> upsertSong(Song song) async {",
      label="importScannedTracks + setCoversBulk")

# ----------------------------------------------------------- 6. library_provider
patch("lib/providers/library_provider.dart",
      r"import '\.\./services/library_service\.dart';",
      "import '../services/ai/ai_bridge.dart';\nimport '../services/library_service.dart';\n"
      "import '../services/media_scanner.dart';",
      label="imports MediaScanner/AiBridge")

patch("lib/providers/library_provider.dart",
      r"  LibraryProvider\(\{LibraryService\? service\}\) : _service = service \?\? LibraryService\(\);",
      "  LibraryProvider({LibraryService? service}) : _service = service ?? LibraryService() {\n"
      "    AiBridge.library = this;\n"
      "  }",
      label="auto-registro en AiBridge")

patch("lib/providers/library_provider.dart",
      r"  Future<void> init\(\) async \{\n    await _service\.load\(\);\n    _loading = false;\n    notifyListeners\(\);\n  \}",
      "  Future<void>? _loadFuture;\n\n"
      "  Future<void> init() => _loadFuture ??= _load();\n\n"
      "  Future<void> _load() async {\n"
      "    await _service.load();\n"
      "    _loading = false;\n"
      "    notifyListeners();\n"
      "  }",
      label="init idempotente")

patch("lib/providers/library_provider.dart",
      r"  double _importProgress = 0;",
      "  double _importProgress = 0;\n  bool _scanning = false;\n  String? _scanMessage;",
      label="estado de escaneo")

patch("lib/providers/library_provider.dart",
      r"  double get importProgress => _importProgress;",
      "  double get importProgress => _importProgress;\n"
      "  bool get isScanning => _scanning;\n"
      "  String? get scanMessage => _scanMessage;",
      label="getters de escaneo")

patch("lib/providers/library_provider.dart",
      r"  // -+ consultas",
      "  // ------------------------------------------------------------ escaneo\n\n"
      "  /// Escanea la música del dispositivo (MediaStore) y añade automáticamente\n"
      "  /// las canciones nuevas. Devuelve cuántas se añadieron.\n"
      "  Future<int> autoScan({bool force = false}) async {\n"
      "    if (_scanning) return 0;\n"
      "    _scanning = true;\n"
      "    _scanMessage = 'Buscando música en el dispositivo…';\n"
      "    notifyListeners();\n"
      "    try {\n"
      "      await init();\n"
      "      final List<ScannedTrack> tracks = await MediaScanner.queryAudio();\n"
      "      if (tracks.isEmpty) {\n"
      "        _scanMessage = 'No se encontró música en el dispositivo';\n"
      "        return 0;\n"
      "      }\n"
      "      final List<Song> found = tracks\n"
      "          .map((ScannedTrack track) => track.toSong())\n"
      "          .toList(growable: false);\n"
      "      final List<Song> added = await _service.importScannedTracks(found);\n"
      "      _scanMessage = added.isEmpty\n"
      "          ? 'Biblioteca al día (${found.length} pistas en el dispositivo)'\n"
      "          : '${added.length} canciones nuevas de ${found.length}';\n"
      "      if (added.isNotEmpty) {\n"
      "        final Map<String, ScannedTrack> byId = <String, ScannedTrack>{\n"
      "          for (final ScannedTrack track in tracks) track.songId: track,\n"
      "        };\n"
      "        unawaited(_fetchAlbumArt(added, byId));\n"
      "      }\n"
      "      return added.length;\n"
      "    } catch (error) {\n"
      "      debugPrint('Error al escanear la biblioteca: $error');\n"
      "      _scanMessage = 'No se pudo escanear la biblioteca';\n"
      "      return 0;\n"
      "    } finally {\n"
      "      _scanning = false;\n"
      "      notifyListeners();\n"
      "    }\n"
      "  }\n\n"
      "  /// Descarga en segundo plano las carátulas de los álbumes importados.\n"
      "  Future<void> _fetchAlbumArt(List<Song> songs, Map<String, ScannedTrack> tracks) async {\n"
      "    final Map<String, String> covers = <String, String>{};\n"
      "    int processed = 0;\n"
      "    for (final Song song in songs) {\n"
      "      final ScannedTrack? track = tracks[song.id];\n"
      "      if (track == null || track.albumId <= 0) continue;\n"
      "      final String? path = await MediaScanner.albumArtPath(track.albumId);\n"
      "      if (path != null) covers[song.id] = path;\n"
      "      processed++;\n"
      "      if (covers.length >= 20) {\n"
      "        await _service.setCoversBulk(covers);\n"
      "        covers.clear();\n"
      "        notifyListeners();\n"
      "      }\n"
      "    }\n"
      "    if (covers.isNotEmpty) await _service.setCoversBulk(covers);\n"
      "    if (processed > 0) _scanMessage = 'Carátulas actualizadas ($processed canciones)';\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  // ------------------------------------------------------------ consultas",
      label="autoScan + carátulas")

# ---------------------------------------------------------- 7. player_provider
patch("lib/providers/player_provider.dart",
      r"import 'library_provider\.dart';",
      "import '../services/ai/ai_bridge.dart';\nimport 'library_provider.dart';",
      label="import AiBridge")

patch("lib/providers/player_provider.dart",
      r"    _bind\(\);\n  \}",
      "    _bind();\n    AiBridge.player = this;\n  }",
      label="auto-registro en AiBridge")

# --------------------------------------------------------- 8. ai_orchestrator
patch("lib/services/ai/ai_orchestrator.dart",
      r";\n\n(  /// |  Future<String> chat)",
      ";\n\n"
      "  /// Protocolo de órdenes ejecutables que el modelo añade a su respuesta.\n"
      "  static const String _actionProtocol = '''\n"
      "ÓRDENES EJECUTABLES (MUY IMPORTANTE):\n"
      "Cuando el usuario te pida HACER algo (no solo preguntar), añade al final de tu\n"
      "respuesta uno o varios bloques con este formato EXACTO:\n"
      '<CMD>{"accion":"reproducir_cancion","consulta":"texto a buscar"}</CMD>\n'
      "Acciones disponibles:\n"
      "  reproducir · pausar · siguiente · anterior · detener\n"
      '  volumen (valor 0..1) · subir_volumen · bajar_volumen · velocidad (valor 0.5..2)\n'
      '  aleatorio (valor true/false) · repetir (modo off|all|one)\n'
      '  reproducir_cancion (consulta) · reproducir_lista (lista)\n'
      '  crear_lista (nombre, consulta, cantidad) · anadir_a_lista (lista, consulta)\n'
      "  buscar (consulta) · editar_metadatos (consulta, campo, valor)\n"
      "  caratula (consulta) · favorito (consulta) · actualizar_biblioteca\n"
      "  que_suena · estadisticas · ayuda\n"
      "El campo 'campo' de editar_metadatos solo puede ser: titulo, artista, album,\n"
      "anio, genero o tags. No menciones ni expliques los bloques <CMD> en el texto.\n"
      "Usa el lenguaje natural solo para conversar; para actuar, usa <CMD>.\n"
      "''';\n\n"
      r"\1",
      label="protocolo de acciones")

patch("lib/services/ai/ai_orchestrator.dart",
      r"systemPrompt: '\$_system\\n\\nBIBLIOTECA DEL USUARIO \(JSON\):\\n",
      "systemPrompt: '$_system\\n$_actionProtocol\\n\\nBIBLIOTECA DEL USUARIO (JSON):\\n",
      label="inyectar protocolo en el chat")

patch("lib/services/ai/ai_orchestrator.dart",
      r"  String _catalogContext\(\) \{",
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
      "  String _catalogContext() {",
      label="suggestMetadata")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
print(f"total: {len(ok)} aplicados, {len(fail)} fallidos")
sys.exit(0 if not fail else 1)
