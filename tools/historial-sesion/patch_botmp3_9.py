"""BotMp3 v1.2.0 — gestión de almacenamiento y caché.

Causa del problema: `file_picker` copia cada canción elegida a su carpeta de
CACHÉ y la app usaba esa ruta; además, cuando el selector devuelve bytes, se
guardaba otra copia en `files/imported/`. Resultado: la música duplicada
(caché + datos del usuario) y canciones que pueden desaparecer si Android
limpia la caché.

Cambios:
  1. Las importaciones se MUEVEN a almacenamiento permanente (`files/imported`).
  2. "Liberar espacio" en Ajustes: migra lo que esté en caché y limpia lo regenerable.
  3. Limpieza automática si la caché supera 250 MB.
  4. Las carátulas antiguas de una canción se borran al guardar una nueva.
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


# ==================================================== 1. StorageService
patch("lib/services/storage_service.dart",
      r"import 'package:path_provider/path_provider\.dart';",
      "import 'package:flutter/foundation.dart';\nimport 'package:path_provider/path_provider.dart';",
      label="import foundation")

patch("lib/services/storage_service.dart",
      r"  Future<String> saveCoverBytes\(String songId, Uint8List bytes, \{bool png = false\}\) async \{\n",
      "  Future<String> saveCoverBytes(String songId, Uint8List bytes, {bool png = false}) async {\n"
      "    // Cada edición reemplaza la carátula anterior (evita acumular archivos).\n"
      "    await deleteCoversOf(songId);\n",
      label="reemplazar carátula anterior")

nuevos = """  /// Carpeta permanente donde se guardan las copias de audio importadas.
  /// No es caché: Android no puede borrarla por su cuenta.
  Future<Directory> importedDirectory() async {
    final Directory docs = await documents();
    final Directory target = Directory('${docs.path}/${StorageKeys.importedDir}');
    if (!target.existsSync()) await target.create(recursive: true);
    return target;
  }

  /// Mueve un archivo de la caché del selector a la carpeta permanente de la app.
  /// Si el renombrado no es posible (otro volumen), copia y borra el original.
  Future<String> moveImportedFile(String sourcePath, String fileName) async {
    final Directory target = await importedDirectory();
    final File source = File(sourcePath);
    final File destination = File('${target.path}/${_sanitize(fileName)}');
    if (source.path == destination.path) return source.path;
    try {
      if (destination.existsSync()) await destination.delete();
      await source.rename(destination.path);
      return destination.path;
    } catch (_) {
      try {
        final File moved = await source.copy(destination.path);
        try {
          await source.delete();
        } catch (_) {}
        return moved.path;
      } catch (error) {
        debugPrint('No se pudo mover $sourcePath: $error');
        return sourcePath;
      }
    }
  }

  /// Tamaño total en bytes de un directorio (recursivo).
  Future<int> directorySize(Directory directory) async {
    if (!directory.existsSync()) return 0;
    int total = 0;
    await for (final FileSystemEntity entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  /// Carpeta raíz de la caché de la app.
  Future<Directory> cacheRoot() async => getTemporaryDirectory();

  /// Bytes que ocupa la caché de la app (carátulas temporales, restos del selector…).
  Future<int> cacheSize() async {
    try {
      return await directorySize(await getTemporaryDirectory());
    } catch (_) {
      return 0;
    }
  }

  /// Borra de la caché todo lo que se puede regenerar o volver a importar.
  /// [protectedPaths] contiene las rutas de canciones EN USO: nunca se tocan.
  /// Devuelve los bytes liberados.
  Future<int> clearRegenerableCache({
    Set<String> protectedPaths = const <String>{},
  }) async {
    int freed = 0;
    try {
      final Directory cache = await getTemporaryDirectory();
      if (!cache.existsSync()) return 0;
      final List<FileSystemEntity> entities =
          cache.listSync(recursive: true, followLinks: false);
      for (final FileSystemEntity entity in entities) {
        if (entity is! File) continue;
        if (protectedPaths.contains(entity.path)) continue;
        try {
          final int size = await entity.length();
          await entity.delete();
          freed += size;
        } catch (_) {}
      }
      for (final FileSystemEntity entity in entities.reversed) {
        if (entity is Directory && entity.existsSync()) {
          try {
            if (entity.listSync().isEmpty) await entity.delete();
          } catch (_) {}
        }
      }
    } catch (error) {
      debugPrint('No se pudo limpiar la caché: $error');
    }
    return freed;
  }

  /// Borra las carátulas anteriores de una canción.
  Future<void> deleteCoversOf(String songId) async {
    try {
      final Directory covers = await coversDirectory();
      final String safeId = _sanitize(songId);
      for (final FileSystemEntity entity in covers.listSync()) {
        if (entity is File &&
            entity.path
                .split(RegExp(r'[\\\\/]'))
                .last
                .startsWith('cover_${safeId}_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Exporta un texto (por ejemplo una lista en JSON) a un archivo temporal
  /// listo para compartir."""

patch("lib/services/storage_service.dart",
      r"  /// Exporta un texto \(por ejemplo una lista en JSON\) a un archivo temporal\n"
      r"  /// listo para compartir\.",
      nuevos,
      label="utilidades de almacenamiento")

# ==================================================== 2. MediaImporter
patch("lib/services/media_importer.dart",
      r"        if \(file\.path != null && file\.path!\.isNotEmpty\) \{\n          paths\.add\(file\.path!\);\n          continue;\n        \}",
      "        if (file.path != null && file.path!.isNotEmpty) {\n"
      "          // El selector deja el audio en SU caché (Android puede borrarla):\n"
      "          // lo movemos al almacenamiento permanente de la app.\n"
      "          final String stable = await StorageService.instance\n"
      "              .moveImportedFile(file.path!, file.name);\n"
      "          paths.add(stable);\n"
      "          continue;\n"
      "        }",
      label="mover importaciones fuera de la caché")

# ==================================================== 3. LibraryService
patch("lib/services/library_service.dart",
      r"  /// Importa en bloque las pistas detectadas en MediaStore\.",
      "  /// Cambia la ruta de varias canciones a la vez (una sola escritura).\n"
      "  Future<void> updatePaths(Map<String, String> pathsBySongId) async {\n"
      "    if (pathsBySongId.isEmpty) return;\n"
      "    bool changed = false;\n"
      "    for (final MapEntry<String, String> entry in pathsBySongId.entries) {\n"
      "      final int index = _songs.indexWhere((Song song) => song.id == entry.key);\n"
      "      if (index < 0) continue;\n"
      "      _songs[index] = _songs[index].copyWith(path: entry.value);\n"
      "      changed = true;\n"
      "    }\n"
      "    if (changed) await _persist();\n"
      "  }\n\n"
      "  /// Importa en bloque las pistas detectadas en MediaStore.",
      label="updatePaths")

# ==================================================== 4. LibraryProvider
patch("lib/providers/library_provider.dart",
      r"  // -+ escaneo",
      "  // ------------------------------------------------------- almacenamiento\n\n"
      "  /// Bytes que ocupa la caché de la app.\n"
      "  Future<int> cacheBytes() => StorageService.instance.cacheSize();\n\n"
      "  /// Libera espacio sin perder nada:\n"
      "  ///  1. mueve a almacenamiento permanente las canciones guardadas en la caché;\n"
      "  ///  2. borra la caché regenerable (carátulas temporales, restos del selector).\n"
      "  /// Devuelve los bytes liberados.\n"
      "  Future<int> freeSpace() async {\n"
      "    if (_scanning) return 0;\n"
      "    _scanning = true;\n"
      "    _scanMessage = 'Liberando espacio…';\n"
      "    notifyListeners();\n"
      "    try {\n"
      "      await init();\n"
      "      final String cacheRoot = (await StorageService.instance.cacheRoot()).path;\n"
      "      final Map<String, String> moved = <String, String>{};\n\n"
      "      // 1) Canciones cuyo audio vive en la caché: pasan a la carpeta fija.\n"
      "      for (final Song song in List<Song>.from(_service.songs)) {\n"
      "        if (!song.path.startsWith(cacheRoot)) continue;\n"
      "        final File file = File(song.path);\n"
      "        if (!file.existsSync()) continue;\n"
      "        final String stable = await StorageService.instance\n"
      "            .moveImportedFile(song.path, file.uri.pathSegments.last);\n"
      "        if (stable != song.path) moved[song.id] = stable;\n"
      "      }\n"
      "      if (moved.isNotEmpty) await _service.updatePaths(moved);\n\n"
      "      // 2) Caché regenerable (nunca se toca lo que está en uso).\n"
      "      final Set<String> inUse =\n"
      "          _service.songs.map((Song song) => song.path).toSet();\n"
      "      int freed = await StorageService.instance\n"
      "          .clearRegenerableCache(protectedPaths: inUse);\n\n"
      "      // 3) Carátulas huérfanas (canciones que ya no existen).\n"
      "      freed += await _purgeOrphanCovers();\n\n"
      "      _scanMessage = freed > 0\n"
      "          ? 'Liberados ${Formatters.bytes(freed)}'\n"
      "          : 'No había nada que liberar';\n"
      "      return freed;\n"
      "    } catch (error) {\n"
      "      debugPrint('No se pudo liberar espacio: $error');\n"
      "      _scanMessage = 'No se pudo liberar espacio';\n"
      "      return 0;\n"
      "    } finally {\n"
      "      _scanning = false;\n"
      "      notifyListeners();\n"
      "    }\n"
      "  }\n\n"
      "  /// Borra las carátulas que ya no pertenecen a ninguna canción.\n"
      "  Future<int> _purgeOrphanCovers() async {\n"
      "    int freed = 0;\n"
      "    try {\n"
      "      final Directory covers = await StorageService.instance.coversDirectory();\n"
      "      final Set<String> used = _service.songs\n"
      "          .map((Song song) => song.coverPath)\n"
      "          .whereType<String>()\n"
      "          .toSet();\n"
      "      for (final FileSystemEntity entity in covers.listSync()) {\n"
      "        if (entity is! File || used.contains(entity.path)) continue;\n"
      "        try {\n"
      "          final int size = await entity.length();\n"
      "          await entity.delete();\n"
      "          freed += size;\n"
      "        } catch (_) {}\n"
      "      }\n"
      "    } catch (_) {}\n"
      "    return freed;\n"
      "  }\n\n"
      "  // ------------------------------------------------------------ escaneo",
      label="cacheBytes + freeSpace")

patch("lib/providers/library_provider.dart",
      r"import '\.\./services/library_service\.dart';",
      "import '../core/formatters.dart';\nimport '../services/library_service.dart';\n"
      "import '../services/storage_service.dart';",
      label="import StorageService y Formatters")

patch("lib/providers/library_provider.dart",
      r"import 'dart:async';",
      "import 'dart:async';\nimport 'dart:io';",
      label="import dart:io")

# ==================================================== 5. HomeShell (auto-limpieza)
patch("lib/screens/home_shell.dart",
      r"    final int added = await context\.read<LibraryProvider>\(\)\.autoScan\(\);",
      "    final LibraryProvider library = context.read<LibraryProvider>();\n"
      "    final int added = await library.autoScan();\n"
      "    // Si la caché crece demasiado, se limpia sola (nunca borra audio en uso).\n"
      "    if (await library.cacheBytes() > 250 * 1024 * 1024) {\n"
      "      await library.freeSpace();\n"
      "    }",
      label="limpieza automática de caché")

# ==================================================== 6. Ajustes: liberar espacio
patch("lib/screens/settings_screen.dart",
      r"            title: const Text\('Escanear ahora'\),.*?\n            \},\n          \),",
      "            title: const Text('Escanear ahora'),\n"
      "            subtitle: Text(library.scanMessage ?? 'Busca música nueva en el dispositivo'),\n"
      "            onTap: () async {\n"
      "              final int added = await library.autoScan(force: true);\n"
      "              if (!context.mounted) return;\n"
      "              ScaffoldMessenger.of(context).showSnackBar(\n"
      "                SnackBar(\n"
      "                  content: Text(\n"
      "                    added == 0\n"
      "                        ? 'No hay canciones nuevas'\n"
      "                        : '$added canciones añadidas',\n"
      "                  ),\n"
      "                ),\n"
      "              );\n"
      "            },\n"
      "          ),\n"
      "          ListTile(\n"
      "            leading: const Icon(Icons.cleaning_services_outlined),\n"
      "            title: const Text('Liberar espacio'),\n"
      "            subtitle: FutureBuilder<int>(\n"
      "              future: library.cacheBytes(),\n"
      "              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {\n"
      "                final String detail = snapshot.hasData\n"
      "                    ? '${Formatters.bytes(snapshot.data!)} en caché (temporal, se puede borrar)'\n"
      "                    : 'Calculando…';\n"
      "                return Text(detail);\n"
      "              },\n"
      "            ),\n"
      "            trailing: TextButton(\n"
      "              onPressed: () async {\n"
      "                final int freed = await library.freeSpace();\n"
      "                if (!context.mounted) return;\n"
      "                ScaffoldMessenger.of(context).showSnackBar(\n"
      "                  SnackBar(\n"
      "                    content: Text(\n"
      "                      freed > 0\n"
      "                          ? 'Liberados ${Formatters.bytes(freed)} 🧹'\n"
      "                          : 'No había nada que liberar',\n"
      "                    ),\n"
      "                  ),\n"
      "                );\n"
      "              },\n"
      "              child: const Text('Limpiar'),\n"
      "            ),\n"
      "          ),",
      flags=re.DOTALL,
      label="tile liberar espacio")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
