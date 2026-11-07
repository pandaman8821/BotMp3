import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/ai_models.dart';
import '../../models/song.dart';
import '../../services/settings_service.dart';
import 'ai_client.dart';
import 'ai_local_search.dart';

/// Agente musical de BotMp3.
///
/// Traduce las peticiones del usuario en prompts para el proveedor de IA
/// elegido, interpreta las respuestas (texto + JSON) y las cruza con la
/// biblioteca local para poder reproducir lo que la IA propone.
class AiOrchestrator {
  AiOrchestrator({
    required this.client,
    required this.librarySongs,
  });

  final AiClient client;
  final List<Song> librarySongs;

  static const String _system = '''
Eres "BotMp3 IA", un DJ y curador musical experto que conversa en español.
Conoces la biblioteca local del usuario (se te entrega como contexto) y puedes
recomendar tanto canciones que ya tiene como música externa que debería buscar.
Reglas:
- La lista ARTISTAS DE LA BIBLIOTECA y las COINCIDENCIAS son la fuente de verdad:
  si un artista o una cancion aparece ahi, el usuario SI lo tiene. Nunca digas que
  no tiene algo que aparece en esas listas.
- Responde SIEMPRE en español, con tono cercano y breve (máximo 6 líneas salvo que pidan más).
- Cuando propongas canciones, explica en una frase por qué encajan (mood, época, género, energía).
- No inventes datos técnicos; si no estás seguro de un año, omítelo.
- Nunca inventes que has escuchado audio: trabajas con metadatos.
- Si el usuario pide una acción sobre la biblioteca, indícalo claramente.
- Escribe como una persona: frases naturales y directas, SIN markdown. No uses
  asteriscos, almohadillas, guiones de lista, negritas ni comillas invertidas
  (tampoco para enumerar: usa frases seguidas o empieza la línea con «•»).
- No vuelques datos en crudo ni fichas técnicas: cuenta lo importante como se
  lo dirías a un amigo, con una recomendación clara y el porqué.
''';

  /// Protocolo de órdenes ejecutables que el modelo añade a su respuesta.
  static const String _actionProtocol = '''
ÓRDENES EJECUTABLES (MUY IMPORTANTE):
Cuando el usuario te pida HACER algo (no solo preguntar), añade al final de tu
respuesta uno o varios bloques con este formato EXACTO:
<CMD>{"accion":"reproducir_cancion","consulta":"texto a buscar"}</CMD>
Acciones disponibles:
  reproducir · pausar · siguiente · anterior · detener
  volumen (valor 0..1) · subir_volumen · bajar_volumen · velocidad (valor 0.5..2)
  aleatorio (valor true/false) · repetir (modo off|all|one)
  reproducir_cancion (consulta) · reproducir_lista (lista)
  crear_lista (nombre, consulta, cantidad) · anadir_a_lista (lista, consulta)
  buscar (consulta) · editar_metadatos (consulta, campo, valor)
  caratula (consulta) · favorito (consulta) · actualizar_biblioteca
  que_suena · estadisticas · ayuda
El campo 'campo' de editar_metadatos solo puede ser: titulo, artista, album,
anio, genero o tags. No menciones ni expliques los bloques <CMD> en el texto.
Usa el lenguaje natural solo para conversar; para actuar, usa <CMD>.
''';

  /// Catálogo compacto de la biblioteca (para gastar pocos tokens).
  /// Corrige y completa los metadatos de una canción (editor simplificado).
  Future<Map<String, String>?> suggestMetadata(Song song) async {
    final String fileName = song.path.split(RegExp(r'[\\/]')).last;
    final String prompt = '''
You are a music metadata expert. Fix and complete the metadata of ONE local song.

Song data:
- file name: $fileName
- current title: ${song.title}
- current artist: ${song.artist}
- current album: ${song.album}
- current year: ${song.year}
- current genre: ${song.genre}

Rules:
1. Use the file name as a strong hint (it often contains "Artist - Title" or track numbers).
2. Fix spelling, capitalisation and common tagging mistakes (feat., remix, slowed, sped up).
3. Return ONLY this JSON, with every field filled:
   {"titulo":"...","artista":"...","album":"...","anio":2020,"genero":"...","tags":["...","..."]}
4. If a value is genuinely unknown, repeat the current value instead of inventing it.
5. Year must be a real 4-digit year between 1900 and ${DateTime.now().year + 1}; otherwise 0.
6. Genre MUST be one of: ${GenreCatalog.all.join(', ')}.
7. Tags: 1 to 4 short lowercase keywords about mood, era or style.
''';
    final String raw = await client.complete(
      <AiMessage>[
        AiMessage(role: 'user', content: prompt, createdAt: DateTime.now()),
      ],
      systemPrompt: '$_system\n$_actionProtocol',
      json: true,
    );
    String? block = extractJsonBlock(raw);
      // Tolerancia: algunos modelos envuelven el JSON en texto o bloques de codigo.
      if (block == null) {
        final int ini = raw.indexOf('{');
        final int fin = raw.lastIndexOf('}');
        if (ini >= 0 && fin > ini) {
          block = raw.substring(ini, fin + 1);
        }
      }
    if (block == null) return null;
    try {
      final dynamic decoded = jsonDecode(block);
      if (decoded is! Map) return null;
      final Map<dynamic, dynamic> map = decoded;
      String pick(List<String> keys) {
        for (final String key in keys) {
          final Object? value = map[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
        return '';
      }

      return <String, String>{
        'titulo': pick(<String>['titulo', 'title']),
        'artista': pick(<String>['artista', 'artist']),
        'album': pick(<String>['album']),
        'anio': pick(<String>['anio', 'año', 'year']),
        'genero': pick(<String>['genero', 'género', 'genre']),
        'tags': map['tags'] is List
            ? (map['tags'] as List).join(', ')
            : pick(<String>['tags']),
      };
    } catch (_) {
      return null;
    }
  }

  String _catalogContext({int limit = 70}) {
    final List<Song> ordered = List<Song>.from(librarySongs)
      ..sort((Song a, Song b) => b.playCount.compareTo(a.playCount));
    final List<Map<String, dynamic>> catalog =
        ordered.take(limit).map((Song song) => song.toAiJson()).toList();
    if (catalog.isEmpty) return 'La biblioteca local está vacía.';
    return jsonEncode(catalog);
  }

  String _recentContext(List<Song> recent) {
    if (recent.isEmpty) return 'Sin historial reciente.';
    return recent.take(12).map((Song s) => '${s.artist} - ${s.title}').join(' | ');
  }

  // ------------------------------------------------------------------ acciones

  /// Conversación libre sobre música.
  Future<String> chat(List<AiMessage> history, {String? extraContext}) async {
    return client.complete(
      history,
      systemPrompt: '$_system\n$_actionProtocol\n\nBIBLIOTECA DEL USUARIO:\n${AiLocalSearch.contexto(librarySongs, '')}\nMuestra (JSON):\n${_catalogContext()}\n'
          '${extraContext == null ? '' : '\nCONTEXTO ACTUAL:\n$extraContext'}',
      temperature: 0.8,
      maxTokens: 1200,
    );
  }

  /// Recomendaciones personalizadas (género, artista, mood o lista actual).
  Future<AiActionResult> recommend({
    required String request,
    List<Song> currentPlaylist = const <Song>[],
    int count = 10,
  }) async {
    final String prompt = '''
El usuario pide: "$request"

Contexto:
- Biblioteca local: ${_catalogContext(limit: 50)}
- Lista/canción actual: ${currentPlaylist.take(8).map((Song s) => '${s.artist} - ${s.title}').join(' | ').ifEmpty('nada seleccionado')}

Devuelve EXACTAMENTE este JSON (sin markdown):
{
  "mensaje": "explicación breve y natural de tus recomendaciones",
  "canciones": [
    {"titulo": "...", "artista": "...", "anio": 2021, "genero": "...", "razon": "por qué encaja"}
  ]
}
Incluye entre $count y ${count + 5} canciones. Marca con "enBiblioteca": true las que ya aparecen en la biblioteca local.
''';

    final String raw = await client.complete(
      <AiMessage>[AiMessage(role: 'user', content: prompt)],
      systemPrompt: _system,
      json: true,
      temperature: 0.85,
      maxTokens: 2200,
    );
    return _parseActionResult(raw);
  }

  /// Genera una lista completa a partir de una petición en lenguaje natural.
  Future<AiActionResult> generatePlaylist({
    required String request,
    required int count,
  }) async {
    final String prompt = '''
Crea una lista de reproducción con estas condiciones: "$request".
Número de canciones: $count (ni una menos).

Biblioteca local disponible: ${_catalogContext(limit: 60)}

Prioriza canciones de la biblioteca local cuando encajen, y completa con música externa si hace falta.
Devuelve EXACTAMENTE este JSON (sin markdown):
{
  "nombre": "nombre atractivo de la lista",
  "descripcion": "una frase que describa la lista",
  "mensaje": "explicación de la selección",
  "canciones": [
    {"titulo": "...", "artista": "...", "anio": 2020, "genero": "...", "razon": "...", "enBiblioteca": true}
  ]
}
''';
    final String raw = await client.complete(
      <AiMessage>[AiMessage(role: 'user', content: prompt)],
      systemPrompt: _system,
      json: true,
      temperature: 0.75,
      maxTokens: 3000,
    );
    final AiActionResult parsed = _parseActionResult(raw);
    // Si el modelo no devolvió nombre, se genera uno a partir de la petición.
    return AiActionResult(
      text: parsed.text,
      suggestions: parsed.suggestions,
      playlistName: parsed.playlistName ?? _fallbackPlaylistName(request),
      playlistDescription: parsed.playlistDescription ?? 'Creada por IA: $request',
    );
  }

  /// Búsqueda inteligente: interpreta la consulta y explica el resultado.
  Future<AiActionResult> smartSearch(String query) async {
    final String prompt = '''
El usuario busca en su biblioteca: "$query"

CONTEXTO REAL (calculado en el dispositivo, es la verdad):
${AiLocalSearch.contexto(librarySongs, query)}

Biblioteca local (muestra de las mas escuchadas): ${_catalogContext(limit: 60)}

Interpreta la intención (mood, época, energía, idioma, actividad) y elige las canciones
de la biblioteca que mejor encajan. Devuelve EXACTAMENTE este JSON:
{
  "mensaje": "explicación en lenguaje natural de lo que entendiste y por qué esas canciones",
  "canciones": [ 15 elementos {"titulo": "...", "artista": "...", "razon": "..."} ]
}
Ordena de más a menos relevante. Máximo 25 canciones, solo de la biblioteca local.
''';
    final String raw = await client.complete(
      <AiMessage>[AiMessage(role: 'user', content: prompt)],
      systemPrompt: _system,
      json: true,
      temperature: 0.4,
      maxTokens: 2000,
    );
    final AiActionResult resultado = _parseActionResult(raw);
    return _resultadoConGuardia(query, resultado);
  }

  /// Red de seguridad: si la biblioteca TIENE coincidencias, la respuesta no
  /// puede decir que no existen. Si el modelo se equivoca, se corrige aqui.
  AiActionResult _resultadoConGuardia(String query, AiActionResult resultado) {
    final List<Song> coincidencias = AiLocalSearch.buscar(librarySongs, query);
    if (coincidencias.isEmpty) return resultado;
    final String texto = (resultado.text ?? '').toLowerCase();
    final bool niega = texto.contains('no tienes') ||
        texto.contains('no hay') ||
        texto.contains('no encontr') ||
        texto.contains('nada suyo') ||
        texto.contains('no aparece');
    final bool sinSugerencias = resultado.suggestions.isEmpty;
    if (!niega && !sinSugerencias) return resultado;
    final List<AiSongSuggestion> sugerencias = <AiSongSuggestion>[
      for (final Song s in coincidencias.take(15))
        AiSongSuggestion(title: s.title, artist: s.artist, reason: 'Esta en tu biblioteca'),
    ];
    final String mensaje = niega
        ? 'Si las tienes: encontre ${coincidencias.length} coincidencias en tu biblioteca.'
        : resultado.text;
    return AiActionResult(
      text: mensaje,
      suggestions: sugerencias,
      playlistName: resultado.playlistName,
      playlistDescription: resultado.playlistDescription,
    );
  }

  /// Modo DJ IA: elige la siguiente canción y explica por qué.
  Future<AiActionResult> djNext({
    required Song current,
    required List<Song> recentlyPlayed,
      String sesion = '',
  }) async {
    final String prompt = '''
Actúas como DJ en vivo. Ahora suena: ${sesion.isEmpty ? '' : '(sesión: ) '}${current.artist} - ${current.title} (${current.genre}).
Historial reciente: ${_recentContext(recentlyPlayed)}

Elige las SIGUIENTES ${SettingsService.actual?.djCanciones ?? 15} canciones de ESTA biblioteca (usa títulos y artistas EXACTOS de la lista),
buscando continuidad de energía y mood. Biblioteca disponible:
${_catalogContext()}
Devuelve EXACTAMENTE este JSON:
{
  "mensaje": "por qué esta canción ahora (1-2 frases, estilo DJ)",
  "canciones": [{"titulo": "...", "artista": "...", "razon": "..."}]
}
''';
    final String raw = await client.complete(
      <AiMessage>[AiMessage(role: 'user', content: prompt)],
      systemPrompt: _system,
      json: true,
      temperature: 0.8,
      maxTokens: 900,
    );
    AiActionResult result = _parseActionResult(raw);
    // Evita repetir la canción actual o las ya escuchadas.
    result = AiActionResult(
      text: result.text,
      suggestions: result.suggestions
          .where((AiSongSuggestion s) =>
              s.localSongId != current.id &&
              !recentlyPlayed.any((Song recent) => recent.id == s.localSongId))
          .toList(),
    );

    // Respaldo local: si la IA no devolvió nada utilizable (sin clave,
    // sin conexión o títulos inventados), el DJ elige desde la biblioteca.
    if (result.suggestions.length < (SettingsService.actual?.djCanciones ?? 15)) {
      final List<Song> cola = _colaLocal(current, recentlyPlayed);
      if (cola.isNotEmpty) {
            result = AiActionResult(
          text: result.text.isEmpty
              ? 'Sigo con algo en la misma línea: ${cola.first.title}.'
              : result.text,
          suggestions: <AiSongSuggestion>[
        // Primero lo que propuso la IA y después el relleno local.
        ...result.suggestions,
        for (final Song s in cola)
          if (!result.suggestions.any(
              (AiSongSuggestion ya) => ya.localSongId == s.id))
            AiSongSuggestion(
              title: s.title,
              artist: s.artist,
              album: s.album,
              year: s.year == 0 ? null : s.year,
              genre: s.genre,
              reason: _razonLocal(current, s),
              localSongId: s.id,
              localSongTitle: s.title,
            ),
      ].take(SettingsService.actual?.djCanciones ?? 15).toList(),
          playlistName: 'Modo DJ',
          playlistDescription: _razonLocal(current, cola.first),
        );
      }
    }
    return result;
  }

  /// Cola de respaldo sin depender de la nube: mismo género, luego mismo
  /// artista y, por último, el resto de la biblioteca (sin repetir nada).
  List<Song> _colaLocal(Song actual, List<Song> recientes, {int cantidad = 15}) {
    final Set<String> vistas = <String>{
      actual.id,
      ...recientes.map((Song s) => s.id),
    };
    final List<Song> cola = <Song>[];
    void anadir(Iterable<Song> candidatas) {
      for (final Song s in candidatas) {
        if (cola.length >= cantidad) return;
        if (!vistas.add(s.id)) continue;
        cola.add(s);
      }
    }
    final List<Song> libres =
        librarySongs.where((Song s) => !vistas.contains(s.id)).toList();
    anadir(libres.where(
        (Song s) => actual.genre.isNotEmpty && s.genre == actual.genre));
    anadir(libres.where((Song s) => s.artist == actual.artist));
    anadir(libres);
    return cola;
  }


  /// Explicación del DJ cuando elige sin IA.
  String _razonLocal(Song actual, Song siguiente) {
    if (actual.genre.isNotEmpty && siguiente.genre == actual.genre) {
      return 'Mismo género (${siguiente.genre}) para no cortar el ambiente.';
    }
    if (siguiente.artist == actual.artist) {
      return 'Sigue el mismo artista, sin repetir la canción.';
    }
    return 'Cambio de aire sin salir de tu biblioteca.';
  }

  /// Crea una idea de canción (letra/estructura) y enlaces de búsqueda.
  Future<AiSongIdea> songIdea(String description) async {
    final String prompt = '''
El usuario quiere crear una canción con esta descripción: "$description"

Devuelve EXACTAMENTE este JSON:
{
  "titulo": "título propuesto",
  "genero": "género principal",
  "mood": "estado de ánimo",
  "bpm": 120,
  "idioma": "español",
  "estructura": ["Intro", "Verso 1", "Coro", "Verso 2", "Puente", "Outro"],
  "semilla_letra": "4 a 8 líneas de letra originales en español, con rima",
  "prompt": "prompt detallado en inglés para un generador de música IA, con instrumentación, mezcla y referencias de estilo"
}
''';
    final String raw = await client.complete(
      <AiMessage>[AiMessage(role: 'user', content: prompt)],
      systemPrompt: '$_system\nEres también compositor y letrista.',
      json: true,
      temperature: 0.95,
      maxTokens: 1500,
    );

    String? block = extractJsonBlock(raw);
      // Tolerancia: algunos modelos envuelven el JSON en texto o bloques de codigo.
      if (block == null) {
        final int ini = raw.indexOf('{');
        final int fin = raw.lastIndexOf('}');
        if (ini >= 0 && fin > ini) {
          block = raw.substring(ini, fin + 1);
        }
      }
    if (block != null) {
      try {
        final dynamic decoded = jsonDecode(block);
        if (decoded is Map<String, dynamic>) return AiSongIdea.fromJson(decoded);
      } catch (error) {
        debugPrint('JSON de canción inválido: $error');
      }
    }
    return AiSongIdea(
      title: 'Untitled idea',
      genre: 'Pop',
      mood: 'neutro',
      bpm: 100,
      structure: const <String>['Intro', 'Verso', 'Coro', 'Outro'],
      lyricSeed: raw,
      prompt: description,
      language: 'español',
    );
  }

  /// Prueba rápida de conectividad y credenciales.
  Future<String> testConnection() async {
    final String reply = await client.complete(
      <AiMessage>[
        const AiMessage(role: 'user', content: 'Reply only with: BotMp3 AI connected'),
      ],
      systemPrompt: 'Eres un comprobador de conexión. Responde en una línea.',
      temperature: 0,
      maxTokens: 40,
    );
    return reply.trim();
  }

  // ------------------------------------------------------------------ parseo

  AiActionResult _parseActionResult(String raw) {
    String? block = extractJsonBlock(raw);
      // Tolerancia: algunos modelos envuelven el JSON en texto o bloques de codigo.
      if (block == null) {
        final int ini = raw.indexOf('{');
        final int fin = raw.lastIndexOf('}');
        if (ini >= 0 && fin > ini) {
          block = raw.substring(ini, fin + 1);
        }
      }
    if (block == null) {
      return AiActionResult(text: raw.trim());
    }

    try {
      final dynamic decoded = jsonDecode(block);
      if (decoded is! Map<String, dynamic>) {
        return AiActionResult(text: raw.trim());
      }

      final dynamic rawSongs = decoded['canciones'] ?? decoded['songs'] ?? <dynamic>[];
      final List<AiSongSuggestion> suggestions = (rawSongs as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AiSongSuggestion.fromJson)
          .toList();

      final String message =
          (decoded['mensaje'] ?? decoded['message'] ?? raw).toString().trim();

      return AiActionResult(
        text: message,
        suggestions: _linkWithLibrary(suggestions),
        playlistName: decoded['nombre']?.toString(),
        playlistDescription: decoded['descripcion']?.toString(),
      );
    } catch (error) {
      debugPrint('No se pudo interpretar la respuesta de la IA: $error');
      return AiActionResult(text: raw.trim());
    }
  }

  /// Empareja las sugerencias con canciones reales de la biblioteca.
  List<AiSongSuggestion> _linkWithLibrary(List<AiSongSuggestion> suggestions) {
    return suggestions.map((AiSongSuggestion suggestion) {
      Song? best;
      double bestScore = 0;
      for (final Song song in librarySongs) {
        final double titulo = Formatters.similarity(song.title, suggestion.title);
          final double artista = Formatters.similarity(song.artist, suggestion.artist);
          // El TITULO manda: muchas bibliotecas tienen el artista vacio o como
          // "Artista desconocido"; exigirlo marcaba como externa una cancion que
          // SI estaba en la biblioteca. El artista solo desempata.
          final double score = titulo >= 0.8 ? titulo : (titulo * 0.75 + artista * 0.25);
        if (score > bestScore) {
          bestScore = score;
          best = song;
        }
      }
      if (best != null && bestScore >= 0.55) {
        return suggestion.copyWith(localSongId: best.id, localSongTitle: best.title);
      }
      return suggestion;
    }).toList();
  }

  String _fallbackPlaylistName(String request) {
    final String clean = request.trim();
    if (clean.isEmpty) return 'Lista IA';
    final String short = clean.length > 38 ? '${clean.substring(0, 38)}…' : clean;
    return 'IA · $short';
  }
}

extension _StringIfEmpty on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
