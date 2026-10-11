import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../models/ai_models.dart';
import '../models/song.dart';
import '../providers/ai_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/dialogs.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

/// Búsqueda global (título, artista, álbum, género, año, tags) + búsqueda
/// inteligente con explicación en lenguaje natural.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final Debouncer _debouncer = Debouncer();

  AiActionResult? _aiResult;
  bool _aiBusy = false;

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final AiAssistantProvider ai = context.watch<AiAssistantProvider>();

    final List<Song> results = library.visibleSongs;
    final List<Song> aiSongs = _aiResult == null
        ? <Song>[]
        : _aiResult!.suggestions
            .map((AiSongSuggestion suggestion) => suggestion.localSongId)
            .whereType<String>()
            .map(library.songById)
            .whereType<Song>()
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Filtros avanzados',
            icon: Badge(
              isLabelVisible: library.hasActiveFilters,
              child: const Icon(Icons.filter_alt_outlined),
            ),
            onPressed: () => AppDialogs.showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (String value) =>
                  _debouncer.run(() => library.setQuery(value)),
              onSubmitted: library.setQuery,
              decoration: InputDecoration(
                hintText: 'Título, artista, álbum, género, año o #tag',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          library.setQuery('');
                          setState(() => _aiResult = null);
                        },
                      ),
              ),
            ),
          ),
          // Atajos de búsqueda rápida
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                for (final String genre in <String>['Rock', 'Pop', 'Reggaetón', 'K-pop', 'Latin', 'Electronic'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(genre),
                      selected: library.genreFilter == genre,
                      onSelected: (bool value) =>
                          library.setGenreFilter(value ? genre : null),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Favoritas'),
                    selected: library.favoritesOnly,
                    onSelected: (_) => library.toggleFavoritesOnly(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _aiBusy ? null : _runAiSearch,
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: Text(_aiBusy ? 'Interpretando…' : 'Búsqueda inteligente'),
                  ),
                ),
                if (_aiResult != null) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Volver a la búsqueda normal',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _aiResult = null),
                  ),
                ],
              ],
            ),
          ),
          if (ai.busy) const LinearProgressIndicator(minHeight: 2),
          if (_aiResult != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: const Color(0xFF1D1D28),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.smart_toy, size: 18, color: Color(0xFF7C4DFF)),
                          const SizedBox(width: 8),
                          Text(
                            'IA (${ai.activeProvider.label})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (aiSongs.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => player.setQueue(aiSongs),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Reproducir'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_aiResult!.text, style: const TextStyle(fontSize: 13.5)),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: () {
              final List<Song> list = _aiResult != null && aiSongs.isNotEmpty ? aiSongs : results;
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off,
                  title: library.songs.isEmpty ? 'No hay canciones' : 'Sin resultados',
                  message: library.songs.isEmpty
                      ? 'Importa música para poder buscarla.'
                      : 'Prueba otros términos, quita filtros o usa la búsqueda inteligente.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: list.length,
                itemBuilder: (BuildContext context, int index) => SongTile(
                  song: list[index],
                  queueContext: list,
                ),
              );
            }(),
          ),
        ],
      ),
    );
  }

  Future<void> _runAiSearch() async {
    final String query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe qué buscas: "algo para entrenar", "rock de los 2000"…')),
      );
      return;
    }
    final AiAssistantProvider ai = context.read<AiAssistantProvider>();
    if (!ai.hasActiveKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configura la API key de ${ai.activeProvider.label} en Ajustes ▸ IA'),
        ),
      );
      return;
    }

    setState(() => _aiBusy = true);
    final AiActionResult? result = await ai.smartSearch(query);
    if (!mounted) return;
    setState(() {
      _aiBusy = false;
      _aiResult = result;
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ai.lastError ?? 'No se pudo completar la búsqueda')),
      );
    }
  }
}

/// Lista de géneros expuesta para autocompletar en otras pantallas.
List<String> get quickGenres => GenreCatalog.all.take(8).toList();
