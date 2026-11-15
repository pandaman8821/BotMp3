import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/player_screen.dart';
import 'cover_art.dart';
import 'glass.dart';
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
      child: GestureDetector(
        // Gestos rapidos sin abrir la pantalla (utiles conduciendo o con el
        // movil guardado): doble toque pausa o reanuda, pulsacion larga pasa a
        // la siguiente cancion.
        onDoubleTap: player.togglePlayPause,
        // Deslizar: a la izquierda pasa a la siguiente cancion, a la derecha
        // vuelve a la anterior.
        onHorizontalDragEnd: (DragEndDetails detalles) {
          final double velocidad = detalles.primaryVelocity ?? 0;
          if (velocidad < -50) {
            player.next();
          } else if (velocidad > 50) {
            player.previous();
          }
        },
        onLongPress: player.next,
        onTap: () {
          Hapticos.toque();
          Navigator.of(context).push(rutaReproductor());
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
              child: Row(
                children: <Widget>[
                  // Misma etiqueta Hero que la portada grande: al abrir el
                  // reproductor la caratula "vuela" desde aqui.
                  Hero(
                    tag: 'cover_${song.id}',
                    child: CoverArt(path: song.coverPath, size: 48, borderRadius: 12),
                  ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
                        ),
                      ],
                    ),
                  ),
                  if (settings.showWaveAnimation && player.playing) ...<Widget>[
                    const WaveBars(height: 18),
                    const SizedBox(width: 8),
                  ],
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
                      final bool playing = snapshot.data?.playing ?? false;
                      final bool loading =
                          snapshot.data?.processingState == ProcessingState.loading ||
                              snapshot.data?.processingState == ProcessingState.buffering;
                      return BotonPlay(
                        playing: playing,
                        loading: loading,
                        size: 44,
                        onPressed: player.togglePlayPause,
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 28,
                    tooltip: AppLocalizations.of(context).actNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () {
                      Hapticos.toque();
                      player.next();
                    },
                  ),
                ],
              ),
            ),
            // Progreso fino y redondeado en la base de la tarjeta.
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                final Duration position = snapshot.data ?? Duration.zero;
                final Duration total = player.duration ?? Duration(milliseconds: song.durationMs);
                final double progress = total.inMilliseconds == 0
                    ? 0
                    : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: _BarraLiquida(progreso: progress),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de progreso de "líquido luminoso": degradado del color principal al
/// de acento, con un brillo suave en la punta que avanza.
class _BarraLiquida extends StatelessWidget {
  const _BarraLiquida({required this.progreso});

  final double progreso;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      value: '${(progreso * 100).round()}%',
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progreso,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: <Color>[scheme.primary, scheme.tertiary]),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: scheme.tertiary.withAlpha(110), blurRadius: 6),
                  ],
                ),
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
                    style: TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
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
            // Burbuja de cristal con el icono (respeta los ajustes de cristal).
            GlassSurface(
              width: 116,
              height: 116,
              borderRadius: 58,
              padding: EdgeInsets.zero,
              quality: context.watch<SettingsProvider>().glassQuality,
              glowColor: AppColors.green,
              child: Center(child: Icon(icon, size: 54, color: AppColors.green)),
            ),
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
                style: TextStyle(fontSize: 14, color: AppColors.darkTextDim),
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

/// Abre el reproductor deslizandolo desde abajo (como las apps de musica).
/// Con "reducir movimiento" la transicion es instantanea.
Route<void> rutaReproductor() {
  return PageRouteBuilder<void>(
    transitionDuration: Motion.ajustar(Motion.lento),
    reverseTransitionDuration: Motion.ajustar(Motion.normal),
    pageBuilder: (_, __, ___) => const PlayerScreen(),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curva = CurvedAnimation(
        parent: animation,
        curve: Motion.entrada,
        reverseCurve: Motion.salida,
      );
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curva),
        child: child,
      );
    },
  );
}

/// Boton circular de reproducir/pausar con el color de acento del tema.
/// Lo usan el mini reproductor y el reproductor grande, asi se ven iguales.
class BotonPlay extends StatelessWidget {
  const BotonPlay({
    super.key,
    required this.playing,
    required this.onPressed,
    this.loading = false,
    this.size = 72,
  });

  final bool playing;
  final bool loading;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations loc = AppLocalizations.of(context);
    return Tooltip(
      message: playing ? loc.actPause : loc.play,
      child: Semantics(
        button: true,
        label: playing ? loc.actPause : loc.play,
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: AppColors.green,
            shape: const CircleBorder(),
            elevation: size > 56 ? 6 : 0,
            shadowColor: AppColors.green.withAlpha(120),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Hapticos.accion();
                onPressed();
              },
              child: Center(
                child: loading
                    ? SizedBox(
                        width: size * 0.4,
                        height: size * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.onPrimary,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: Motion.ajustar(Motion.rapido),
                        transitionBuilder: (Widget child, Animation<double> a) =>
                            ScaleTransition(scale: a, child: child),
                        child: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(playing),
                          size: size * 0.56,
                          color: scheme.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
