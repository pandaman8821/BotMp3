import '../models/song.dart';

/// Utilidades de texto compartidas por la lista, la búsqueda y el escaneo.

/// Texto listo para comparar alfabéticamente: sin acentos, en minúsculas y sin
/// espacios sobrantes. Así «Ámbar» ordena junto a «ambar» y no después de la Z.
String claveAlfabetica(String texto) {
  const Map<String, String> equivalencias = <String, String>{
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ß': 'ss',
  };
  final String base = texto.toLowerCase().trim();
  final StringBuffer salida = StringBuffer();
  for (final int code in base.runes) {
    final String caracter = String.fromCharCode(code);
    salida.write(equivalencias[caracter] ?? caracter);
  }
  return salida.toString();
}

/// Compara dos textos alfabéticamente (sin acentos). Los valores vacíos se
/// colocan **al final**, para que las canciones sin artista o sin álbum no
/// encabecen la lista.
int compararTextos(String a, String b) {
  final String ka = claveAlfabetica(a);
  final String kb = claveAlfabetica(b);
  if (ka.isEmpty != kb.isEmpty) return ka.isEmpty ? 1 : -1;
  return ka.compareTo(kb);
}

/// Marcas que aparecen en las rutas de los audios de apps de mensajería y en
/// las grabaciones de voz (notas de voz de WhatsApp, Telegram, dictáfonos…).
const List<String> _marcasDeApps = <String>[
  'whatsapp',
  'telegram',
  'messenger',
  'instagram',
  'facebook',
  'snapchat',
  'signal',
  'viber',
  'wechat',
  'grabacion',
  'grabación',
  'voice note',
  'voicenote',
  'voice/',
  'recordings',
  'recorder',
  'dictaphone',
  'aud-',
  'ptt-',
  'sound recordings',
  '/ringtones/',
  '/alarms/',
  '/notifications/',
];

/// ¿Parece un audio de una app (no música)? Se usa para no importarlo ni
/// mostrarlo salvo que el usuario active la opción en Ajustes.
bool pareceAudioDeApp(Song song) {
  final String pista = '${song.path} ${song.title}'.toLowerCase();
  for (final String marca in _marcasDeApps) {
    if (pista.contains(marca)) return true;
  }
  return false;
}
