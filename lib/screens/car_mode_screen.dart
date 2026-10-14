import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/player_provider.dart';

/// Modo coche: controles enormes para usar la app sin mirar la pantalla.
///
/// Solo depende de lo que ya existe en el reproductor (nada nativo ni
/// dependencias nuevas): anterior, pausa/reanudar y siguiente, con la carátula
/// y el título muy grandes y contraste alto.
class CarModeScreen extends StatelessWidget {
  const CarModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerProvider player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Modo coche'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.directions_car,
                        size: 46,
                        color: Colors.white.withAlpha(120),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        player.current?.title ?? 'Nada sonando',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        player.current?.artist ?? 'Pon algo a sonar',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  _BotonGrande(
                    icon: Icons.skip_previous,
                    label: 'Anterior',
                    onTap: player.previous,
                  ),
                  const SizedBox(width: 14),
                  _BotonGrande(
                    icon: player.playing ? Icons.pause : Icons.play_arrow,
                    label: player.playing ? 'Pausa' : 'Reproducir',
                    destacado: true,
                    onTap: player.togglePlayPause,
                  ),
                  const SizedBox(width: 14),
                  _BotonGrande(
                    icon: Icons.skip_next,
                    label: 'Siguiente',
                    onTap: player.next,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Desliza el dedo por la barra de abajo o usa estos botones: están '
                'pensados para pulsarlos sin apartar la vista de la carretera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado y grande, legible de un vistazo.
class _BotonGrande extends StatelessWidget {
  const _BotonGrande({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destacado = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final Color fondo =
        destacado ? AppColors.green : Colors.white.withAlpha(28);
    final Color tinta = destacado ? Colors.black : Colors.white;

    return Expanded(
      child: SizedBox(
        height: 132,
        child: Material(
          color: fondo,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 54, color: tinta),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: tinta,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
