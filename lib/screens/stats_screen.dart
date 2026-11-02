import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';

/// Estadisticas de escucha calculadas con la biblioteca local.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final List<Song> canciones = context.watch<LibraryProvider>().songs;
    final int totalReproducciones = canciones.fold<int>(0, (int a, Song s) => a + s.playCount);
    final int conReproducciones = canciones.where((Song s) => s.playCount > 0).length;
    final Map<String, int> porGenero = <String, int>{};
    for (final Song s in canciones) {
      if (s.genre.trim().isEmpty) continue;
      porGenero[s.genre] = (porGenero[s.genre] ?? 0) + s.playCount;
    }
    final List<MapEntry<String, int>> generos = porGenero.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text(loc.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Tarjeta(icono: Icons.play_circle_outline, titulo: loc.statsTotalPlays, valor: '$totalReproducciones'),
          _Tarjeta(icono: Icons.library_music_outlined, titulo: loc.statsUniqueSongs, valor: '$conReproducciones / ${canciones.length}'),
          const SizedBox(height: 12),
          if (generos.isNotEmpty) ...<Widget>[
            Text(loc.genreLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (final MapEntry<String, int> g in generos.take(8))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(g.key),
                trailing: Text('${g.value}', style: const TextStyle(color: AppColors.green)),
              ),
          ],
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.icono, required this.titulo, required this.valor});

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icono, color: AppColors.green),
        title: Text(titulo),
        trailing: Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
