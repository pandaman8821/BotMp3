"""BotMp3 v1.2.0 (parte 2) — recuperar el espacio de las copias importadas.

  1. `autoScan` ya no duplica canciones que ya están en la biblioteca.
  2. `freeSpace` reapunta cada canción copiada al archivo ORIGINAL del
     dispositivo (MediaStore) y borra la copia: es donde están los GB.
     Si la canción no está en el dispositivo, la copia sale de la caché.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
REL = "lib/providers/library_provider.dart"

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


# ------------------------------------------------ 1. autoScan sin duplicados
patch(REL,
      r"      final List<Song> found = tracks\n"
      r"          \.map\(\(ScannedTrack track\) => track\.toSong\(\)\)\n"
      r"          \.toList\(growable: false\);\n"
      r"      final List<Song> added = await _service\.importScannedTracks\(found\);",
      "      final List<Song> found = tracks\n"
      "          .map((ScannedTrack track) => track.toSong())\n"
      "          .toList(growable: false);\n\n"
      "      // No se duplican canciones que ya están en la biblioteca\n"
      "      // (aunque apunten a una copia importada).\n"
      "      final Set<String> conocidas = <String>{\n"
      "        for (final Song song in _service.songs)\n"
      "          _claveDispositivo(song.title, song.artist),\n"
      "      };\n"
      "      final List<Song> nuevas = found\n"
      "          .where((Song song) =>\n"
      "              !conocidas.contains(_claveDispositivo(song.title, song.artist)))\n"
      "          .toList(growable: false);\n"
      "      final List<Song> added = await _service.importScannedTracks(nuevas);",
      label="autoScan sin duplicados")

# ------------------------------------------------ 2. freeSpace inteligente
nuevo_free = """  Future<int> freeSpace() async {
    if (_scanning) return 0;
    _scanning = true;
    _scanMessage = 'Liberando espacio…';
    notifyListeners();
    try {
      await init();
      final StorageService storage = StorageService.instance;
      final String cacheRoot = (await storage.cacheRoot()).path;
      final String importedRoot = (await storage.importedDirectory()).path;

      // Índice de la música real del dispositivo (por título+artista y por archivo).
      final List<ScannedTrack> enDispositivo = await MediaScanner.queryAudio();
      final Map<String, List<ScannedTrack>> porCancion = <String, List<ScannedTrack>>{};
      final Map<String, ScannedTrack> porArchivo = <String, ScannedTrack>{};
      for (final ScannedTrack track in enDispositivo) {
        porCancion
            .putIfAbsent(_claveDispositivo(track.title, track.artist), () => <ScannedTrack>[])
            .add(track);
        if (track.path != null && track.path!.isNotEmpty) {
          porArchivo[_nombreArchivo(track.path!)] = track;
        }
      }

      final Map<String, String> reapuntadas = <String, String>{};
      int liberado = 0;
      int recuperadas = 0;
      int movidas = 0;

      for (final Song song in List<Song>.from(_service.songs)) {
        final bool enCache = song.path.startsWith(cacheRoot);
        final bool enImportadas = song.path.startsWith(importedRoot);
        if (!enCache && !enImportadas) continue;

        final File file = File(song.path);
        if (!file.existsSync()) continue;

        // 1) Si la canción también está en la música del dispositivo, se usa el
        //    archivo ORIGINAL y se borra nuestra copia (aquí está el ahorro real).
        final ScannedTrack? original = _buscarEnDispositivo(song, porCancion, porArchivo);
        if (original != null) {
          reapuntadas[song.id] = original.source;
          try {
            liberado += await file.length();
            recuperadas++;
            await file.delete();
          } catch (_) {}
          continue;
        }

        // 2) Si no está en el dispositivo, al menos sale de la caché.
        if (enCache) {
          final String estable = await storage
              .moveImportedFile(song.path, file.uri.pathSegments.last);
          if (estable != song.path) {
            reapuntadas[song.id] = estable;
            movidas++;
          }
        }
      }

      if (reapuntadas.isNotEmpty) await _service.updatePaths(reapuntadas);

      // 3) Caché regenerable (nunca se toca lo que está en uso) + carátulas huérfanas.
      final Set<String> enUso = _service.songs.map((Song song) => song.path).toSet();
      liberado += await storage.clearRegenerableCache(protectedPaths: enUso);
      liberado += await _purgeOrphanCovers();

      _scanMessage = liberado > 0
          ? 'Liberados ${Formatters.bytes(liberado)}'
              '${recuperadas > 0 ? ' · $recuperadas copias reemplazadas por el original' : ''}'
          : 'No había nada que liberar';
      return liberado;
    } catch (error) {
      debugPrint('No se pudo liberar espacio: $error');
      _scanMessage = 'No se pudo liberar espacio';
      return 0;
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  /// Clave para reconocer la misma canción entre la biblioteca y el dispositivo.
  static String _claveDispositivo(String title, String artist) =>
      '${title.toLowerCase().trim()}|${artist.toLowerCase().trim()}';

  static String _nombreArchivo(String path) {
    final String name = path.split(RegExp(r'[\\\\/]')).last;
    final int dot = name.lastIndexOf('.');
    return (dot > 0 ? name.substring(0, dot) : name).toLowerCase().trim();
  }

  /// Busca la canción original en la música del dispositivo.
  ScannedTrack? _buscarEnDispositivo(
    Song song,
    Map<String, List<ScannedTrack>> porCancion,
    Map<String, ScannedTrack> porArchivo,
  ) {
    final List<ScannedTrack>? candidatos =
        porCancion[_claveDispositivo(song.title, song.artist)];
    if (candidatos != null && candidatos.isNotEmpty) {
      if (candidatos.length == 1 || song.durationMs <= 0) return candidatos.first;
      for (final ScannedTrack track in candidatos) {
        if ((track.durationMs - song.durationMs).abs() <= 3000) return track;
      }
      return candidatos.first;
    }
    // Respaldo: mismo nombre de archivo (habitual al importar con el selector).
    return porArchivo[_nombreArchivo(song.path)];
  }

  /// Borra las carátulas que ya no pertenecen a ninguna canción."""

patch(REL,
      r"  Future<int> freeSpace\(\) async \{.*?\n  \}\n\n  /// Borra las carátulas que ya no pertenecen a ninguna canción\.",
      nuevo_free,
      flags=re.DOTALL,
      label="freeSpace con reapuntado")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
