import '../services/audio_device_watcher.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_importer.dart';
import '../screens/ai_screen.dart';
import '../screens/home_dashboard.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _index = 0;

  /// Animación de entrada del contenido al cambiar de pestaña.
  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  static final List<Widget> _screens = <Widget>[
    HomeDashboard(),
    SongsScreen(),
    PlaylistsScreen(),
    SearchScreen(),
    AiScreen(),
    SettingsScreen(),
  ];

  bool _autoImportStarted = false;
  DateTime _ultimoEscaneo = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurarSesion());
    // Reanudar/pausar al conectar o quitar auriculares/Bluetooth.
    AudioDeviceWatcher.iniciar();
    AudioDeviceWatcher.onCambio = _alCambiarDispositivoAudio;
    // Boton de favorito de la notificacion.
    JustAudioBackground.onCustomAction = (String name, Map<String, dynamic>? extra) async {
      if (name != 'favorito' || !mounted) return;
      final Song? actual = context.read<PlayerProvider>().current;
      if (actual == null) return;
      await context.read<LibraryProvider>().toggleFavorite(actual.id);
    };
    // Importación automática al abrir la app y cada vez que vuelves a ella
    // (así aparecen las canciones nuevas sin reiniciar).
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoImport());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAutoImport(silencioso: true);
    }
  }

  /// Escanea MediaStore (si está activado) y avisa de las canciones nuevas.
  Future<void> _runAutoImport({bool silencioso = false}) async {
    if (!mounted) return;
    final SettingsProvider settings = context.read<SettingsProvider>();
    if (!settings.autoImport) return;
    if (silencioso) {
      // Margen mínimo entre escaneos automáticos (evita repetirlos si
      // vuelves a la app varias veces seguidas).
      if (DateTime.now().difference(_ultimoEscaneo) <
          const Duration(seconds: 20)) {
        return;
      }
    } else if (_autoImportStarted) {
      return;
    }
    _autoImportStarted = true;
    _ultimoEscaneo = DateTime.now();
    await MediaImporter.ensureAudioPermission();
    // Android 13+: sin este permiso no hay notificación ni controles.
    await MediaImporter.ensureNotificationPermission();
    if (!mounted) return;
    final LibraryProvider library = context.read<LibraryProvider>();
    final int added = await library.autoScan();
    // Copia de seguridad interna si han pasado 7 dias (no sube nada fuera).
    await library.autoBackup();
    // Si la caché crece demasiado, se limpia sola (nunca borra audio en uso).
    if (await library.cacheBytes() > 250 * 1024 * 1024) {
      await library.freeSpace();
    }
    if (!mounted || added <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).songsAddedToLibrary(added))),
    );
  }

  /// Reanuda la musica al conectar auriculares/Bluetooth y la pausa al quitarlos.
  Future<void> _alCambiarDispositivoAudio(String evento) async {
    if (!mounted) return;
    final SettingsService ajustes = await SettingsService.instance();
    final PlayerProvider reproductor = context.read<PlayerProvider>();
    if (evento == 'conectado') {
      if (ajustes.reanudarAlConectar && !reproductor.playing && reproductor.current != null) {
        await reproductor.play();
      }
    } else if (evento == 'desconectado') {
      if (ajustes.pausarAlDesconectar && reproductor.playing) {
        await reproductor.pause();
      }
    }
  }

  /// Continua donde lo dejaste la ultima vez (sin empezar a sonar).
  Future<void> _restaurarSesion() async {
    final SettingsService ajustes = await SettingsService.instance();
    final String? id = ajustes.ultimaCancionId;
    if (id == null || !mounted) return;
    final LibraryProvider biblioteca = context.read<LibraryProvider>();
    final PlayerProvider reproductor = context.read<PlayerProvider>();
    if (reproductor.current != null) return;
    final Song? cancion = biblioteca.songById(id);
    if (cancion == null) return;
    await reproductor.prepararSesion(cancion, Duration(milliseconds: ajustes.ultimaPosicionMs));
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
      floatingActionButton: _index == 1
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
                  destinations: <GlassNavDestination>[
                    GlassNavDestination(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: AppLocalizations.of(context).tabHome,
                    ),
                    GlassNavDestination(
                      icon: Icons.library_music_outlined,
                      selectedIcon: Icons.library_music,
                      label: AppLocalizations.of(context).tabSongs,
                    ),
                    GlassNavDestination(
                      icon: Icons.queue_music_outlined,
                      selectedIcon: Icons.queue_music,
                      label: AppLocalizations.of(context).tabPlaylists,
                    ),
                    GlassNavDestination(
                      icon: Icons.search,
                      selectedIcon: Icons.saved_search,
                      label: AppLocalizations.of(context).tabSearch,
                    ),
                    GlassNavDestination(
                      icon: Icons.smart_toy_outlined,
                      selectedIcon: Icons.smart_toy,
                      label: AppLocalizations.of(context).tabAi,
                    ),
                    GlassNavDestination(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: AppLocalizations.of(context).tabSettings,
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
