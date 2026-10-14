import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' hide RepeatMode;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/song.dart';
import 'settings_service.dart';

/// Motor de reproducción: cola personalizable, orden aleatorio, repetición,
/// notificación de reproducción y control del wakelock (pantalla encendida).
///
/// Se gestiona la cola manualmente (sin `ConcatenatingAudioSource`) para que la
/// app funcione igual con just_audio 0.9 y 0.10, y para poder aplicar la lógica
/// del "Modo DJ IA" (elegir la siguiente canción desde cualquier punto).
class PlayerService {
  PlayerService() {
    _player.processingStateStream.listen((ProcessingState state) {
      if (state == ProcessingState.completed) {
        _handleCompletion();
      }
    });

    _player.playerStateStream.listen((PlayerState state) {
      _syncWakelock(state.playing);
      // Se cuenta la reproducción cuando el audio suena de verdad.
      if (state.playing) _registrarInicioDeReproduccion();
    });

    // La sesión multimedia (bloqueo, auriculares, reloj…) puede cambiar de
    // pista por su cuenta: aquí se sincroniza el estado de la app.
    _player.currentIndexStream.listen(_onPlayerIndexChanged);
  }

  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  final List<Song> _queue = <Song>[];
  final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);
  final ValueNotifier<int> queueRevision = ValueNotifier<int>(0);

  List<int> _playOrder = <int>[];
  int _playOrderIndex = 0;
  int _currentIndex = -1;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;
  bool _advancing = false;
  bool _keepScreenOn = true;
  int _speed = 100; // 1.00x

  /// La biblioteca registra aquí la reproducción para las estadísticas.
  void Function(Song song)? onSongStarted;

  /// Cola DJ infinita: si se define, se llama al llegar a la ultima cancion
  /// de la cola para pedir mas (el proveedor de IA encola otras 15).
  Future<List<Song>> Function(Song actual)? onColaAgotada;

  /// Últimos errores de reproducción (se muestran en el diagnóstico).
  final List<String> ultimosErrores = <String>[];

  /// Última canción cuya reproducción ya se contó para el ranking
  /// (evita duplicados al preparar colas o al cambiar de pista).
  String? _ultimaReproduccionRegistrada;

  /// Canciones ya reproducidas en la pasada actual de aleatorio.
  final Set<String> _sonadasEnPasada = <String>{};

  /// Cuenta la reproduccion solo si la cancion sigue sonando a los 20 s.
  Timer? _temporizadorRecuento;

  /// Cuenta una reproducción **solo si el audio está sonando**, una vez por
  /// canción. Así, cargar una cola o pulsar «aleatorio» sin arrancar no
  /// infla el ranking.
  void _registrarInicioDeReproduccion() {
    if (!_player.playing) return;
    // Se usa el índice PROPIO (el que se acaba de cargar), no el del
    // reproductor: al arrancar el audio, `currentIndex` puede llegar aún con
    // el valor anterior y la reproducción se sumaba a la canción equivocada
    // (normalmente la primera de la lista).
    final int indice = (_currentIndex >= 0 && _currentIndex < _queue.length)
        ? _currentIndex
        : (_player.currentIndex ?? -1);
    if (indice < 0 || indice >= _queue.length) return;
    final Song cancion = _queue[indice];
    _sonadasEnPasada.add(cancion.id);
    if (_ultimaReproduccionRegistrada == cancion.id) return;
    // Se cuenta a los 20 s de reproduccion real: un salto rapido no infla el
    // ranking. Si la cancion cambia antes, el temporizador se cancela.
    _temporizadorRecuento?.cancel();
    final int indiceContado = indice;
    final String idContado = cancion.id;
    _temporizadorRecuento = Timer(const Duration(seconds: 20), () {
      if (!_player.playing) return;
      if ((_player.currentIndex ?? _currentIndex) != indiceContado) return;
      if (_ultimaReproduccionRegistrada == idContado) return;
      _ultimaReproduccionRegistrada = idContado;
      onSongStarted?.call(cancion);
    });
    if (_currentIndex != indice) {
      _currentIndex = indice;
      _playOrderIndex = _playOrder.indexOf(indice);
      if (_playOrderIndex < 0) _playOrderIndex = 0;
      currentSong.value = cancion;
    }
    onSongStarted?.call(cancion);
  }

  void _registrarError(String mensaje) {
    ultimosErrores.insert(0, mensaje);
    if (ultimosErrores.length > 6) ultimosErrores.removeLast();
  }

  AudioPlayer get player => _player;
  List<Song> get queue => List<Song>.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _shuffle;
  RepeatMode get repeatMode => _repeat;

  Song? get current => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  bool get hasNext {
    if (_queue.isEmpty) return false;
    if (_shuffle || _repeat == RepeatMode.all) return true;
    return _playOrderIndex + 1 < _playOrder.length;
  }

  bool get hasPrevious {
    if (_queue.isEmpty) return false;
    if (_shuffle || _repeat == RepeatMode.all) return true;
    return _playOrderIndex > 0;
  }

  /// Velocidad de reproducción en porcentaje (100 = 1.0x).
  int get speedPercent => _speed;

  // ------------------------------------------------------------------ cola

  /// Carga una lista completa y empieza por [startIndex].
  Future<void> setQueue(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    _queue
      ..clear()
      ..addAll(songs);
    queueRevision.value++;
    if (_queue.isEmpty) {
      _currentIndex = -1;
      currentSong.value = null;
      await _player.stop();
      return;
    }
    final int start = startIndex.clamp(0, _queue.length - 1);
    _rebuildPlayOrder(anchorIndex: start);
    // Se carga TODA la cola en el reproductor (no solo una canción): es lo que
    // permite que la pantalla de bloqueo ofrezca siguiente/anterior.
    await _loadQueueIntoPlayer(start, autoPlay: autoPlay);
  }

  /// Reproduce una canción dentro de un contexto (por ejemplo, el resultado de
  /// una búsqueda o el contenido de una lista).
  Future<void> playSong(Song song, {List<Song>? context}) async {
    if (context != null && context.isNotEmpty) {
      final int index = context.indexWhere((Song s) => s.id == song.id);
      await setQueue(context, startIndex: index < 0 ? 0 : index);
      return;
    }
    await setQueue(<Song>[song], startIndex: 0);
  }

  /// Añade canciones al final de la cola.
  Future<void> enqueue(List<Song> songs, {bool playIfEmpty = true}) async {
    if (songs.isEmpty) return;
    final bool wasEmpty = _queue.isEmpty;
    _queue.addAll(songs);
    queueRevision.value++;
    if (wasEmpty && playIfEmpty) {
      _rebuildPlayOrder(anchorIndex: 0);
      await _loadQueueIntoPlayer(0);
      return;
    }
    _rebuildPlayOrder(anchorIndex: _currentIndex);
    if (wasEmpty) return;
    // Se añaden al final de la cola del sistema sin cortar la reproducción.
    final AudioSource? source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      for (final Song song in songs) {
        await source.add(_sourceFor(song));
      }
    } else {
      await _loadQueueIntoPlayer(_currentIndex < 0 ? 0 : _currentIndex,
          autoPlay: false);
    }
  }

  /// Inserta una canción justo después de la actual (Modo DJ IA).
  Future<void> playNext(Song song) async {
    if (_queue.isEmpty) {
      await setQueue(<Song>[song]);
      return;
    }
    final int insertAt = (_currentIndex + 1).clamp(0, _queue.length);
    _queue.insert(insertAt, song);
    queueRevision.value++;
    _rebuildPlayOrder(anchorIndex: _currentIndex);
    // Se inserta justo después de la actual en la cola del sistema.
    final AudioSource? source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      await source.insert(insertAt.clamp(0, source.children.length), _sourceFor(song));
    } else {
      await _loadQueueIntoPlayer(insertAt.clamp(0, _queue.length - 1), autoPlay: false);
    }
  }

  Future<void> removeFromQueue(String songId) async {
    final int index = _queue.indexWhere((Song song) => song.id == songId);
    if (index < 0) return;
    _queue.removeAt(index);
    queueRevision.value++;

    final AudioSource? source = _player.audioSource;
    if (source is ConcatenatingAudioSource && index < source.children.length) {
      await source.removeAt(index);
    }

    if (_queue.isEmpty) {
      await stopAndClear();
      return;
    }
    if (index < _currentIndex) _currentIndex--;
    _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
    _rebuildPlayOrder(anchorIndex: _currentIndex);
    currentSong.value = _queue[_currentIndex];
  }

  /// Reemplaza la canción actual conservando la posición (evita cortes al
  /// actualizar metadatos o carátulas).
  Future<void> refreshCurrentSong(Song updated) async {
    final int index = _queue.indexWhere((Song s) => s.id == updated.id);
    if (index < 0) return;
    _queue[index] = updated;
    queueRevision.value++;
    if (index == _currentIndex) {
      currentSong.value = updated;
    }
  }

  /// Canciones que vienen después de la actual.
  List<Song> upcoming({int count = 25}) {
    if (_queue.isEmpty) return <Song>[];
    final List<Song> result = <Song>[];
    for (int i = _playOrderIndex + 1; i < _playOrder.length && result.length < count; i++) {
      result.add(_queue[_playOrder[i]]);
    }
    return result;
  }

  // ------------------------------------------------------------------ control

  Future<void> togglePlayPause() async {
    if (_queue.isEmpty) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> play() async {
    if (_queue.isEmpty) return;
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> next({bool auto = false}) async {
    if (_queue.isEmpty) return;

    if (auto && _repeat == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    if (_playOrderIndex + 1 < _playOrder.length) {
      _playOrderIndex++;
      await _loadIndex(_playOrder[_playOrderIndex]);
      return;
    }

    if (_repeat == RepeatMode.all || _shuffle) {
      _rebuildPlayOrder(anchorIndex: -1);
      _playOrderIndex = 0;
      if (_playOrder.isNotEmpty) {
        await _loadIndex(_playOrder.first);
      }
      return;
    }

    // Fin de la cola sin repetición.
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    // Si ya pasaron más de 3 s, "anterior" reinicia la canción actual.
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_playOrderIndex > 0) {
      _playOrderIndex--;
      await _loadIndex(_playOrder[_playOrderIndex]);
    } else if (_repeat == RepeatMode.all || _shuffle) {
      _rebuildPlayOrder(anchorIndex: -1);
      _playOrderIndex = _playOrder.length - 1;
      await _loadIndex(_playOrder.last);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> seekBy(Duration delta) async {
    final Duration current = _player.position;
    final Duration target = current + delta;
    final Duration? duration = _player.duration;
    Duration clamped = target < Duration.zero ? Duration.zero : target;
    if (duration != null && clamped > duration) clamped = duration;
    await _player.seek(clamped);
  }

  Future<void> setVolume(double value) => _player.setVolume(value.clamp(0.0, 1.0));

  /// Velocidad expresada en porcentaje (50..200 → 0.5x..2.0x).
  Future<void> setSpeedPercent(int percent) async {
    _speed = percent.clamp(50, 200);
    await _player.setSpeed(_speed / 100);
  }

  void setKeepScreenOn(bool value) {
    _keepScreenOn = value;
    _syncWakelock(_player.playing);
  }

  // ------------------------------------------------------------------ modos

  void setShuffle(bool enabled) {
    if (_shuffle == enabled) return;
    _shuffle = enabled;
    _rebuildPlayOrder(anchorIndex: _currentIndex);
  }

  void setRepeatMode(RepeatMode mode) {
    _repeat = mode;
  }

  /// Alterna aleatorio y devuelve el estado nuevo.
  bool toggleShuffle() {
    setShuffle(!_shuffle);
    return _shuffle;
  }

  /// Ciclo: sin repetición → repetir todo → repetir una.
  RepeatMode cycleRepeatMode() {
    final RepeatMode next = switch (_repeat) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    _repeat = next;
    return next;
  }

  // ------------------------------------------------------------------ interno

  /// Fuente de audio de una canción, con los datos de la notificación.
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
  List<AudioSource> _buildSources() => _queue
      // Se descartan entradas sin fuente utilizable: una sola mala evitaba
      // que se cargase la cola entera.
      .map((Song song) => song.path.trim())
      .where((String path) => path.isNotEmpty)
      .map((String path) => _sourceFor(_queue.firstWhere((Song song) => song.path == path)))
      .toList();

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
      // No se cuenta aquí: lo hará el estado del reproductor cuando suene.
      if (autoPlay) unawaited(_player.play());
    } catch (error) {
      debugPrint('No se pudo cargar la cola: $error');
      _registrarError('Cola: $error');
      // Intenta al menos la canción concreta.
      try {
        await _player.setAudioSource(_sourceFor(_queue[start]));
        if (autoPlay) unawaited(_player.play());
      } catch (innerError) {
        debugPrint('No se pudo reproducir ${_queue[start].path}: $innerError');
        _registrarError('Cancion: $innerError');
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
    _registrarInicioDeReproduccion();
    // Cola DJ infinita: si suena la ultima y hay gancho, se piden mas canciones.
    if (sequenceIndex == _queue.length - 1 && onColaAgotada != null) {
      final Future<List<Song>> Function(Song) gancho = onColaAgotada!;
      unawaited(gancho(_queue[sequenceIndex]).then((List<Song> mas) {
        if (mas.isNotEmpty) enqueue(mas, playIfEmpty: false);
      }));
    }
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
        if (autoPlay && !_player.playing) {
          unawaited(_player.play());
        } else {
          // Si ya estaba sonando, el cambio de pista no emite un nuevo
          // «reproduciendo»: se cuenta aquí, una vez por canción.
          _registrarInicioDeReproduccion();
        }
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
  }

  /// Salta directamente a una posición de la cola (usado por la lista "a continuación").
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _rebuildPlayOrder(anchorIndex: index);
    await _loadIndex(index);
  }

  /// Detiene y vacía la cola (por ejemplo al borrar la canción actual).
  Future<void> stopAndClear() async {
    _queue.clear();
    _currentIndex = -1;
    _playOrder = <int>[];
    _playOrderIndex = 0;
    currentSong.value = null;
    queueRevision.value++;
    await _player.stop();
  }

  double _lastVolume = 1.0;

  @override
  void dispose() {
    _player.dispose();
    currentSong.dispose();
    queueRevision.dispose();
  }

  Future<void> _handleCompletion() async {
    if (_advancing) return;
    _advancing = true;
    try {
      await next(auto: true);
    } finally {
      _advancing = false;
    }
  }

  void _rebuildPlayOrder({int? anchorIndex}) {
    final int anchor = anchorIndex ?? _currentIndex;
    final List<int> indices = List<int>.generate(_queue.length, (int i) => i);
    if (_shuffle) {
      // Aleatorio sin repeticiones: suenan primero las que no han sonado en la
      // pasada actual; cuando se agotan, empieza una pasada nueva.
      final List<int> nuevas = indices
          .where((int i) => !_sonadasEnPasada.contains(_queue[i].id))
          .toList();
      final List<int> repetidas = indices
          .where((int i) => _sonadasEnPasada.contains(_queue[i].id))
          .toList();
      if (nuevas.isEmpty) _sonadasEnPasada.clear();
      nuevas.shuffle(_random);
      repetidas.shuffle(_random);
      indices
        ..clear()
        ..addAll(nuevas.isEmpty ? repetidas : <int>[...nuevas, ...repetidas]);
      if (anchor >= 0 && anchor < _queue.length) {
        indices.remove(anchor);
        indices.insert(0, anchor);
      }
    }
    _playOrder = indices;
    if (anchor >= 0) {
      final int position = indices.indexOf(anchor);
      _playOrderIndex = position < 0 ? 0 : position;
    } else {
      _playOrderIndex = 0;
    }
  }

  void _syncWakelock(bool playing) {
    try {
      if (playing && _keepScreenOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (_) {
      // Plataformas sin soporte de wakelock: se ignora.
    }
  }

  /// Mantiene el volumen guardado en ajustes (se reaplica al cambiar de pista).
  void rememberVolume(double value) => _lastVolume = value.clamp(0.0, 1.0);
}
