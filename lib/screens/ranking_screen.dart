import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_art.dart';
import '../widgets/glass.dart';

enum _Periodo { todo, mes, semana }

extension on _Periodo {
  String get etiqueta => switch (this) {
        _Periodo.todo => 'Todo',
        _Periodo.mes => 'Último mes',
        _Periodo.semana => 'Última semana',
      };

  DateTime? get desde => switch (this) {
        _Periodo.todo => null,
        _Periodo.mes => DateTime.now().subtract(const Duration(days: 30)),
        _Periodo.semana => DateTime.now().subtract(const Duration(days: 7)),
      };
}

/// Ranking de lo que más escuchas: canciones, artistas, álbumes y géneros,
/// con filtro por periodo y opción de reproducir el «top».
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  _Periodo _periodo = _Periodo.todo;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final DateTime? desde = _periodo.desde;

    final List<Song> canciones = library.service.topCanciones(from: desde, limit: 100);
    final List<MapEntry<String, int>> artistas = library.service.topArtistas(from: desde);
    final List<MapEntry<String, int>> albumes = library.service.topAlbumes(from: desde);
    final List<MapEntry<String, int>> generos = library.service.topGeneros(from: desde);
    final int totalReproducciones =
        library.service.playsSince(desde).values.fold<int>(0, (int a, int b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: <Widget>[
          if (canciones.isNotEmpty)
            IconButton(
              tooltip: 'Reproducir el top 10',
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {
                final List<Song> top = canciones.take(10).toList();
                context.read<PlayerProvider>().setQueue(top);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const <Tab>[
            Tab(text: 'Canciones'),
            Tab(text: 'Artistas'),
            Tab(text: 'Álbumes'),
            Tab(text: 'Géneros'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: _Periodo.values.map((_Periodo valor) {
                      return ChoiceChip(
                        label: Text(valor.etiqueta, style: const TextStyle(fontSize: 12)),
                        selected: _periodo == valor,
                        onSelected: (_) => setState(() => _periodo = valor),
                      );
                    }).toList(),
                  ),
                ),
                Text(
                  '$totalReproducciones ${totalReproducciones == 1 ? 'reproducción' : 'reproducciones'}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.darkTextDim),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _listaCanciones(canciones),
                _listaSimple(artistas, Icons.person_outline, 'artista'),
                _listaSimple(albumes, Icons.album_outlined, 'álbum'),
                _listaSimple(generos, Icons.category_outlined, 'género'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vacio(String texto) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.leaderboard_outlined, size: 46),
              const SizedBox(height: 12),
              Text(texto, textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _listaCanciones(List<Song> canciones) {
    if (canciones.isEmpty) {
      return _vacio(
        'Todavía no hay reproducciones en este periodo.\n'
        'Escucha música y el ranking se irá construyendo solo.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 4),
      itemCount: canciones.length,
      itemBuilder: (BuildContext context, int index) {
        final Song song = canciones[index];
        return ListTile(
          leading: SizedBox(
            width: 56,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(width: 26, child: _medalla(index + 1)),
                CoverArt(path: song.coverPath, size: 40, borderRadius: 8),
              ],
            ),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${song.artist} · ${song.playCount} ${song.playCount == 1 ? 'reproducción' : 'reproducciones'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => context.read<PlayerProvider>().setQueue(
                canciones,
                startIndex: index,
              ),
        );
      },
    );
  }

  Widget _medalla(int puesto) {
    if (puesto <= 3) {
      const List<String> emojis = <String>['🥇', '🥈', '🥉'];
      return Text(emojis[puesto - 1], style: const TextStyle(fontSize: 17));
    }
    return Text(
      '$puesto',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );
  }

  Widget _listaSimple(List<MapEntry<String, int>> datos, IconData icono, String singular) {
    if (datos.isEmpty) {
      return _vacio('Todavía no hay datos de $singular en este periodo.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 4),
      itemCount: datos.length,
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, int> item = datos[index];
        return ListTile(
          leading: SizedBox(
            width: 56,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(width: 26, child: _medalla(index + 1)),
                Icon(icono, size: 22),
              ],
            ),
          ),
          title: Text(item.key, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.value} ${item.value == 1 ? 'reproducción' : 'reproducciones'}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            // Reproduce lo más escuchado de ese artista, álbum o género.
            final List<Song> coincidencias = context.read<LibraryProvider>().songs.where((
              Song song,
            ) {
              switch (singular) {
                case 'artista':
                  return song.artist == item.key;
                case 'álbum':
                  return song.album == item.key;
                default:
                  return song.genre == item.key;
              }
            }).toList();
            if (coincidencias.isNotEmpty) {
              context.read<PlayerProvider>().setQueue(coincidencias);
            }
          },
        );
      },
    );
  }
}
