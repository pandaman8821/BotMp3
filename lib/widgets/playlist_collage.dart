import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/song.dart';
import 'cover_art.dart';

/// Caratula de una lista hecha con las 4 primeras portadas (2x2).
///
/// Si no hay canciones con portada, muestra el icono de lista y nada mas.
class PlaylistCollage extends StatelessWidget {
  const PlaylistCollage({super.key, required this.songs, this.size = 48});

  final List<Song> songs;
  final double size;

  @override
  Widget build(BuildContext context) {
    final List<String?> portadas = songs
        .map((Song s) => s.coverPath)
        .where((String? p) => p != null && p.isNotEmpty)
        .take(4)
        .toList();

    if (portadas.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.26),
          color: AppColors.darkSurface,
        ),
        child: Icon(
          Icons.queue_music,
          size: size * 0.5,
          color: AppColors.green,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              CoverArt(
                path: i < portadas.length ? portadas[i] : portadas.first,
                size: size / 2,
                borderRadius: 0,
              ),
          ],
        ),
      ),
    );
  }
}