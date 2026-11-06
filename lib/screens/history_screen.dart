import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/settings_service.dart';
import '../widgets/cover_art.dart';

/// Historial de reproduccion (las ultimas 100 canciones, mas reciente arriba).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _ids = <String>[];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final SettingsService ajustes = await SettingsService.instance();
    if (!mounted) return;
    setState(() => _ids = ajustes.historial);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context);
    final LibraryProvider library = context.watch<LibraryProvider>();
    final PlayerProvider player = context.watch<PlayerProvider>();
    final List<Song> canciones = <Song>[
      for (final String id in _ids)
        if (library.songById(id) != null) library.songById(id)!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.historyTitle),
        actions: <Widget>[
          if (canciones.isNotEmpty)
            IconButton(
              tooltip: loc.historyClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final SettingsService ajustes = await SettingsService.instance();
                await ajustes.limpiarHistorial();
                if (mounted) setState(() => _ids = <String>[]);
              },
            ),
        ],
      ),
      body: canciones.isEmpty
          ? Center(
              child: Text(
                loc.historyEmpty,
                style: TextStyle(color: AppColors.darkTextDim),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: canciones.length,
              itemBuilder: (BuildContext context, int i) {
                final Song song = canciones[i];
                return ListTile(
                  leading: CoverArt(path: song.coverPath, size: 44),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => player.playSong(song, context: canciones),
                );
              },
            ),
    );
  }
}