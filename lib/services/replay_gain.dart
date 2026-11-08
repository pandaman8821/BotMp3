import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Lectura de ReplayGain desde las etiquetas del archivo (MP3 ID3v2 y FLAC).
///
/// Se usa para normalizar el volumen entre canciones sin tocar el audio:
/// el valor en dB se convierte en un factor de volumen.
class ReplayGain {
  const ReplayGain._();

  /// Ganancia recomendada por ReplayGain (dB) cacheada por ruta.
  static final Map<String, double> _cache = <String, double>{};
  static final Set<String> _procesando = <String>{};

  /// Factor de volumen ya calculado (1.0 si no hay etiqueta).
  static double factor(String? ruta) {
    if (ruta == null || ruta.isEmpty) return 1;
    final double? db = _cache[ruta];
    if (db == null) return 1;
    // -18 dB .. +18 dB -> factor 0.13 .. 7.9; se limita a 0.25 .. 2.0
    return math.pow(10, db / 20).toDouble().clamp(0.25, 2.0);
  }

  /// Precarga la ganancia de una cancion (sin bloquear la reproduccion).
  static Future<void> precargar(String? ruta) async {
    if (ruta == null || ruta.isEmpty) return;
    if (_cache.containsKey(ruta) || _procesando.contains(ruta)) return;
    _procesando.add(ruta);
    try {
      final double? db = await _leer(ruta);
      if (db != null) _cache[ruta] = db;
    } catch (_) {
      // sin etiqueta: se deja el volumen normal
    } finally {
      _procesando.remove(ruta);
    }
  }

  /// Expuesto para pruebas: extrae el ReplayGain de un binario con etiquetas.
  static double? gainDeBinario(Uint8List binario) => _buscarEtiqueta(binario);

  static Future<double?> _leer(String ruta) async {
    final File archivo = File(ruta);
    if (!await archivo.exists()) return null;
    final Uint8List bytes = await archivo.readAsBytes();
    if (bytes.length < 128) return null;
    final String ext = ruta.split('.').last.toLowerCase();
    if (ext == 'mp3') return _leerMp3(bytes);
    if (ext == 'flac') return _leerFlac(bytes);
    if (ext == 'ogg' || ext == 'oga' || ext == 'opus') return _leerOggOpus(bytes);
    if (ext == 'm4a' || ext == 'mp4' || ext == 'm4b' || ext == 'aac') return _leerMp4(bytes);
    // Muchos MP3 sin extension clara: intentar ID3 si empieza por "ID3".
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) return _leerMp3(bytes);
    return null;
  }

  /// Lee REPLAYGAIN_TRACK_GAIN / _ALBUM_GAIN de un ID3v2 (TXXX o texto).
  static double? _leerMp3(Uint8List b) {
    if (!(b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33)) return null;
    final int version = b[3];
    final int tam = ((b[6] & 0x7F) << 21) | ((b[7] & 0x7F) << 14) | ((b[8] & 0x7F) << 7) | (b[9] & 0x7F);
    final int fin = math.min(b.length, 10 + tam);
    int i = 10;
    double? track;
    double? album;
    while (i + 10 < fin) {
      final String id = String.fromCharCodes(b.sublist(i, i + 4));
      if (id.trim().isEmpty || id.codeUnits.any((int c) => c < 0x30 || c > 0x5A)) break;
      final int size = version >= 4
          ? ((b[i + 4] & 0x7F) << 21) | ((b[i + 5] & 0x7F) << 14) | ((b[i + 6] & 0x7F) << 7) | (b[i + 7] & 0x7F)
          : (b[i + 4] << 24) | (b[i + 5] << 16) | (b[i + 6] << 8) | b[i + 7];
      if (size <= 0 || i + 10 + size > fin) break;
      final Uint8List cuerpo = b.sublist(i + 10, i + 10 + size);
      if (id == 'TXXX') {
        final String texto = _texto(cuerpo);
        final String bajo = texto.toLowerCase();
        final double? db = _dbDeTexto(texto);
        if (bajo.contains('replaygain_track_gain')) track = db;
        if (bajo.contains('replaygain_album_gain')) album = db;
      }
      i += 10 + size;
    }
    return track ?? album;
  }

  /// Lee etiquetas Vorbis de un FLAC (bloque METADATA_BLOCK_VORBIS_COMMENT).
  static double? _leerFlac(Uint8List b) {
    if (b.length < 8 || b[0] != 0x66 || b[1] != 0x4C || b[2] != 0x61 || b[3] != 0x43) return null;
    int i = 4;
    while (i + 4 <= b.length) {
      final int cabecera = b[i];
      final bool ultimo = (cabecera & 0x80) != 0;
      final int tipo = cabecera & 0x7F;
      final int tam = (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
      i += 4;
      if (i + tam > b.length) break;
      if (tipo == 4) {
        final Uint8List bloque = b.sublist(i, i + tam);
        final String texto = latin1.decode(bloque, allowInvalid: true);
        final String bajo = texto.toLowerCase();
        final int pos = bajo.indexOf('replaygain_track_gain');
        if (pos >= 0) return _dbDeTexto(texto.substring(pos, math.min(texto.length, pos + 80)));
      }
      i += tam;
      if (ultimo) break;
    }
    return null;
  }


  /// OGG Vorbis / Opus: las etiquetas van en texto plano dentro del contenedor.
  static double? _leerOggOpus(Uint8List b) => _buscarEtiqueta(b);

  /// M4A / MP4: las etiquetas freeform de iTunes llevan el texto en claro.
  static double? _leerMp4(Uint8List b) => _buscarEtiqueta(b);

  /// Busca 'replaygain_track_gain' en el binario y extrae los dB.
  static double? _buscarEtiqueta(Uint8List b) {
    final StringBuffer texto = StringBuffer();
    for (final int c in b) {
      texto.write(c >= 32 && c < 127 ? String.fromCharCode(c) : ' ');
    }
    final String plano = texto.toString();
    final int pos = plano.toLowerCase().indexOf('replaygain_track_gain');
    if (pos < 0) return null;
    final String trozo = plano.substring(pos, math.min(plano.length, pos + 120));
    return _dbTexto(trozo);
  }

  /// Variante de _dbDeTexto que tambien acepta '= -7.5 dB'.
  static double? _dbTexto(String texto) {
    final RegExpMatch? m = RegExp(r'([+-]?\d+(?:[.,]\d+)?)\s*dB', caseSensitive: false).firstMatch(texto);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  /// Extrae "-7.25 dB" o "+3.1 dB" de un texto y lo devuelve como numero.
  static double? _dbDeTexto(String texto) {
    final RegExpMatch? m = RegExp(r'([+-]?\d+(?:[.,]\d+)?)\s*dB', caseSensitive: false).firstMatch(texto);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  /// Decodifica un TXXX (texto con separador nulo, UTF-8/UTF-16 segun charset).
  static String _texto(Uint8List cuerpo) {
    if (cuerpo.isEmpty) return '';
    final int codificacion = cuerpo[0];
    Uint8List resto = cuerpo.sublist(1);
    if (codificacion == 1 || codificacion == 2) {
      // UTF-16: se convierte a Latin1 aproximado ignorando bytes nulos.
      final List<int> limpios = <int>[];
      final bool be = codificacion == 2;
      for (int i = 0; i + 1 < resto.length; i += 2) {
        final int code = be ? (resto[i] << 8) | resto[i + 1] : resto[i] | (resto[i + 1] << 8);
        if (code != 0) limpios.add(code);
      }
      return String.fromCharCodes(limpios);
    }
    // UTF-8 / ISO-8859-1: se eliminan los nulos separadores.
    resto = Uint8List.fromList(resto.where((int c) => c != 0).toList());
    return utf8.decode(resto, allowMalformed: true);
  }
}