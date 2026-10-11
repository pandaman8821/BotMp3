import '../core/constants.dart';

/// Mensaje de la conversación con el agente musical.
class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    this.provider,
    this.model,
    this.createdAt,
    this.suggestedSongIds = const <String>[],
    this.error = false,
  });

  /// 'system' | 'user' | 'assistant'
  final String role;
  final String content;
  final AiProvider? provider;
  final String? model;
  final DateTime? createdAt;

  /// Canciones locales que la IA propone reproducir con este mensaje.
  final List<String> suggestedSongIds;

  final bool error;

  bool get isUser => role == 'user';

  AiMessage copyWith({
    String? content,
    List<String>? suggestedSongIds,
    bool? error,
  }) {
    return AiMessage(
      role: role,
      content: content ?? this.content,
      provider: provider,
      model: model,
      createdAt: createdAt,
      suggestedSongIds: suggestedSongIds ?? this.suggestedSongIds,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'content': content,
        'provider': provider?.id,
        'model': model,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
        'suggestedSongIds': suggestedSongIds,
        'error': error,
      };

  static AiMessage fromJson(Map<String, dynamic> json) {
    final String? providerId = json['provider']?.toString();
    return AiMessage(
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      provider: providerId == null
          ? null
          : AiProvider.values.firstWhere(
              (AiProvider p) => p.id == providerId,
              orElse: () => AiProvider.deepseek,
            ),
      model: json['model']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      suggestedSongIds: (json['suggestedSongIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic id) => id.toString())
          .toList(),
      error: json['error'] == true,
    );
  }
}

/// Sugerencia musical devuelta por la IA (puede existir o no en la biblioteca).
class AiSongSuggestion {
  const AiSongSuggestion({
    required this.title,
    required this.artist,
    this.album,
    this.year,
    this.genre,
    this.reason = '',
    this.mood,
    this.localSongId,
    this.localSongTitle,
  });

  final String title;
  final String artist;
  final String? album;
  final int? year;
  final String? genre;

  /// Explicación en lenguaje natural de por qué encaja.
  final String reason;
  final String? mood;

  /// Si la sugerencia ya está en la biblioteca local, se enlaza aquí.
  final String? localSongId;
  final String? localSongTitle;

  bool get isLocal => localSongId != null;

  AiSongSuggestion copyWith({String? localSongId, String? localSongTitle}) {
    return AiSongSuggestion(
      title: title,
      artist: artist,
      album: album,
      year: year,
      genre: genre,
      reason: reason,
      mood: mood,
      localSongId: localSongId ?? this.localSongId,
      localSongTitle: localSongTitle ?? this.localSongTitle,
    );
  }

  /// Enlace de búsqueda para escuchar la canción en servicios externos
  /// (la app no descarga música: solo sugiere y enlaza).
  String get searchUrl =>
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$artist $title')}';

  static AiSongSuggestion fromJson(Map<String, dynamic> json) {
    return AiSongSuggestion(
      title: (json['titulo'] ?? json['title'] ?? 'Sin título').toString(),
      artist: (json['artista'] ?? json['artist'] ?? 'Desconocido').toString(),
      album: (json['album'])?.toString(),
      year: int.tryParse((json['anio'] ?? json['year'] ?? '').toString()),
      genre: (json['genero'] ?? json['genre'])?.toString(),
      reason: (json['razon'] ?? json['reason'] ?? json['por_que'] ?? '').toString(),
      mood: (json['mood'] ?? json['animo'])?.toString(),
    );
  }
}

/// Ficha creativa de una canción generada por IA (letra/estructura + prompt).
class AiSongIdea {
  const AiSongIdea({
    required this.title,
    required this.genre,
    required this.mood,
    required this.bpm,
    required this.structure,
    required this.lyricSeed,
    required this.prompt,
    required this.language,
  });

  final String title;
  final String genre;
  final String mood;
  final int bpm;
  final List<String> structure;
  final String lyricSeed;

  /// Prompt listo para pegar en generadores de audio (Suno, Udio, MusicGen...).
  final String prompt;
  final String language;

  String get youtubeSearchUrl =>
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$title $genre')}';

  /// Prompt para un generador de música con IA (estilo Suno).
  String get generatorPrompt =>
      '$prompt | genre: $genre | mood: $mood | bpm: $bpm | language: $language';

  static AiSongIdea fromJson(Map<String, dynamic> json) {
    return AiSongIdea(
      title: (json['titulo'] ?? json['title'] ?? 'Idea sin título').toString(),
      genre: (json['genero'] ?? json['genre'] ?? 'Pop').toString(),
      mood: (json['mood'] ?? json['animo'] ?? 'neutro').toString(),
      bpm: int.tryParse((json['bpm'] ?? '100').toString()) ?? 100,
      structure: (json['estructura'] as List<dynamic>? ?? json['structure'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic step) => step.toString())
          .toList(),
      lyricSeed: (json['semilla_letra'] ?? json['lyricSeed'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      language: (json['idioma'] ?? json['language'] ?? 'español').toString(),
    );
  }
}

/// Respuesta estructurada del agente para una acción concreta.
class AiActionResult {
  const AiActionResult({
    required this.text,
    this.suggestions = const <AiSongSuggestion>[],
    this.playlistName,
    this.playlistDescription,
  });

  final String text;
  final List<AiSongSuggestion> suggestions;
  final String? playlistName;
  final String? playlistDescription;
}
