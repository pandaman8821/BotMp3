import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../core/formatters.dart';
import '../services/settings_service.dart';
import '../widgets/cover_art.dart';
import 'album_screen.dart';
import 'artist_screen.dart';

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
  final TextEditingController _busqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    final int guardado = SettingsService.actual?.rankingPeriodo ?? 0;
    _periodo = _Periodo.values[guardado.clamp(0, _Periodo.values.length - 1)];
  }

  /// Quita acentos para que el filtro no falle con tildes.
  static String _limpio(String texto) {
    const Map<String, String> mapa = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    String salida = texto.toLowerCase();
    mapa.forEach((String k, String v) => salida = salida.replaceAll(k, v));
    return salida;
  }

  /// Menu al mantener pulsada una cancion del ranking.
  Future<void> _menuCancion(BuildContext context, Song song) async {
    final LibraryProvider library = context.read<LibraryProvider>();
    final bool esFavorita = library.songById(song.id)?.isFavorite ?? false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(esFavorita ? Icons.favorite : Icons.favorite_border,
                  color: esFavorita ? AppColors.danger : null),
              title: Text(AppLocalizations.of(context).actFavorite(song.title)),
              onTap: () async {
                await library.toggleFavorite(song.id);
                if (sheet.mounted) Navigator.of(sheet).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(AppLocalizations.of(context).rankOpenArtist),
              onTap: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ArtistScreen(artist: song.artist),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.album_outlined),
              title: Text(AppLocalizations.of(context).rankSeeAlbum),
              onTap: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AlbumScreen(album: song.album),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final DateTime? desde = _periodo.desde;

    // Si algo fallara al calcular el ranking, se enseña el error en pantalla
    // en lugar de una pantalla en blanco.
    List<Song> canciones = const <Song>[];
    List<MapEntry<String, int>> artistas = const <MapEntry<String, int>>[];
    List<MapEntry<String, int>> albumes = const <MapEntry<String, int>>[];
    List<MapEntry<String, int>> generos = const <MapEntry<String, int>>[];
    int totalReproducciones = 0;
    Map<String, int> conteos = const <String, int>{};
    String? errorRanking;
    try {
      canciones = library.service.topCanciones(from: desde, limit: 100);
      artistas = library.service.topArtistas(from: desde);
      albumes = library.service.topAlbumes(from: desde);
      generos = library.service.topGeneros(from: desde);
      conteos = library.service.playsSince(desde);
      totalReproducciones =
          conteos.values.fold<int>(0, (int a, int b) => a + b);
    } catch (error) {
      errorRanking = '$error';
    }

    // Filtro de texto: afecta a las 4 pestanas a la vez.
    final String consulta = _limpio(_busqueda.text.trim());
    if (consulta.isNotEmpty) {
      canciones = canciones
          .where((Song s) => _limpio('${s.title} ${s.artist} ${s.album}').contains(consulta))
          .toList();
      artistas = artistas
          .where((MapEntry<String, int> e) => _limpio(e.key).contains(consulta))
          .toList();
      albumes = albumes
          .where((MapEntry<String, int> e) => _limpio(e.key).contains(consulta))
          .toList();
      generos = generos
          .where((MapEntry<String, int> e) => _limpio(e.key).contains(consulta))
          .toList();
    }
    final int maximo = conteos.isEmpty
        ? 0
        : conteos.values.reduce((int a, int b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context).resetStatsTitle,
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final bool? confirmar = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) => AlertDialog(
                  title: Text(AppLocalizations.of(context).resetRanking),
                  content: Text(
                    AppLocalizations.of(context).resetStatsBody,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Reiniciar'),
                    ),
                  ],
                ),
              );
              if (confirmar != true || !context.mounted) return;
              await context.read<LibraryProvider>().resetPlayStats();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ranking reiniciado')),
              );
            },
          ),
          if (canciones.isNotEmpty)
            IconButton(
              tooltip: AppLocalizations.of(context).playTop10,
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
          tabs: <Tab>[
            Tab(text: AppLocalizations.of(context).tabSongs),
            Tab(text: AppLocalizations.of(context).sortArtist),
            Tab(text: AppLocalizations.of(context).albumLabel),
            Tab(text: AppLocalizations.of(context).genreLabel),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (errorRanking != null)
            Container(
              width: double.infinity,
              color: Colors.redAccent.withAlpha(38),
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                'Ranking error: $errorRanking',
                style: const TextStyle(fontSize: 12),
              ),
            ),
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
                        onSelected: (_) {
                          setState(() => _periodo = valor);
                          SettingsService.actual?.setRankingPeriodo(valor.index);
                        },
                      );
                    }).toList(),
                  ),
                ),
                Text(
                  '$totalReproducciones ${totalReproducciones == 1 ? 'reproducción' : 'reproducciones'}',
                  style: TextStyle(fontSize: 11.5, color: AppColors.darkTextDim),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: AppLocalizations.of(context).rankSearchHint,
                suffixIcon: _busqueda.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _listaCanciones(canciones, conteos, maximo),
                _listaSimple(artistas, Icons.person_outline,
                    AppLocalizations.of(context).sortArtist, maximo,
                    tipo: 'artista'),
                _listaSimple(albumes, Icons.album_outlined,
                    AppLocalizations.of(context).albumLabel, maximo,
                    tipo: 'album'),
                _listaSimple(generos, Icons.category_outlined,
                    AppLocalizations.of(context).genreLabel, maximo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla vacia, con boton para poner algo de musica al azar.
  Widget _vacio(String texto, {VoidCallback? alAzar}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.green.withAlpha(40),
                      AppColors.aiViolet.withAlpha(30),
                    ],
                  ),
                  border: Border.all(color: AppColors.green.withAlpha(70)),
                ),
                child: const Icon(Icons.leaderboard_outlined, size: 46),
              ),
              const SizedBox(height: 14),
              Text(texto, textAlign: TextAlign.center),
              if (alAzar != null) ...<Widget>[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: alAzar,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(AppLocalizations.of(context).rankPlaySomething),
                ),
              ],
            ],
          ),
        ),
      );

  /// Reproduce al azar toda la biblioteca (para salir del ranking vacio).
  void _reproducirAlAzar() {
    final List<Song> todas = context.read<LibraryProvider>().songs;
    if (todas.isEmpty) return;
    final List<Song> mezcla = List<Song>.from(todas)..shuffle();
    context.read<PlayerProvider>().setQueue(mezcla);
  }

  Widget _listaCanciones(
    List<Song> canciones,
    Map<String, int> conteos,
    int maximo,
  ) {
    if (canciones.isEmpty) {
      return _vacio(
        AppLocalizations.of(context).rankEmptyPeriod,
        alAzar: _reproducirAlAzar,
      );
    }
    final AppLocalizations loc = AppLocalizations.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, top: 4),
      itemCount: canciones.length,
      itemBuilder: (BuildContext context, int index) {
        final Song song = canciones[index];
        final int jugadas = conteos[song.id] ?? 0;
        final DateTime? ultima = song.lastPlayedAt;
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ultima == null
                    ? '${song.artist} · ${loc.rankPlays('$jugadas')}'
                    : '${song.artist} · ${loc.rankPlays('$jugadas')} · '
                        '${loc.rankLastPlayed(Formatters.relativeDate(ultima))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 5),
              // Barra proporcional: cuanto pesa frente al numero 1.
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: maximo <= 0 ? 0 : (jugadas / maximo).clamp(0.02, 1.0),
                  minHeight: 4,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => context.read<PlayerProvider>().setQueue(
                canciones,
                startIndex: index,
              ),
          onLongPress: () => _menuCancion(context, song),
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

  Widget _listaSimple(
    List<MapEntry<String, int>> datos,
    IconData icono,
    String singular,
    int maximo, {
    String? tipo,
  }) {
    if (datos.isEmpty) {
      return _vacio(AppLocalizations.of(context).rankEmptyData(singular));
    }
    final AppLocalizations loc = AppLocalizations.of(context);
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                loc.rankPlays('${item.value}'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: maximo <= 0 ? 0 : (item.value / maximo).clamp(0.02, 1.0),
                  minHeight: 4,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            // Artista y album abren su pantalla; genero reproduce las suyas.
            if (tipo == 'artista') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ArtistScreen(artist: item.key),
                ),
              );
              return;
            }
            if (tipo == 'album') {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AlbumScreen(album: item.key),
                ),
              );
              return;
            }
            final List<Song> coincidencias =
                context.read<LibraryProvider>().songs.where((Song song) {
              return song.genre == item.key;
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
