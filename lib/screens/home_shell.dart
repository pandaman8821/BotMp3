import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_importer.dart';
import '../screens/ai_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/songs_screen.dart';
import '../widgets/dialogs.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../widgets/glass.dart';
import '../widgets/mini_player.dart';

/// Contenedor principal con navegación inferior y reproductor persistente.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Animación de entrada del contenido al cambiar de pestaña.
  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void dispose() {
    _tabTransition.dispose();
    super.dispose();
  }

  /// Cambia de pestaña animando la entrada del contenido (en todas).
  void _changeTab(int value) {
    if (value == _index) return;
    setState(() => _index = value);
    if (!MediaQuery.disableAnimationsOf(context)) {
      _tabTransition.forward(from: 0);
    }
  }

  static const List<Widget> _screens = <Widget>[
    SongsScreen(),
    PlaylistsScreen(),
    SearchScreen(),
    AiScreen(),
    SettingsScreen(),
  ];

  bool _autoImportStarted = false;

  @override
  void initState() {
    super.initState();
    // Importación automática de la música del dispositivo al abrir la app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoImport());
  }

  /// Escanea MediaStore (si está activado) y avisa de las canciones nuevas.
  Future<void> _runAutoImport() async {
    if (_autoImportStarted || !mounted) return;
    _autoImportStarted = true;
    final SettingsProvider settings = context.read<SettingsProvider>();
    if (!settings.autoImport) return;
    await MediaImporter.ensureAudioPermission();
    // Android 13+: sin este permiso no hay notificación ni controles.
    await MediaImporter.ensureNotificationPermission();
    final LibraryProvider library = context.read<LibraryProvider>();
    final int added = await library.autoScan();
    // Si la caché crece demasiado, se limpia sola (nunca borra audio en uso).
    if (await library.cacheBytes() > 250 * 1024 * 1024) {
      await library.freeSpace();
    }
    if (!mounted || added <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added canciones añadidas a tu biblioteca 🎵')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo se reconstruye la barra cuando cambia la canción: el resto queda en
    // IndexedStack (estado preservado y sin recargas al cambiar de pestaña).
    context.watch<SettingsProvider>();
    context.watch<PlayerProvider>();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _tabTransition,
        builder: (BuildContext context, Widget? child) {
          // Aparición suave (deslizamiento + opacidad) al entrar en la pestaña.
          final double t = Curves.easeOutCubic.transform(_tabTransition.value);
          // La pestaña entra desde transparente, deslizándose y creciendo
          // ligeramente: el cambio se percibe en TODAS las pestañas.
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 26 * (1 - t)),
              child: Transform.scale(
                scale: 0.965 + 0.035 * t,
                child: child,
              ),
            ),
          );
        },
        child: IndexedStack(index: _index, children: _screens),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => AppDialogs.importSongs(context),
              icon: const Icon(Icons.library_add),
              label: const Text('Importar'),
            )
          : null,
      bottomNavigationBar: GlassGroup(
        child: Stack(
          children: <Widget>[
            // Fondo del cristal: la carátula del álbum muy difuminada + un velo.
            // Así el desenfoque toma los colores reales de la música.
            Positioned.fill(
              child: _GlassBackdrop(song: context.watch<PlayerProvider>().current),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GlassSurface(
                  quality: context.watch<SettingsProvider>().glassQuality,
                  borderRadius: 22,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: EdgeInsets.zero,
                  glowColor: context.watch<SettingsProvider>().glassActive
                      ? AppColors.aiViolet
                      : null,
                  child: const MiniPlayer(),
                ),
                GlassNavBar(
                  index: _index,
                  onChanged: _changeTab,
                  quality: context.watch<SettingsProvider>().glassQuality,
                  destinations: const <GlassNavDestination>[
                    GlassNavDestination(
                      icon: Icons.library_music_outlined,
                      selectedIcon: Icons.library_music,
                      label: 'Canciones',
                    ),
                    GlassNavDestination(
                      icon: Icons.queue_music_outlined,
                      selectedIcon: Icons.queue_music,
                      label: 'Listas',
                    ),
                    GlassNavDestination(
                      icon: Icons.search,
                      selectedIcon: Icons.saved_search,
                      label: 'Buscar',
                    ),
                    GlassNavDestination(
                      icon: Icons.smart_toy_outlined,
                      selectedIcon: Icons.smart_toy,
                      label: 'IA',
                    ),
                    GlassNavDestination(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Ajustes',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo decorativo del cristal: carátula difuminada y velo degradado.
class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop({this.song});

  final Song? song;

  @override
  Widget build(BuildContext context) {
    final String? path = song?.coverPath;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (path != null)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.darkBg.withAlpha(30),
                  AppColors.darkBg.withAlpha(205),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
