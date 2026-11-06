import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Extrae el color dominante de una caratula para teñir el fondo del
/// reproductor. El resultado se cachea en memoria por ruta: no se vuelve a
/// decodificar la imagen en cada frame y no cuesta audio.
class CoverPalette {
  const CoverPalette._();

  static final Map<String, Color> _cache = <String, Color>{};

  /// Color ya calculado (o null si aun no se ha procesado).
  static Color? cached(String? ruta) => ruta == null || ruta.isEmpty ? null : _cache[ruta];

  /// Calcula (o devuelve de cache) el color dominante de la caratula.
  static Future<Color?> cargar(String? ruta) async {
    if (ruta == null || ruta.isEmpty) return null;
    final Color? enCache = _cache[ruta];
    if (enCache != null) return enCache;
    try {
      final File archivo = File(ruta);
      if (!await archivo.exists()) return null;
      final Uint8List bytes = await archivo.readAsBytes();
      final img.Image? decodificada = img.decodeImage(bytes);
      if (decodificada == null) return null;
      final img.Image mini = img.copyResize(decodificada, width: 18, height: 18);
      int r = 0;
      int g = 0;
      int b = 0;
      int n = 0;
      for (final img.Pixel p in mini) {
        final double lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        if (lum < 18 || lum > 245) continue; // ignora negros y blancos puros
        r += p.r.toInt();
        g += p.g.toInt();
        b += p.b.toInt();
        n++;
      }
      if (n == 0) return null;
      // Se oscurece un poco para poder usarlo como fondo con texto encima.
      final Color base = Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round());
      final Color resultado = Color.lerp(base, Colors.black, 0.42) ?? base;
      _cache[ruta] = resultado;
      return resultado;
    } catch (_) {
      return null;
    }
  }
}