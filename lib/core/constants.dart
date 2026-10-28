import 'package:flutter/material.dart';

/// Catálogo de géneros disponibles en el selector obligatorio de cada canción.
class GenreCatalog {
  const GenreCatalog._();

  static const List<String> all = <String>[
    'Rock',
    'Pop',
    'Hip-Hop',
    'Electronic',
    'Reggaetón',
    'K-pop',
    'Latin',
    'Cumbia',
    'Salsa',
    'Bachata',
    'Merengue',
    'Reggae',
    'Metal',
    'Punk',
    'Indie',
    'R&B',
    'Soul',
    'Jazz',
    'Blues',
    'Clásica',
    'Folk',
    'Folklore',
    'Trap',
    'Rap',
    'Country',
    'Funk',
    'Disco',
    'House',
    'Techno',
    'Lo-fi',
    'Instrumental',
    'Bolero',
    'Balada',
    'Vallenato',
    'Cuarteto',
    'Chicha',
    'Podcast',
    'Otro',
  ];

  static String normalize(String? genre) {
    if (genre == null || genre.trim().isEmpty) return 'Otro';
    final String needle = genre.trim().toLowerCase();
    for (final String option in all) {
      if (option.toLowerCase() == needle) return option;
    }
    return genre.trim();
  }
}

/// Formatos de audio soportados por el reproductor local.
class AudioFormats {
  const AudioFormats._();

  static const List<String> supported = <String>[
    'mp3',
    'mp2',
    'amr',
    'awb',
    'mka',
    'mp4',
    '3gp',
    'ac3',
    'eac3',
    'dts',
    'm4a',
    'm4b',
    'aac',
    'ogg',
    'oga',
    'opus',
    'flac',
    'wav',
    'aif',
    'aiff',
  ];

  static bool isSupported(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return false;
    return supported.contains(path.substring(dot + 1).toLowerCase());
  }

  static String extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }
}

/// Proveedores de IA soportados por el agente musical.
enum AiProvider { openai, deepseek, gemini, claude }

extension AiProviderInfo on AiProvider {
  String get id => name;

  /// Nombre comercial que se muestra en la interfaz.
  String get label {
    switch (this) {
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.deepseek:
        return 'DeepSeek';
      case AiProvider.gemini:
        return 'Google Gemini';
      case AiProvider.claude:
        return 'Anthropic Claude';
    }
  }

  /// Modelos recomendados (el primero es el que se usa por defecto).
  List<String> get models {
    switch (this) {
      case AiProvider.openai:
        return <String>[
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-4.1',
            'gpt-4.1-mini',
            'o4-mini',
          ];
      case AiProvider.deepseek:
        // Nombres VIGENTES de la API de DeepSeek. Los antiguos
        // `deepseek-chat` y `deepseek-reasoner` ya no existen.
        return <String>['deepseek-flash', 'deepseek-v4-pro'];
      case AiProvider.gemini:
        return <String>['gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-2.0-flash'];
      case AiProvider.claude:
        return <String>[
            'claude-sonnet-4-20250514',
            'claude-3-7-sonnet-20250219',
            'claude-3-5-haiku-20241022',
          ];
    }
  }

  String get defaultModel => models.first;

  /// Pista corta sobre un modelo concreto (se muestra bajo el selector).
  String? hintFor(String model) {
    switch (model) {
      case 'deepseek-flash':
        return 'Recomendado: el más rápido y económico (ideal para toda la app).';
      case 'deepseek-v4-pro':
        return 'Más capaz en razonamiento; cuesta unas 4 veces más por uso.';
      case 'deepseek-chat':
      case 'deepseek-reasoner':
        return 'Nombre retirado por DeepSeek: usa deepseek-flash o deepseek-v4-pro.';
      case 'gpt-4o':
        return 'Equilibrado y con buen español; buen equilibrio calidad/precio.';
      case 'gpt-4o-mini':
        return 'Muy rápido y barato; suficiente para metadatos y listas.';
      case 'o1':
      case 'o1-mini':
        return 'Razonamiento: más lento y caro; con estos la app omite el modo JSON.';
      case 'gemini-2.0-flash':
      case 'gemini-2.5-flash':
        return 'Rápido y con cuota gratuita generosa de Google.';
      case 'gemini-2.5-pro':
        return 'Más capaz; consume antes la cuota gratuita.';
      case 'claude-3-5-haiku-latest':
        return 'El más rápido y económico de Claude.';
      case 'claude-3-5-sonnet-latest':
        return 'Equilibrado; muy buena redacción en español.';
      case 'claude-3-opus-latest':
        return 'El más potente de Claude y también el más caro.';
    }
    return null;
  }

  /// Dónde obtener la API key (se muestra en Ajustes).
  String get keysUrl {
    switch (this) {
      case AiProvider.openai:
        return 'https://platform.openai.com/api-keys';
      case AiProvider.deepseek:
        return 'https://platform.deepseek.com/api_keys';
      case AiProvider.gemini:
        return 'https://aistudio.google.com/app/apikey';
      case AiProvider.claude:
        return 'https://console.anthropic.com/settings/keys';
    }
  }

  String get hint {
    switch (this) {
      case AiProvider.openai:
        return 'sk-...';
      case AiProvider.deepseek:
        return 'sk-...';
      case AiProvider.gemini:
        return 'AIza...';
      case AiProvider.claude:
        return 'sk-ant-...';
    }
  }

  IconData get icon {
    switch (this) {
      case AiProvider.openai:
        return Icons.auto_awesome;
      case AiProvider.deepseek:
        return Icons.psychology;
      case AiProvider.gemini:
        return Icons.diamond_outlined;
      case AiProvider.claude:
        return Icons.bolt;
    }
  }
}

/// Etiquetas rápidas sugeridas al editar una canción (búsqueda avanzada).
class TagSuggestions {
  const TagSuggestions._();

  static const List<String> all = <String>[
    'favorita',
    'fiesta',
    'trabajo',
    'estudio',
    'entrenamiento',
    'relajante',
    'triste',
    'alegre',
    'romántica',
    'verano',
    'invierno',
    'navidad',
    'viaje',
    'noche',
    'mañana',
    'chill',
    'energía',
    'clásico',
    'nuevo',
    'bolivia',
    'latino',
    'en vivo',
  ];
}

/// Novedades de cada compilación (se muestran en «Acerca de»).
class AppChangelog {
  const AppChangelog._();

  static const Map<int, String> novedades = <int, String>{
    14: '«Acerca de» muestra la versión real del APK y sus novedades, con las últimas correcciones.',
    13: 'Controles del bloqueo corregidos y pantalla de Diagnóstico de reproducción.',
    12: 'Pestaña IA arreglada (Tendencias como chip en las acciones).',
    11: 'Ranking de lo más escuchado y tendencias con aviso diario.',
    10: 'Siguiente y anterior en la pantalla de bloqueo.',
    9: 'Modelos de IA al día (deepseek-flash / deepseek-v4-pro).',
    8: 'Notificación de reproducción con controles en el bloqueo.',
    7: 'Transición visible en todas las pestañas.',
    6: 'Tocar una canción la reproduce al instante.',
    5: 'Efecto cristal (Liquid Glass) en barras y paneles.',
    4: 'Icono nuevo y gestión de espacio en caché.',
  };

  static String? forCode(int code) => novedades[code];
}

/// Claves de almacenamiento local.
class StorageKeys {
  const StorageKeys._();

  static const String library = 'botmp3_library_v1.json';

    /// Copia de seguridad interna (semanal) y su marca de fecha.
    static const String backupFile = 'botmp3_backup_v1.json';
    static const String backupFecha = 'botmp3_backup_fecha_v1.json';
  static const String settings = 'botmp3_settings_v1.json';
  static const String aiChat = 'botmp3_ai_chat_v1.json';
  static const String trendsFile = 'botmp3_trends_v1.json';
  static const String playLogFile = 'botmp3_playlog_v1.json';
  static const String importedDir = 'imported';
  static const String coversDir = 'covers';
}
