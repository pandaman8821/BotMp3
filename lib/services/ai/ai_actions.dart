import 'dart:convert';

/// Acciones que BotMp3 puede ejecutar a partir de una frase escrita o dictada.
///
/// El motor entiende dos fuentes:
///  1. **IA**: bloques `<CMD>{"accion":"reproducir","consulta":"..."}</CMD>` que el
///     modelo añade a su respuesta (o un objeto JSON con la clave `acciones`).
///  2. **Reglas locales**: frases en español/inglés, para que los comandos
///     funcionen incluso sin API key o sin conexión.
enum AiActionType {
  play,
  pause,
  next,
  previous,
  stop,
  volumeSet,
  volumeUp,
  volumeDown,
  speedSet,
  shuffleOn,
  shuffleOff,
  repeatOff,
  repeatAll,
  repeatOne,
  seek,
  playQuery,
  playPlaylist,
  createPlaylist,
  addToPlaylist,
  searchLibrary,
  editMetadata,
  setCover,
  toggleFavorite,
  rescanLibrary,
  nowPlaying,
  libraryStats,
  help,
  unknown,
}

/// Una orden concreta lista para ejecutarse.
class AiAction {
  const AiAction(
    this.type, {
    this.query,
    this.playlistName,
    this.field,
    this.value,
    this.count,
    this.raw = '',
  });

  final AiActionType type;

  /// Canción, artista, álbum, género o texto libre de búsqueda.
  final String? query;

  /// Nombre de la lista implicada (crear, reproducir o añadir).
  final String? playlistName;

  /// Campo de metadatos a editar: titulo | artista | album | anio | genero | tags
  final String? field;

  /// Valor nuevo del campo, valor numérico (volumen/velocidad) o modo de repetición.
  final String? value;

  /// Número de canciones (para crear listas).
  final int? count;

  final String raw;

  /// Descripción corta para mostrar en la interfaz.
  String get label {
    switch (type) {
      case AiActionType.play:
        return 'Reproducir';
      case AiActionType.pause:
        return 'Pausar';
      case AiActionType.next:
        return 'Siguiente canción';
      case AiActionType.previous:
        return 'Canción anterior';
      case AiActionType.stop:
        return 'Detener';
      case AiActionType.volumeSet:
        return 'Volumen ${value ?? ''}';
      case AiActionType.volumeUp:
        return 'Subir volumen';
      case AiActionType.volumeDown:
        return 'Bajar volumen';
      case AiActionType.speedSet:
        return 'Velocidad ${value ?? ''}x';
      case AiActionType.shuffleOn:
        return 'Aleatorio activado';
      case AiActionType.shuffleOff:
        return 'Aleatorio desactivado';
      case AiActionType.repeatOff:
        return 'Repetición desactivada';
      case AiActionType.repeatAll:
        return 'Repetir toda la cola';
      case AiActionType.repeatOne:
        return 'Repetir esta canción';
      case AiActionType.seek:
        return 'Saltar a ${value ?? ''} s';
      case AiActionType.playQuery:
        return 'Reproducir «${query ?? ''}»';
      case AiActionType.playPlaylist:
        return 'Reproducir lista «${playlistName ?? query ?? ''}»';
      case AiActionType.createPlaylist:
        return 'Crear lista «${playlistName ?? ''}»';
      case AiActionType.addToPlaylist:
        return 'Añadir a «${playlistName ?? ''}»';
      case AiActionType.searchLibrary:
        return 'Buscar «${query ?? ''}»';
      case AiActionType.editMetadata:
        return 'Editar ${field ?? 'datos'} de «${query ?? ''}»';
      case AiActionType.setCover:
        return 'Cambiar carátula de «${query ?? ''}»';
      case AiActionType.toggleFavorite:
        return 'Favorito: «${query ?? ''}»';
      case AiActionType.rescanLibrary:
        return 'Actualizar biblioteca';
      case AiActionType.nowPlaying:
        return '¿Qué suena?';
      case AiActionType.libraryStats:
        return 'Estadísticas de la biblioteca';
      case AiActionType.help:
        return 'Ayuda de comandos';
      case AiActionType.unknown:
        return '';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accion': type.name,
        if (query != null) 'consulta': query,
        if (playlistName != null) 'lista': playlistName,
        if (field != null) 'campo': field,
        if (value != null) 'valor': value,
        if (count != null) 'cantidad': count,
      };
}

/// Interpreta las órdenes de la IA y, como respaldo, el lenguaje natural.
class AiActionParser {
  const AiActionParser._();

  static final RegExp _block = RegExp(
    r'<CMD>(.*?)</CMD>',
    caseSensitive: false,
    dotAll: true,
  );

  /// Extrae las acciones de la respuesta del modelo y devuelve el texto limpio.
  static (String text, List<AiAction> actions) fromAiReply(String reply) {
    final List<AiAction> actions = <AiAction>[];
    for (final RegExpMatch match in _block.allMatches(reply)) {
      final Map<String, dynamic>? json = _decode(match.group(1) ?? '');
      if (json == null) continue;
      if (json['acciones'] is List) {
        for (final dynamic item in json['acciones'] as List<dynamic>) {
          if (item is Map<String, dynamic>) {
            final AiAction? action = _fromMap(item);
            if (action != null) actions.add(action);
          }
        }
      } else {
        final AiAction? action = _fromMap(json);
        if (action != null) actions.add(action);
      }
    }
    final String clean = reply.replaceAll(_block, '').trim();
    return (clean, actions);
  }

  static Map<String, dynamic>? _decode(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static AiAction? _fromMap(Map<String, dynamic> map) {
    final String rawAction = (map['accion'] ??
            map['action'] ??
            map['cmd'] ??
            map['command'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (rawAction.isEmpty) return null;

    final String? query = _firstString(map, <String>['consulta', 'query', 'buscar', 'cancion', 'canción']);
    final String? playlist = _firstString(map, <String>['lista', 'playlist', 'nombre_lista']);
    final String? field = _firstString(map, <String>['campo', 'field']);
    final String? value = _firstString(map, <String>['valor', 'value', 'modo', 'mode']);
    final int? count = int.tryParse((map['cantidad'] ?? map['count'] ?? '').toString());

    return AiAction(
      typeFromName(rawAction, value: value),
      query: query,
      playlistName: playlist ?? (rawAction.contains('lista') ? query : null),
      field: field,
      value: value,
      count: count,
      raw: jsonEncode(map),
    );
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final Object? value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  /// Traduce el nombre de la acción (español o inglés) al enum.
  static AiActionType typeFromName(String name, {String? value}) {
    switch (name) {
      case 'reproducir':
      case 'play':
        return AiActionType.play;
      case 'pausar':
      case 'pausa':
      case 'pause':
        return AiActionType.pause;
      case 'siguiente':
      case 'next':
        return AiActionType.next;
      case 'anterior':
      case 'previous':
      case 'prev':
        return AiActionType.previous;
      case 'detener':
      case 'stop':
        return AiActionType.stop;
      case 'volumen':
      case 'volume':
        return AiActionType.volumeSet;
      case 'subir_volumen':
      case 'volume_up':
        return AiActionType.volumeUp;
      case 'bajar_volumen':
      case 'volume_down':
        return AiActionType.volumeDown;
      case 'velocidad':
      case 'speed':
        return AiActionType.speedSet;
      case 'aleatorio':
      case 'shuffle':
        return (value == 'false' || value == '0' || value == 'off')
            ? AiActionType.shuffleOff
            : AiActionType.shuffleOn;
      case 'repetir':
      case 'repeat':
        switch (value) {
          case 'one':
          case 'una':
          case '1':
            return AiActionType.repeatOne;
          case 'all':
          case 'todo':
          case 'todas':
            return AiActionType.repeatAll;
          default:
            return AiActionType.repeatOff;
        }
      case 'reproducir_cancion':
      case 'play_song':
      case 'reproducir_busqueda':
        return AiActionType.playQuery;
      case 'reproducir_lista':
      case 'play_playlist':
        return AiActionType.playPlaylist;
      case 'crear_lista':
      case 'create_playlist':
        return AiActionType.createPlaylist;
      case 'anadir_a_lista':
      case 'añadir_a_lista':
      case 'add_to_playlist':
        return AiActionType.addToPlaylist;
      case 'buscar':
      case 'search':
        return AiActionType.searchLibrary;
      case 'editar':
      case 'editar_metadatos':
      case 'edit':
        return AiActionType.editMetadata;
      case 'caratula':
      case 'carátula':
      case 'cover':
        return AiActionType.setCover;
      case 'favorito':
      case 'favorite':
        return AiActionType.toggleFavorite;
      case 'actualizar_biblioteca':
      case 'rescan':
      case 'escanear':
        return AiActionType.rescanLibrary;
      case 'que_suena':
      case 'now_playing':
        return AiActionType.nowPlaying;
      case 'estadisticas':
      case 'stats':
        return AiActionType.libraryStats;
      case 'ayuda':
      case 'help':
        return AiActionType.help;
      default:
        return AiActionType.unknown;
    }
  }

  // ---------------------------------------------------------------------
  // Reglas locales (sin IA): español primero, inglés como respaldo
  // ---------------------------------------------------------------------

  static final RegExp _timeRegex = RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?');

  static List<AiAction> fromNaturalLanguage(String text) {
    final String lower = text.toLowerCase().trim();
    final List<AiAction> actions = <AiAction>[];
    if (lower.isEmpty) return actions;

    // --- Reproducción básica ---
    if (RegExp(r'\b(pausa|pausar|pause)\b').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.pause));
    }
    if (RegExp(r'\b(siguiente|next|salta|cambia de cancion|cambia de canción)\b').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.next));
    }
    if (RegExp(r'\b(anterior|previous|volver a la anterior)\b').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.previous));
    }
    if (RegExp(r'\b(reanuda|reanudar|continua|continúa|resume|dale play)\b').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.play));
    }

    // --- Volumen ---
    final RegExpMatch? percent = RegExp(r'(\d{1,3})\s*%').firstMatch(lower);
    if (percent != null && RegExp(r'volumen|volume').hasMatch(lower)) {
      actions.add(AiAction(
        AiActionType.volumeSet,
        value: (int.parse(percent.group(1)!) / 100).clamp(0, 1).toStringAsFixed(2),
      ));
    } else if (RegExp(r'\b(sube|sube el|aumenta).*(volumen|volumen)|volume up').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.volumeUp));
    } else if (RegExp(r'\b(baja|reduce|bajale|bájale).*(volumen)|volume down').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.volumeDown));
    }

    // --- Velocidad ---
    final RegExpMatch? speed = RegExp(r'(\d(?:[.,]\d{1,2})?)\s*(?:x|veces)').firstMatch(lower);
    if (speed != null && !lower.contains('lista')) {
      actions.add(AiAction(AiActionType.speedSet, value: speed.group(1)!.replaceAll(',', '.')));
    }

    // --- Modos ---
    if (RegExp(r'\b(aleatorio|shuffle)\b').hasMatch(lower)) {
      final bool off = RegExp(r'\b(quita|desactiva|sin)\b').hasMatch(lower);
      actions.add(AiAction(off ? AiActionType.shuffleOff : AiActionType.shuffleOn));
    }
    if (RegExp(r'\b(repite|repetir|repeat|bucle|loop)\b').hasMatch(lower)) {
      if (RegExp(r'una|esta cancion|esta canción|one').hasMatch(lower)) {
        actions.add(const AiAction(AiActionType.repeatOne));
      } else if (RegExp(r'\b(quita|desactiva|para|stop)\b').hasMatch(lower)) {
        actions.add(const AiAction(AiActionType.repeatOff));
      } else {
        actions.add(const AiAction(AiActionType.repeatAll));
      }
    }

    // --- Crear / añadir a lista ---
    final RegExpMatch? create = RegExp(
      r'(?:crea|crear|haz|hazme|genera|monta)(?:me)?\s+(?:una\s+)?(?:lista|playlist)\s*(?:llamada|con nombre|de|para|con)?\s*([^.,;]+)',
    ).firstMatch(lower);
    if (create != null) {
      final String subject = create.group(1)!.trim();
      final int? count = int.tryParse(RegExp(r'(\d{1,3})').firstMatch(subject)?.group(1) ?? '');
      final String name = _stripCount(subject);
      actions.add(AiAction(
        AiActionType.createPlaylist,
        playlistName: name,
        query: subject,
        count: count,
      ));
    }
    final RegExpMatch? addTo = RegExp(
      r'(?:anade|añade|agrega|mete|pon)\s+(?:esto|esta|estas|la|las)?\s*(?:cancion|canciones|canción|esto)?\s*(?:a|en|dentro de)\s+(?:la\s+)?(?:lista|playlist)\s+([^.,;]+)',
    ).firstMatch(lower);
    if (addTo != null) {
      actions.add(AiAction(AiActionType.addToPlaylist, playlistName: _stripCount(addTo.group(1)!.trim())));
    }

    // --- Editar metadatos ---
    final RegExpMatch? edit = RegExp(
      r'(?:cambia|cambiar|pon|ponle|poner|edita|corrige|actualiza)\s+(?:el|la|los|las)?\s*(titulo|título|artista|album|álbum|anio|año|genero|género|tags|etiquetas)\s+(?:de\s+([^.,;]+?)\s+)?(?:a|por|como)\s+([^.,;]+)',
    ).firstMatch(lower);
    if (edit != null) {
      actions.add(AiAction(
        AiActionType.editMetadata,
        field: _normalizeField(edit.group(1)!),
        query: edit.group(2)?.trim(),
        value: edit.group(3)!.trim(),
      ));
    }

    // --- Carátula / favorito / biblioteca ---
    if (RegExp(r'caratula|carátula|cover|portada').hasMatch(lower) &&
        RegExp(r'\b(cambia|cambiar|pon|poner|edita|actualiza|asigna)\b').hasMatch(lower)) {
      actions.add(AiAction(AiActionType.setCover, query: _extractSongHint(lower)));
    }
    if (RegExp(r'\b(marca|pon|anade|añade).*(favorit)').hasMatch(lower)) {
      actions.add(AiAction(AiActionType.toggleFavorite, query: _extractSongHint(lower)));
    }
    if (RegExp(r'(actualiza|escanear|escanéa|escanear|revisa|busca canciones nuevas|refresh).*(biblioteca|musica|música|canciones)').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.rescanLibrary));
    }

    // --- Consultas ---
    if (RegExp(r'que (suena|cancion|canción)|qué (suena|cancion|canción)|now playing').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.nowPlaying));
    }
    if (RegExp(r'cuantas (canciones|listas)|cuántas (canciones|listas)|estadisticas|estadísticas|stats').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.libraryStats));
    }
    if (RegExp(r'\b(ayuda|help|que puedo (hacer|pedir)|qué puedo (hacer|pedir)|comandos)\b').hasMatch(lower)) {
      actions.add(const AiAction(AiActionType.help));
    }

    // --- Reproducir algo concreto ---
    if (actions.isEmpty || _looksLikePlayRequest(lower)) {
      final String? target = _extractPlayTarget(lower);
      if (target != null) {
        final bool isPlaylist = lower.contains('lista') || lower.contains('playlist');
        actions.add(AiAction(
          isPlaylist ? AiActionType.playPlaylist : AiActionType.playQuery,
          query: target,
          playlistName: isPlaylist ? target : null,
        ));
      }
    }

    // --- Buscar en la biblioteca ---
    final RegExpMatch? search = RegExp(r'\b(busca|buscar|search|encuentra|muestra)\b\s+(.+)').firstMatch(lower);
    if (search != null && actions.isEmpty) {
      actions.add(AiAction(AiActionType.searchLibrary, query: search.group(2)!.trim()));
    }

    // --- Saltar a un minuto ---
    final RegExpMatch? time = _timeRegex.firstMatch(lower);
    if (time != null && RegExp(r'\b(salta|ve a|minuto|segundo)\b').hasMatch(lower)) {
      final int minutes = int.tryParse(time.group(1)!) ?? 0;
      final int seconds = int.tryParse(time.group(2)!) ?? 0;
      actions.add(AiAction(AiActionType.seek, value: '${minutes * 60 + seconds}'));
    }

    return actions;
  }

  static bool _looksLikePlayRequest(String lower) =>
      RegExp(r'\b(pon|ponme|reproduce|reproducir|play|escuchar|quiero oir|quiero oír|suena)\b')
          .hasMatch(lower);

  static String? _extractPlayTarget(String lower) {
    final RegExpMatch? match = RegExp(
      r'\b(?:pon|ponme|reproduce|reproducir|play|escuchar|suena)\b\s+(?:la\s+|el\s+|los\s+|las\s+|un\s+|una\s+)?(?:cancion|canciones|canción|musica|música|lista|playlist|album|álbum|artista)?\s*(?:de\s+)?(.+)',
    ).firstMatch(lower);
    if (match == null) return null;
    String target = match.group(1)!.trim();
    target = target.replaceAll(RegExp(r'^(algo de|algo|mas de|más de)\s+'), '').trim();
    if (target.length < 2) return null;
    return target;
  }

  static String? _extractSongHint(String lower) {
    final RegExpMatch? match = RegExp(r'(?:de|para)\s+([^.,;]+)$').firstMatch(lower);
    return match?.group(1)?.trim();
  }

  static String _stripCount(String value) =>
      value.replaceAll(RegExp(r'\b\d{1,3}\b'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _normalizeField(String raw) {
    switch (raw) {
      case 'titulo':
      case 'título':
        return 'titulo';
      case 'artista':
        return 'artista';
      case 'album':
      case 'álbum':
        return 'album';
      case 'anio':
      case 'año':
        return 'anio';
      case 'genero':
      case 'género':
        return 'genero';
      case 'tags':
      case 'etiquetas':
        return 'tags';
      default:
        return raw;
    }
  }
}
