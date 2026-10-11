import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' hide RepeatMode;

import '../models/song.dart';
import '../services/player_service.dart';
import '../services/settings_service.dart';
import '../services/ai/ai_bridge.dart';
import 'library_provider.dart';

/// Estado del reproductor: se apoya en [PlayerService] y notifica a la interfaz
/// solo cuando cambia algo relevante (evita repintados innecesarios a 120 Hz).
class PlayerProvider extends ChangeNotifier {
  PlayerProvider({
    required LibraryProvider library,
    required SettingsService settings,
  })  : _library = library,
        _settings = settings,
        service = PlayerService() {
    service.currentSong.addListener(_onSongChanged);
    _currentSubscription = () => service.currentSong.removeListener(_onSongChanged);
    service.onSongStarted = _onSongStarted;
    _bind();
    AiBridge.player = this;
  }

  final LibraryProvider _library;
  final SettingsService _settings;
  final PlayerService service;

  late final VoidCallback _currentSubscription;
  final List<Song> _recentlyPlayed = <Song>[];

  Song? get current => service.current;
  bool get playing => service.player.playing;
  bool get isShuffleEnabled => service.isShuffleEnabled;
  RepeatMode get repeatMode => service.repeatMode;
  List<Song> get queue => service.queue;
  List<Song> get recentlyPlayed => List<Song>.unmodifiable(_recentlyPlayed);
  bool get hasSong => current != null;
  int get speedPercent => service.speedPercent;

  Stream<Duration> get positionStream => service.player.positionStream;
  Stream<Duration?> get durationStream => service.player.durationStream;
  Stream<Duration> get bufferedStream => service.player.bufferedPositionStream;
  Stream<PlayerState> get playerStateStream => service.player.playerStateStream;
  Stream<ProcessingState> get processingStateStream => service.player.processingStateStream;

  Duration get position => service.player.position;
  Duration? get duration => service.player.duration;
  double get volume => service.player.volume;

  void _bind() {
    // Restaura los modos guardados por el usuario.
    service.setShuffle(_settings.shuffle);
    service.setRepeatMode(_settings.repeatMode);
    service.setKeepScreenOn(_settings.keepScreenOn);
    service.rememberVolume(_settings.volume);
    unawaited(service.setVolume(_settings.volume));
    unawaited(service.setSpeedPercent(speedPercent));
  }

  void _onSongChanged() => notifyListeners();

  void _onSongStarted(Song song) {
    _recentlyPlayed.removeWhere((Song s) => s.id == song.id);
    _recentlyPlayed.insert(0, song);
    if (_recentlyPlayed.length > 40) _recentlyPlayed.removeLast();
    // Estadísticas para las recomendaciones de la IA.
    unawaited(_library.registerPlay(song.id));
    notifyListeners();
  }

  // ------------------------------------------------------------------ acciones

  Future<void> playSong(Song song, {List<Song>? context}) async {
    await service.playSong(song, context: context);
    notifyListeners();
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0, bool autoPlay = true}) async {
    await service.setQueue(songs, startIndex: startIndex, autoPlay: autoPlay);
    notifyListeners();
  }

  Future<void> enqueue(List<Song> songs) async {
    await service.enqueue(songs);
    notifyListeners();
  }

  Future<void> playNext(Song song) async {
    await service.playNext(song);
    notifyListeners();
  }

  Future<void> removeFromQueue(String songId) async {
    await service.removeFromQueue(songId);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    await service.togglePlayPause();
    notifyListeners();
  }

  Future<void> next() async {
    await service.next();
    notifyListeners();
  }

  /// Salta a una canción concreta de la cola actual.
  Future<void> playAtIndex(int index) async {
    await service.playAtIndex(index);
    notifyListeners();
  }

  Future<void> previous() async {
    await service.previous();
    notifyListeners();
  }

  Future<void> seek(Duration position) => service.seekTo(position);

  Future<void> seekBy(Duration delta) => service.seekBy(delta);

  Future<void> setVolume(double value) async {
    await service.setVolume(value);
    await _settings.setVolume(value);
    service.rememberVolume(value);
    notifyListeners();
  }

  Future<void> setSpeedPercent(int percent) async {
    await service.setSpeedPercent(percent);
    notifyListeners();
  }

  bool toggleShuffle() {
    final bool value = service.toggleShuffle();
    unawaited(_settings.setShuffle(value));
    notifyListeners();
    return value;
  }

  RepeatMode cycleRepeatMode() {
    final RepeatMode mode = service.cycleRepeatMode();
    unawaited(_settings.setRepeatMode(mode));
    notifyListeners();
    return mode;
  }

  void setKeepScreenOn(bool value) {
    service.setKeepScreenOn(value);
    unawaited(_settings.setKeepScreenOn(value));
  }

  /// Detiene y vacía la cola (por ejemplo al borrar la canción actual).
  Future<void> stopAndClear() async {
    await service.stopAndClear();
    notifyListeners();
  }

  @override
  void dispose() {
    _currentSubscription();
    service.dispose();
    super.dispose();
  }
}
