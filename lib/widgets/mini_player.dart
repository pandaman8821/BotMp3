import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/player_screen.dart';
import 'cover_art.dart';
import 'wave_bars.dart';

/// Barra compacta de reproducción que vive sobre la barra de navegación.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerProvider player = context.watch<PlayerProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final Song? song = player.current;

    if (song == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                final Duration position = snapshot.data ?? Duration.zero;
                final Duration total = player.duration ?? Duration(milliseconds: song.durationMs);
                final double progress = total.inMilliseconds == 0
                    ? 0
                    : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppColors.green,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  CoverArt(path: song.coverPath, size: 46, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.darkTextDim),
                        ),
                      ],
                    ),
                  ),
                  if (settings.showWaveAnimation && player.playing) ...<Widget>[
                    const WaveBars(height: 20),
                    const SizedBox(width: 10),
                  ],
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
                      final bool playing = snapshot.data?.playing ?? false;
                      final bool loading =
                          snapshot.data?.processingState == ProcessingState.loading ||
                              snapshot.data?.processingState == ProcessingState.buffering;
                      if (loading) {
                        return const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        iconSize: 34,
                        tooltip: playing ? 'Pausar' : 'Reproducir',
                        icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
                        color: AppColors.green,
                        onPressed: player.togglePlayPause,
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 30,
                    tooltip: 'Siguiente',
                    icon: const Icon(Icons.skip_next),
                    onPressed: player.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección con acción opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Estado vacío con icono, texto y acción.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary.withAlpha(((0.7) * 255).round())),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.darkTextDim),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de tiempo corto reutilizable.
String shortDuration(Duration? duration) => Formatters.duration(duration);
