import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';

/// Navegador de carpetas: explora el almacenamiento segun las rutas de la
/// biblioteca y permite reproducir una carpeta entera.
class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  String _ruta = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();

    final List<Song> conRuta = library.visibleSongs
        .where((Song s) => s.path.isNotEmpty && !s.path.startsWith('content://'))
        .toList();

    if (_ruta.isEmpty) {
      // Raiz: carpetas de primer nivel de cada ruta (padre del archivo).
      final Set<String> raices = <String>{};
      for (final Song s in conRuta) {
        raices.add(_padre(s.path));
      }
      final List<String> lista = raices.toList()..sort();
      return Scaffold(
        appBar: AppBar(title: Text(loc.foldersTitle), backgroundColor: Colors.transparent),
        body: lista.isEmpty
            ? Center(child: Text(loc.foldersEmpty, style: TextStyle(color: AppColors.darkTextDim)))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: lista.length,
                itemBuilder: (BuildContext context, int i) {
                  final String carpeta = lista[i];
                  final int n = conRuta.where((Song s) => _padre(s.path) == carpeta).length;
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(_nombre(carpeta), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(loc.albumSongsCount(n), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _ruta = carpeta),
                  );
                },
              ),
      );
    }

    // Dentro de una carpeta: subcarpetas + canciones directas.
    final String prefijo = '$_ruta/';
    final Set<String> subcarpetas = <String>{};
    for (final Song s in conRuta) {
      if (!s.path.startsWith(prefijo)) continue;
      final String resto = s.path.substring(prefijo.length);
      final int corte = resto.indexOf('/');
      if (corte > 0) subcarpetas.add(prefijo + resto.substring(0, corte));
    }
    final List<Song> aqui = conRuta.where((Song s) => _padre(s.path) == _ruta).toList()
      ..sort((Song a, Song b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final List<String> hijas = subcarpetas.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(_nombre(_ruta), maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _ruta = _padre(_ruta)),
        ),
        actions: <Widget>[
          if (aqui.isNotEmpty)
            IconButton(
              tooltip: loc.playAll,
              icon: const Icon(Icons.play_arrow),
              onPressed: () => player.playSong(aqui.first, context: aqui),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: <Widget>[
          for (final String sub in hijas)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(_nombre(sub), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _ruta = sub),
            ),
          for (final Song song in aqui)
            ListTile(
              leading: CoverArt(path: song.coverPath, size: 44),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => player.playSong(song, context: aqui),
            ),
          if (hijas.isEmpty && aqui.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(loc.foldersEmpty, style: TextStyle(color: AppColors.darkTextDim)),
            ),
        ],
      ),
    );
  }

  static String _padre(String ruta) {
    final int i = ruta.lastIndexOf(Platform.pathSeparator);
    return i > 0 ? ruta.substring(0, i) : ruta;
  }

  static String _nombre(String ruta) {
    final List<String> partes = ruta.split(Platform.pathSeparator).where((String p) => p.isNotEmpty).toList();
    return partes.isEmpty ? ruta : partes.last;
  }
}