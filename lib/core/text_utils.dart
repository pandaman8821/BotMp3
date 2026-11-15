import 'dart:convert';
import '../models/song.dart';
import 'ui_strings.dart';

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
  // OJO: en Dart `replaceAll` NO entiende "$1" (lo escribía tal cual y en el
  // chat salía "$1" en lugar de la palabra en negrita): hace falta
  // `replaceAllMapped`.
  String grupo1(Match m) => m.group(1) ?? '';
  salida = salida.replaceAllMapped(RegExp(r'\*\*\*(.+?)\*\*\*'), grupo1);
  salida = salida.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), grupo1);
  salida = salida.replaceAllMapped(RegExp(r'(?<!\*)\*(?!\s)([^*\n]+?)(?<!\s)\*(?!\*)'), grupo1);
  salida = salida.replaceAllMapped(RegExp(r'__(.+?)__'), grupo1);
  salida = salida.replaceAllMapped(RegExp(r'(?<![A-Za-z0-9_])_([^_\n]+)_(?![A-Za-z0-9_])'), grupo1);
  // Viñetas y citas.
  salida = salida.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '\u2022 ');
  salida = salida.replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '');
  // Asteriscos sueltos y líneas en blanco de más.
  salida = salida.replaceAll('*', '');
  salida = salida.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  salida = salida.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return salida.trim();
}

/// Lee un campo de texto de un JSON aunque esté cortado o mal formado
/// (respetando comillas escapadas). Si el valor quedó a medias, se devuelve lo
/// que llegó terminado en «…». Devuelve null si el campo no aparece.
String? campoJsonTexto(String raw, List<String> claves) {
  for (final String clave in claves) {
    final RegExpMatch? completo = RegExp(
      '"${RegExp.escape(clave)}"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"',
    ).firstMatch(raw);
    if (completo != null) return _desescapar(completo.group(1)!);
    final RegExpMatch? cortado = RegExp(
      '"${RegExp.escape(clave)}"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)\$',
    ).firstMatch(raw);
    if (cortado != null && cortado.group(1)!.trim().isNotEmpty) {
      return '${_desescapar(cortado.group(1)!).trimRight()}…';
    }
  }
  return null;
}

String _desescapar(String valor) {
  try {
    final dynamic decoded = jsonDecode('"$valor"');
    if (decoded is String) return decoded;
  } catch (_) {}
  return valor.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');
}

/// ¿El texto es (o empieza como) una respuesta JSON de la IA?
bool pareceJsonDeIa(String texto) {
  final String t = texto.trimLeft().replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
  return t.startsWith('{') &&
      RegExp(r'"(mensaje|message|canciones|songs|titulo|nombre)"\s*:').hasMatch(t);
}

/// Texto que se pinta en una burbuja del chat: si la IA devolvió JSON (también
/// en mensajes antiguos guardados así), se muestra solo su frase natural.
String textoParaChat(String contenido) {
  if (!pareceJsonDeIa(contenido)) return textoHumano(contenido);
  return mensajeDelDJ(contenido);
}

/// Mensaje legible del DJ: si el modelo devolvio JSON (con "mensaje" o
/// "message"), se saca ese campo; si no, se limpia el texto. Evita volcar el
/// JSON crudo en la pantalla del reproductor.
String mensajeDelDJ(String raw, [int profundidad = 0]) {
  // A veces el modelo mete el JSON entero DENTRO del campo "mensaje"
  // ({"mensaje": "{\"mensaje\": ...}"}): se desenvuelve hasta 3 niveles.
  String limpio(String mensaje) => pareceJsonDeIa(mensaje) && profundidad < 3
      ? mensajeDelDJ(mensaje, profundidad + 1)
      : textoHumano(mensaje.trim());

  // 1) Si viene un JSON (aunque haya texto delante), se lee su campo de mensaje.
  final int inicio = raw.indexOf('{');
  if (inicio >= 0) {
    final int fin = raw.lastIndexOf('}');
    if (fin > inicio) {
      try {
        final dynamic json = jsonDecode(raw.substring(inicio, fin + 1));
        if (json is Map) {
          final Object? mensaje =
              json['mensaje'] ?? json['message'] ?? json['texto'];
          if (mensaje is String && mensaje.trim().isNotEmpty) {
            return limpio(mensaje);
          }
        }
      } catch (_) {
        // JSON mal formado: se intenta rescatar el campo mas abajo.
      }
    }
  }
  // 2) Rescate del campo aunque el JSON venga roto.
  final String? rescatado =
      campoJsonTexto(raw, const <String>['mensaje', 'message', 'texto']);
  if (rescatado != null && rescatado.trim().isNotEmpty) {
    return limpio(rescatado);
  }
  // 3) Nunca se enseña JSON en crudo: frase neutra si no hay nada legible.
  if (pareceJsonDeIa(raw)) return UiStrings.loc.aiSelectionBelow;
  return textoHumano(raw);
}