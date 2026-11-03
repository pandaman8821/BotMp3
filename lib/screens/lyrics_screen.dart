import '../l10n/app_localizations.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/lyrics_fetcher.dart';

/// Letra de la canción que está sonando.
///
/// Lee el archivo `.lrc` (o `.txt`) que esté **en la misma carpeta y con el
/// mismo nombre** que el audio. Si el archivo tiene tiempos (`[00:12.34]`), se
/// quitan para mostrar solo el texto.
class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key, required this.song});

  final Song song;

  Future<String?> _leerLetraLocal() async {
    final String ruta = song.path;
    if (ruta.isEmpty || ruta.startsWith('content://')) return null;
    final int punto = ruta.lastIndexOf('.');
    final String base = punto > 0 ? ruta.substring(0, punto) : ruta;
    for (final String ext in <String>['.lrc', '.LRC', '.txt', '.letra']) {
      try {
        final File archivo = File('$base$ext');
        if (await archivo.exists()) {
          final String texto = await archivo.readAsString();
          if (texto.trim().isNotEmpty) return texto;
        }
      } catch (_) {
        // Si un formato falla se prueba el siguiente.
      }
    }
    return null;
  }

  /// Quita las marcas de tiempo y las líneas vacías.
  static String _soloTexto(String letra) {
    final RegExp tiempos = RegExp(r'\[\d{1,2}:\d{2}(\.\d{1,3})?\]');
    return letra
        .split('\n')
        .map((String linea) => linea.replaceAll(tiempos, '').trim())
        .where((String linea) => linea.isNotEmpty)
        .join('\n');
  }

  Future<String?> _leerLetra() async {
    final String? local = await _leerLetraLocal();
    if (local != null) return local;
    // No hay archivo .lrc junto al audio: se busca la letra online.
    return LyricsFetcher.fetch(song.title, song.artist, album: song.album);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<String?>(
        future: _leerLetra(),
        builder: (BuildContext context, AsyncSnapshot<String?> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final String? letra = snap.data;
          if (letra == null || letra.trim().isEmpty) {
            return Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.lyricsNotFound,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.lyricsHowTo,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
            child: SelectableText(
              _soloTexto(letra),
              style: const TextStyle(fontSize: 16, height: 1.7),
            ),
          );
        },
      ),
    );
  }
}
