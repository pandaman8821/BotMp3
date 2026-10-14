"""BotMp3 v1.3.5 — siguiente/anterior en la pantalla de bloqueo.

Causa: el servicio cargaba UNA sola canción en el reproductor
(`setAudioSource(AudioSource.uri(...))` por canción), así que la sesión
multimedia creía que la cola tenía 1 elemento: en el bloqueo solo aparecían
«play» y «pausa», sin siguiente/anterior.

Solución: cargar la cola COMPLETA como `ConcatenatingAudioSource`, **en el orden
de la cola** (índice de secuencia = índice de cola, sin desajustes). El orden
aleatorio sigue aplicándose en la app mediante `_playOrder`; lo único que hace el
sistema es avanzar por la lista, que es el comportamiento esperado y seguro.
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
REL = "lib/services/player_service.dart"

ok: list[str] = []
fail: list[str] = []


def read() -> str:
    with open(os.path.join(PROJ, REL), "r", encoding="utf-8") as handle:
        return handle.read()


def write(text: str) -> None:
    with open(os.path.join(PROJ, REL), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def patch(pattern: str, replacement: str, *, flags: int = 0, label: str = "") -> None:
    text = read()
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1, flags=flags)
    if n:
        write(new)
        ok.append(label)
    else:
        fail.append(f"NO ENCONTRADO -> {label}")


# ============================================ 1. Escuchar los cambios de pista
patch(
    r"    _player\.playerStateStream\.listen\(\(PlayerState state\) \{\n"
    r"      _syncWakelock\(state\.playing\);\n"
    r"    \}\);",
    "    _player.playerStateStream.listen((PlayerState state) {\n"
    "      _syncWakelock(state.playing);\n"
    "    });\n\n"
    "    // La sesión multimedia (bloqueo, auriculares, reloj…) puede cambiar de\n"
    "    // pista por su cuenta: aquí se sincroniza el estado de la app.\n"
    "    _player.currentIndexStream.listen(_onPlayerIndexChanged);",
    label="escuchar cambio de pista del sistema",
)

# ============================================ 2. setQueue carga la cola completa
patch(
    r"    _rebuildPlayOrder\(anchorIndex: start\);\n"
    r"    // Se arranca por la canción ELEGIDA \(antes siempre por la primera\)\.\n"
    r"    await _loadIndex\(_playOrder\[_playOrderIndex\], autoPlay: autoPlay\);",
    "    _rebuildPlayOrder(anchorIndex: start);\n"
    "    // Se carga TODA la cola en el reproductor (no solo una canción): es lo que\n"
    "    // permite que la pantalla de bloqueo ofrezca siguiente/anterior.\n"
    "    await _loadQueueIntoPlayer(start, autoPlay: autoPlay);",
    label="setQueue carga la cola completa",
)

# ============================================ 3. enqueue / playNext / remove
patch(
    r"  Future<void> enqueue\(List<Song> songs, \{bool playIfEmpty = true\}\) async \{\n"
    r"    if \(songs\.isEmpty\) return;\n"
    r"    final bool wasEmpty = _queue\.isEmpty;\n"
    r"    _queue\.addAll\(songs\);\n"
    r"    queueRevision\.value\+\+;\n"
    r"    if \(wasEmpty && playIfEmpty\) \{\n"
    r"      _rebuildPlayOrder\(anchorIndex: 0\);\n"
    r"      await _loadIndex\(0\);\n"
    r"    \} else \{\n"
    r"      _rebuildPlayOrder\(anchorIndex: _currentIndex\);\n"
    r"    \}\n"
    r"  \}",
    "  Future<void> enqueue(List<Song> songs, {bool playIfEmpty = true}) async {\n"
    "    if (songs.isEmpty) return;\n"
    "    final bool wasEmpty = _queue.isEmpty;\n"
    "    _queue.addAll(songs);\n"
    "    queueRevision.value++;\n"
    "    if (wasEmpty && playIfEmpty) {\n"
    "      _rebuildPlayOrder(anchorIndex: 0);\n"
    "      await _loadQueueIntoPlayer(0);\n"
    "      return;\n"
    "    }\n"
    "    _rebuildPlayOrder(anchorIndex: _currentIndex);\n"
    "    if (wasEmpty) return;\n"
    "    // Se añaden al final de la cola del sistema sin cortar la reproducción.\n"
    "    final AudioSource? source = _player.audioSource;\n"
    "    if (source is ConcatenatingAudioSource) {\n"
    "      for (final Song song in songs) {\n"
    "        await source.add(_sourceFor(song));\n"
    "      }\n"
    "    } else {\n"
    "      await _loadQueueIntoPlayer(_currentIndex < 0 ? 0 : _currentIndex,\n"
    "          autoPlay: false);\n"
    "    }\n"
    "  }",
    label="enqueue añade a la cola del sistema",
)

patch(
    r"  Future<void> playNext\(Song song\) async \{\n"
    r"    if \(_queue\.isEmpty\) \{\n"
    r"      await setQueue\(<Song>\[song\]\);\n"
    r"      return;\n"
    r"    \}\n"
    r"    final int insertAt = \(_currentIndex \+ 1\)\.clamp\(0, _queue\.length\);\n"
    r"    _queue\.insert\(insertAt, song\);\n"
    r"    queueRevision\.value\+\+;\n"
    r"    _rebuildPlayOrder\(anchorIndex: _currentIndex\);\n"
    r"  \}",
    "  Future<void> playNext(Song song) async {\n"
    "    if (_queue.isEmpty) {\n"
    "      await setQueue(<Song>[song]);\n"
    "      return;\n"
    "    }\n"
    "    final int insertAt = (_currentIndex + 1).clamp(0, _queue.length);\n"
    "    _queue.insert(insertAt, song);\n"
    "    queueRevision.value++;\n"
    "    _rebuildPlayOrder(anchorIndex: _currentIndex);\n"
    "    // Se inserta justo después de la actual en la cola del sistema.\n"
    "    final AudioSource? source = _player.audioSource;\n"
    "    if (source is ConcatenatingAudioSource) {\n"
    "      await source.insert(insertAt.clamp(0, source.children.length), _sourceFor(song));\n"
    "    } else {\n"
    "      await _loadQueueIntoPlayer(insertAt.clamp(0, _queue.length - 1), autoPlay: false);\n"
    "    }\n"
    "  }",
    label="playNext inserta en la cola del sistema",
)

patch(
    r"  Future<void> removeFromQueue\(String songId\) async \{.*?\n  \}",
    "  Future<void> removeFromQueue(String songId) async {\n"
    "    final int index = _queue.indexWhere((Song song) => song.id == songId);\n"
    "    if (index < 0) return;\n"
    "    _queue.removeAt(index);\n"
    "    queueRevision.value++;\n\n"
    "    final AudioSource? source = _player.audioSource;\n"
    "    if (source is ConcatenatingAudioSource && index < source.children.length) {\n"
    "      await source.removeAt(index);\n"
    "    }\n\n"
    "    if (_queue.isEmpty) {\n"
    "      await stopAndClear();\n"
    "      return;\n"
    "    }\n"
    "    if (index < _currentIndex) _currentIndex--;\n"
    "    _currentIndex = _currentIndex.clamp(0, _queue.length - 1);\n"
    "    _rebuildPlayOrder(anchorIndex: _currentIndex);\n"
    "    currentSong.value = _queue[_currentIndex];\n"
    "  }",
    flags=re.DOTALL,
    label="removeFromQueue respeta la cola del sistema",
)

# ============================================ 4. Núcleo: fuentes y carga de cola
patch(
    r"  Future<void> _loadIndex\(int queueIndex, \{bool autoPlay = true\}\) async \{.*?\n  \}",
    """  /// Fuente de audio de una canción, con los datos de la notificación.
  AudioSource _sourceFor(Song song) {
    final MediaItem mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist.isEmpty ? 'Artista desconocido' : song.artist,
      album: song.album.isEmpty ? null : song.album,
      genre: song.genre,
      duration: song.durationMs > 0 ? Duration(milliseconds: song.durationMs) : null,
      artUri: song.coverPath != null ? Uri.file(song.coverPath!) : null,
      extras: <String, dynamic>{'path': song.path},
    );
    return AudioSource.uri(
      song.path.startsWith('content://') ? Uri.parse(song.path) : Uri.file(song.path),
      tag: mediaItem,
    );
  }

  /// Fuentes de toda la cola, **en orden de cola**: el índice de secuencia del
  /// reproductor coincide siempre con el índice de la cola (sin desajustes).
  List<AudioSource> _buildSources() =>
      _queue.map((Song song) => _sourceFor(song)).toList();

  Future<void> _applyPlayerSettings() async {
    await _player.setVolume(_lastVolume);
    await _player.setSpeed(_speed / 100);
  }

  /// Carga TODA la cola en el reproductor. Esto es lo que hace que la sesión
  /// multimedia (pantalla de bloqueo, auriculares, reloj) conozca las canciones
  /// y pueda ofrecer siguiente/anterior.
  Future<void> _loadQueueIntoPlayer(int startIndex, {bool autoPlay = true}) async {
    if (_queue.isEmpty) return;
    final int start = startIndex.clamp(0, _queue.length - 1);
    _currentIndex = start;
    _playOrderIndex = _playOrder.indexOf(start);
    if (_playOrderIndex < 0) _playOrderIndex = 0;
    currentSong.value = _queue[start];
    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: _buildSources()),
        initialIndex: start,
        initialPosition: Duration.zero,
      );
      await _applyPlayerSettings();
      if (autoPlay) unawaited(_player.play());
      onSongStarted?.call(_queue[start]);
    } catch (error) {
      debugPrint('No se pudo cargar la cola: $error');
      // Intenta al menos la canción concreta.
      try {
        await _player.setAudioSource(_sourceFor(_queue[start]));
        if (autoPlay) unawaited(_player.play());
      } catch (innerError) {
        debugPrint('No se pudo reproducir ${_queue[start].path}: $innerError');
      }
    }
  }

  /// La sesión multimedia cambió de pista (bloqueo, auriculares, reloj…).
  void _onPlayerIndexChanged(int? sequenceIndex) {
    if (sequenceIndex == null ||
        sequenceIndex < 0 ||
        sequenceIndex >= _queue.length) {
      return;
    }
    if (sequenceIndex == _currentIndex) return;
    _currentIndex = sequenceIndex;
    _playOrderIndex = _playOrder.indexOf(sequenceIndex);
    if (_playOrderIndex < 0) _playOrderIndex = 0;
    currentSong.value = _queue[sequenceIndex];
    onSongStarted?.call(_queue[sequenceIndex]);
  }

  Future<void> _loadIndex(int queueIndex, {bool autoPlay = true}) async {
    if (queueIndex < 0 || queueIndex >= _queue.length) return;
    _currentIndex = queueIndex;
    final Song song = _queue[queueIndex];
    currentSong.value = song;
    final int orderIndex = _playOrder.indexOf(queueIndex);
    _playOrderIndex = orderIndex < 0 ? 0 : orderIndex;

    try {
      // Si el reproductor ya tiene la cola cargada, basta con saltar de pista.
      if (_player.audioSource is ConcatenatingAudioSource &&
          _player.sequence.length == _queue.length) {
        await _player.seek(Duration.zero, index: queueIndex);
        if (autoPlay && !_player.playing) unawaited(_player.play());
        onSongStarted?.call(song);
        return;
      }
      await _loadQueueIntoPlayer(queueIndex, autoPlay: autoPlay);
    } catch (error) {
      debugPrint('No se pudo reproducir ${song.path}: $error');
      // Salta a la siguiente canción disponible.
      if (_playOrderIndex + 1 < _playOrder.length) {
        await _loadIndex(_playOrder[_playOrderIndex + 1], autoPlay: autoPlay);
      }
    }
  }""",
    flags=re.DOTALL,
    label="núcleo: cola completa + fuentes + sincronización",
)

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
