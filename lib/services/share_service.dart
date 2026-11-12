import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Compartir con la hoja de Android **sin romper derechos de autor**.
///
/// Solo se comparte informacion (titulo, artista, album, lista, letra) y
/// enlaces a busquedas legales. Nunca se comparte el archivo de audio: la app
/// no distribuye musica, solo cuenta que estas escuchando.
class ShareService {
  const ShareService._();

  static const MethodChannel _canal = MethodChannel('botmp3/share');

  /// Comparte texto plano. Si el canal falla, lo copia al portapapeles.
  static Future<bool> texto(String contenido, {String? asunto}) async {
    try {
      final bool? ok = await _canal.invokeMethod<bool>('texto', <String, dynamic>{
        'texto': contenido,
        'asunto': asunto,
      });
      return ok ?? false;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: contenido));
      return false;
    }
  }

  /// Comparte un archivo por FileProvider (imagen de la tarjeta).
  static Future<bool> compartirRuta(String ruta, {String mime = 'image/png', String? texto}) async {
    try {
      final bool? ok = await _canal.invokeMethod<bool>('archivo', <String, dynamic>{
        'ruta': ruta,
        'mime': mime,
        'texto': texto,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Enlaces de busqueda en servicios legales (no descargas).
  static String enlacesLegales(String titulo, String artista) {
    final String consulta = Uri.encodeComponent('$artista $titulo'.trim());
    return 'https://open.spotify.com/search/$consulta\n'
        'https://music.youtube.com/search?q=$consulta';
  }

  /// Texto para compartir una cancion.
  static String textoCancion({
    required String titulo,
    required String artista,
    String? album,
    required String atribucion,
  }) {
    final StringBuffer buffer = StringBuffer()..writeln('🎵 $titulo — $artista');
    if (album != null && album.trim().isNotEmpty) {
      buffer.writeln('💿 ${album.trim()}');
    }
    buffer
      ..writeln()
      ..writeln(enlacesLegales(titulo, artista))
      ..writeln()
      ..write(atribucion);
    return buffer.toString();
  }

  /// Texto para compartir una lista completa (numerada).
  static String textoLista({
    required String nombre,
    required List<String> canciones,
    required String atribucion,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('🎧 $nombre')
      ..writeln();
    for (int i = 0; i < canciones.length; i++) {
      buffer.writeln('${i + 1}. ${canciones[i]}');
    }
    buffer
      ..writeln()
      ..write(atribucion);
    return buffer.toString();
  }

  /// Convierte el widget marcado con [clave] en PNG y lo comparte.
  static Future<bool> compartirWidget(GlobalKey clave, {String? texto}) async {
    try {
      final RenderRepaintBoundary? limite =
          clave.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (limite == null) return false;
      final ui.Image imagen = await limite.toImage(pixelRatio: 3);
      final ByteData? datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (datos == null) return false;
      final Directory cache = await getTemporaryDirectory();
      final File archivo = File(
        '${cache.path}/botmp3_compartir_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await archivo.writeAsBytes(datos.buffer.asUint8List(), flush: true);
      return await compartirRuta(archivo.path, texto: texto);
    } catch (_) {
      return false;
    }
  }
}
