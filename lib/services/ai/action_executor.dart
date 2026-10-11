import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart' show RepeatMode;
import 'ai_actions.dart';

/// Resultado legible de ejecutar una orden.
class ActionOutcome {
  const ActionOutcome(
    this.action,
    this.message, {
    this.ok = true,
    this.songId,
  });

  final AiAction action;
  final String message;
  final bool ok;

  /// Canción implicada (necesaria para acciones que abren la galería).
  final String? songId;

  /// La acción requiere que la interfaz abra el selector de imagen.
  bool get needsCoverPicker =>
      action.type == AiActionType.setCover && ok && songId != null;
}

/// Ejecuta las órdenes de la IA (o del lenguaje natural) sobre la app real:
/// reproduce, crea listas, edita metadatos, cambia ajustes y consulta el estado.
class ActionExecutor {
  ActionExecutor({
    required this.library,
    required this.player,
    required this.settings,
  });

  final LibraryProvider library;
  final PlayerProvider player;
  final SettingsProvider settings;

  Future<List<ActionOutcome>> runAll(List<AiAction> actions) async {
    final List<ActionOutcome> outcomes = <ActionOutcome>[];
    for (final AiAction action in actions) {
      if (action.type == AiActionType.unknown) continue;
      outcomes.add(await run(action));
    }
    return outcomes;
  }

  Future<ActionOutcome> run(AiAction action) async {
    try {
      switch (action.type) {
        case AiActionType.play:
          await player.service.play();
          return ActionOutcome(action, 'Reproduciendo ▶️');
        case AiActionType.pause:
          await player.service.pause();
          return ActionOutcome(action, 'En pausa ⏸️');
        case AiActionType.next:
          await player.next();
          return ActionOutcome(action, 'Siguiente canción ⏭️');
        case AiActionType.previous:
          await player.previous();
          return ActionOutcome(action, 'Canción anterior ⏮️');
        case AiActionType.stop:
          await player.stopAndClear();
          return ActionOutcome(action, 'Reproducción detenida');
        case AiActionType.seek:
          final int seconds = int.tryParse(action.value ?? '') ?? 0;
          await player.seek(Duration(seconds: seconds));
          return ActionOutcome(action, 'Salté a ${Formatters.duration(Duration(seconds: seconds))}');
        case AiActionType.volumeSet:
          final double volume = double.tryParse(action.value ?? '') ?? player.volume;
          await player.setVolume(volume.clamp(0.0, 1.0));
          return ActionOutcome(action, 'Volumen al ${(volume * 100).round()}% 🔊');
        case AiActionType.volumeUp:
          final double up = (player.volume + 0.15).clamp(0.0, 1.0);
          await player.setVolume(up);
          return ActionOutcome(action, 'Volumen al ${(up * 100).round()}% 🔊');
        case AiActionType.volumeDown:
          final double down = (player.volume - 0.15).clamp(0.0, 1.0);
          await player.setVolume(down);
          return ActionOutcome(action, 'Volumen al ${(down * 100).round()}% 🔉');
        case AiActionType.speedSet:
          final double speed = double.tryParse(action.value ?? '') ?? 1;
          final int percent = (speed * 100).round().clamp(50, 200);
          await player.setSpeedPercent(percent);
          return ActionOutcome(action, 'Velocidad ${(percent / 100).toStringAsFixed(2)}x ⏩');
        case AiActionType.shuffleOn:
          if (!player.isShuffleEnabled) player.toggleShuffle();
          return ActionOutcome(action, 'Aleatorio activado 🔀');
        case AiActionType.shuffleOff:
          if (player.isShuffleEnabled) player.toggleShuffle();
          return ActionOutcome(action, 'Aleatorio desactivado');
        case AiActionType.repeatOff:
          settings.service.setRepeatMode(RepeatMode.off);
          player.service.setRepeatMode(RepeatMode.off);
          return ActionOutcome(action, 'Repetición desactivada');
        case AiActionType.repeatAll:
          settings.service.setRepeatMode(RepeatMode.all);
          player.service.setRepeatMode(RepeatMode.all);
          return ActionOutcome(action, 'Repetir toda la cola 🔁');
        case AiActionType.repeatOne:
          settings.service.setRepeatMode(RepeatMode.one);
          player.service.setRepeatMode(RepeatMode.one);
          return ActionOutcome(action, 'Repetir esta canción 🔂');

        case AiActionType.playQuery:
          if ((action.query ?? '').trim().isEmpty) {
            await player.service.play();
            return ActionOutcome(action, 'Reproduciendo ▶️');
          }
          final List<Song> matches = _findSongs(action.query);
          if (matches.isEmpty) {
            return ActionOutcome(
              action,
              'No encontré «${action.query}» en tu biblioteca. Prueba con otro título o actualiza la biblioteca.',
              ok: false,
            );
          }
          await player.setQueue(matches);
          final Song first = matches.first;
          return ActionOutcome(
            action,
            'Reproduciendo «${first.title}» — ${first.artist}'
            '${matches.length > 1 ? ' (y ${matches.length - 1} más)' : ''} 🎵',
            songId: first.id,
          );

        case AiActionType.playPlaylist:
          final String wanted = action.playlistName ?? action.query ?? '';
          final Playlist? playlist = _findPlaylist(wanted);
          if (playlist == null) {
            return ActionOutcome(action, 'No existe ninguna lista llamada «$wanted».', ok: false);
          }
          final List<Song> songs = library.songsOf(playlist);
          if (songs.isEmpty) {
            return ActionOutcome(action, 'La lista «${playlist.name}» está vacía.', ok: false);
          }
          await player.setQueue(songs);
          return ActionOutcome(action, 'Reproduciendo la lista «${playlist.name}» (${songs.length} canciones) 🎶');

        case AiActionType.createPlaylist:
          final List<Song> songs = _findSongs(action.query, limit: action.count ?? 30);
          final String name = (action.playlistName ?? '').trim().isEmpty
              ? 'Lista IA ${DateTime.now().day}/${DateTime.now().month}'
              : action.playlistName!.trim();
          final Playlist created = await library.createPlaylist(
            name: name,
            description: action.query == null ? 'Creada por la IA' : 'IA · ${action.query}',
            songIds: songs.map((Song song) => song.id).toList(),
            isAiGenerated: true,
            aiPrompt: action.query,
          );
          return ActionOutcome(
            action,
            'Lista «${created.name}» creada con ${songs.length} canciones 📝',
            songId: created.id,
          );

        case AiActionType.addToPlaylist:
          final String wanted = (action.playlistName ?? '').trim();
          Playlist? playlist = _findPlaylist(wanted);
          List<Song> songs = _findSongs(action.query, limit: 50);
          if (songs.isEmpty) {
            final Song? current = player.current;
            if (current != null) songs = <Song>[current];
          }
          if (songs.isEmpty) {
            return ActionOutcome(action, 'No encontré canciones para añadir.', ok: false);
          }
          playlist ??= await library.createPlaylist(
            name: wanted.isEmpty ? 'Lista IA' : wanted,
            description: 'Creada por la IA',
            isAiGenerated: true,
          );
          await library.addSongsToPlaylist(
            playlist.id,
            songs.map((Song song) => song.id).toList(),
          );
          return ActionOutcome(
            action,
            '${songs.length} canción(es) añadidas a «${playlist.name}» ✅',
          );

        case AiActionType.searchLibrary:
          final List<Song> found = _findSongs(action.query, limit: 60);
          library.setQuery(action.query ?? '');
          return ActionOutcome(
            action,
            found.isEmpty
                ? 'Sin resultados para «${action.query}».'
                : '${found.length} resultados para «${action.query}» — los tienes en la pestaña Canciones 🔍',
            ok: found.isNotEmpty,
          );

        case AiActionType.editMetadata:
          final List<Song> matches = _findSongs(action.query, limit: 1);
          final Song? song = matches.isEmpty ? null : matches.first;
          if (song == null) {
            return ActionOutcome(action, 'No encontré la canción «${action.query}».', ok: false);
          }
          final Song updated = _applyField(song, action.field, action.value);
          await library.saveSong(updated);
          return ActionOutcome(
            action,
            'Actualizado «${updated.title}»: ${_fieldLabel(action.field)} = ${action.value ?? ''} ✏️',
            songId: song.id,
          );

        case AiActionType.setCover:
          final List<Song> coverMatches = _findSongs(action.query, limit: 1);
          final Song? coverSong = coverMatches.isEmpty ? null : coverMatches.first;
          if (coverSong == null) {
            return ActionOutcome(action, 'No encontré la canción para cambiar la carátula.', ok: false);
          }
          return ActionOutcome(
            action,
            'Elige la nueva carátula de «${coverSong.title}» 🖼️',
            songId: coverSong.id,
          );

        case AiActionType.toggleFavorite:
          final List<Song> favMatches = _findSongs(action.query, limit: 1);
          final Song? song = (favMatches.isEmpty ? null : favMatches.first) ?? player.current;
          if (song == null) {
            return ActionOutcome(action, 'No encontré la canción.', ok: false);
          }
          await library.toggleFavorite(song.id);
          final bool isFav = library.songById(song.id)?.isFavorite ?? false;
          return ActionOutcome(
            action,
            isFav ? '«${song.title}» marcada como favorita ❤️' : '«${song.title}» ya no es favorita',
          );

        case AiActionType.rescanLibrary:
          final int added = await library.autoScan(force: true);
          return ActionOutcome(
            action,
            added == 0
                ? 'Biblioteca al día: no hay canciones nuevas (${library.songs.length} en total) 📚'
                : 'Actualizada: $added canciones nuevas añadidas 📚',
          );

        case AiActionType.nowPlaying:
          final Song? current = player.current;
          if (current == null) {
            return ActionOutcome(action, 'No hay nada sonando ahora mismo.', ok: false);
          }
          return ActionOutcome(
            action,
            'Suena «${current.title}» de ${current.artist} (${current.genre}) 🎧',
          );

        case AiActionType.libraryStats:
          return ActionOutcome(action, _stats());

        case AiActionType.help:
          return ActionOutcome(action, _help());

        case AiActionType.unknown:
          return ActionOutcome(action, '', ok: false);
      }
    } catch (error) {
      debugPrint('No se pudo ejecutar ${action.type}: $error');
      return ActionOutcome(action, 'No pude ejecutar «${action.label}»: $error', ok: false);
    }
  }

  // ------------------------------------------------------------------ utilidades

  List<Song> _findSongs(String? query, {int limit = 30}) {
    final String clean = (query ?? '').trim();
    if (clean.isEmpty) {
      return library.songs.take(limit).toList();
    }
    return library.service.search(clean, limit: limit);
  }

  Playlist? _findPlaylist(String name) {
    final String clean = name.trim().toLowerCase();
    if (clean.isEmpty) return null;
    Playlist? best;
    double bestScore = 0;
    for (final Playlist playlist in library.playlists) {
      if (playlist.name.toLowerCase() == clean) return playlist;
      final double score = Formatters.similarity(playlist.name, name);
      if (score > bestScore) {
        bestScore = score;
        best = playlist;
      }
    }
    return bestScore >= 0.55 ? best : null;
  }

  Song _applyField(Song song, String? field, String? value) {
    final String v = (value ?? '').trim();
    switch ((field ?? '').toLowerCase()) {
      case 'titulo':
      case 'título':
        return song.copyWith(title: v.isEmpty ? song.title : v);
      case 'artista':
        return song.copyWith(artist: v.isEmpty ? song.artist : v);
      case 'album':
      case 'álbum':
        return song.copyWith(album: v);
      case 'anio':
      case 'año':
        return song.copyWith(year: int.tryParse(RegExp(r'\d{4}').firstMatch(v)?.group(0) ?? '') ?? song.year);
      case 'genero':
      case 'género':
        return song.copyWith(genre: GenreCatalog.normalize(v));
      case 'tags':
      case 'etiquetas':
        return song.copyWith(
          tags: v.split(RegExp(r'[,\s]+')).where((String tag) => tag.isNotEmpty).toList(),
        );
      default:
        return song;
    }
  }

  String _fieldLabel(String? field) {
    switch ((field ?? '').toLowerCase()) {
      case 'titulo':
      case 'título':
        return 'título';
      case 'artista':
        return 'artista';
      case 'album':
      case 'álbum':
        return 'álbum';
      case 'anio':
      case 'año':
        return 'año';
      case 'genero':
      case 'género':
        return 'género';
      case 'tags':
      case 'etiquetas':
        return 'etiquetas';
      default:
        return field ?? 'dato';
    }
  }

  String _stats() {
    final List<Song> songs = library.songs;
    final int playlists = library.playlists.length;
    final Map<String, int> genres = <String, int>{};
    for (final Song song in songs) {
      genres[song.genre] = (genres[song.genre] ?? 0) + 1;
    }
    final List<MapEntry<String, int>> top = genres.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    final String topGenre = top.isEmpty ? '—' : '${top.first.key} (${top.first.value})';
    final int favorites = songs.where((Song song) => song.isFavorite).length;
    return 'Tienes ${songs.length} canciones, $playlists listas y $favorites favoritas. '
        'Género dominante: $topGenre 📊';
  }

  String _help() => 'Puedo ejecutar lo que me escribas. Ejemplos:\n'
      '• «pon cumbia» / «reproduce Bad Bunny»\n'
      '• «crea una lista de 20 canciones para entrenar»\n'
      '• «añade esta canción a la lista Fiesta»\n'
      '• «cambia el género de esta canción a Rock»\n'
      '• «sube el volumen al 80%», «velocidad 1.5x», «aleatorio»\n'
      '• «actualiza mi biblioteca», «¿qué suena?», «cuántas canciones tengo»';
}
