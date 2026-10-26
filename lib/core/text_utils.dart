import 'dart:convert';
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

/// Deja el texto de la IA listo para leer: quita los bloques internos de órdenes
/// (`<CMD>…</CMD>`) y el marcado markdown (`**negrita**`, `*cursiva*`, títulos con
/// `#`, `código`, viñetas con guiones), y conserva el texto en frases naturales.
///
/// El texto original se sigue usando para ejecutar las órdenes: esto solo afecta
/// a lo que se muestra.
String textoHumano(String texto) {
  String salida = texto;
  // Bloques de órdenes internos (no deben verse nunca).
  salida = salida.replaceAll(RegExp(r'<CMD>[\s\S]*?</CMD>', caseSensitive: false), ' ');
  salida = salida.replaceAll(RegExp(r'</?CMD>', caseSensitive: false), '');
  // Bloques y restos de código.
  salida = salida.replaceAll(RegExp(r'```[a-zA-Z]*'), '');
  salida = salida.replaceAll('`', '');
  // Títulos markdown.
  salida = salida.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
  // Negrita y cursiva: se queda el texto, se van los asteriscos.
  salida = salida.replaceAll(RegExp(r'\*\*\*(.+?)\*\*\*'), r'$1');
  salida = salida.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
  salida = salida.replaceAll(RegExp(r'(?<!\*)\*(?!\s)([^*\n]+?)(?<!\s)\*(?!\*)'), r'$1');
  salida = salida.replaceAll(RegExp(r'__(.+?)__'), r'$1');
  salida = salida.replaceAll(RegExp(r'(?<![A-Za-z0-9_])_([^_\n]+)_(?![A-Za-z0-9_])'), r'$1');
  // Viñetas y citas.
  salida = salida.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '\u2022 ');
  salida = salida.replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '');
  // Asteriscos sueltos y líneas en blanco de más.
  salida = salida.replaceAll('*', '');
  salida = salida.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  salida = salida.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return salida.trim();
}

/// Mensaje legible del DJ: si el modelo devolvio JSON (con "mensaje" o
/// "message"), se saca ese campo; si no, se limpia el texto. Evita volcar el
/// JSON crudo en la pantalla del reproductor.
String mensajeDelDJ(String raw) {
  final String limpio = raw.trim();
  if (limpio.startsWith('{')) {
    try {
      final dynamic json = jsonDecode(limpio);
      if (json is Map) {
        final Object? mensaje =
            json['mensaje'] ?? json['message'] ?? json['texto'];
        if (mensaje is String && mensaje.trim().isNotEmpty) {
          return textoHumano(mensaje.trim());
        }
      }
    } catch (_) {
      // No era JSON valido: se limpia como texto normal.
    }
  }
  return textoHumano(raw);
}