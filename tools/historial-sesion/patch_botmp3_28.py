"""BotMp3 v1.5.0 — filtro/orden, importación automática y audios de apps.

Tres cosas pedidas por el usuario:

  1. El orden alfabético fallaba con acentos («Ámbar» iba después de la Z) y las
     canciones sin artista/álbum encabezaban la lista. Ahora se compara sin
     acentos, los valores vacíos van al final y el menú marca la opción activa.
  2. La importación automática solo corría al abrir la app: había que reiniciarla
     para ver la música nueva. Ahora se reescanea al volver a la app (resumed).
  3. Nuevo ajuste para **incluir o no los audios de apps de mensajería y notas de
     voz** (por defecto: no se importan ni se muestran).
"""

from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")

ok: list[str] = []
fail: list[str] = []


def read(rel: str) -> str:
    with open(os.path.join(PROJ, rel), "r", encoding="utf-8") as handle:
        return handle.read()


def write(rel: str, text: str) -> None:
    with open(os.path.join(PROJ, rel), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def patch(rel: str, pattern: str, replacement: str, *, flags: int = 0,
          label: str = "", skip_if: str = "") -> None:
    text = read(rel)
    if skip_if and skip_if in text:
        ok.append(f"{rel}: {label} (ya aplicado)")
        return
    new, n = re.subn(pattern, lambda _m: replacement, text, count=1, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label}")


# ============================================================ 1. Ajuste nuevo
patch("lib/services/settings_service.dart",
      r"  static SettingsService\? _instance;",
      "  static SettingsService? _instance;\n\n"
      "  /// Instancia ya creada (consulta síncrona). La usan servicios que no\n"
      "  /// pueden esperar a `instance()`.\n"
      "  static SettingsService? get actual => _instance;",
      label="acceso síncrono a los ajustes")

patch("lib/services/settings_service.dart",
      r"  Future<void> setAutoImport\(bool value\) async \{\n"
      r"    await _prefs\.setBool\('auto_import', value\);\n"
      r"  \}",
      "  Future<void> setAutoImport(bool value) async {\n"
      "    await _prefs.setBool('auto_import', value);\n"
      "  }\n\n"
      "  /// Importar también audios de apps (WhatsApp, Telegram…) y notas de voz.\n"
      "  /// Desactivado (por defecto) solo se importa música.\n"
      "  bool get importMediaAudio => _prefs.getBool('import_media_audio') ?? false;\n\n"
      "  Future<void> setImportMediaAudio(bool value) async {\n"
      "    await _prefs.setBool('import_media_audio', value);\n"
      "  }",
      label="ajuste de audios de apps")

patch("lib/providers/settings_provider.dart",
      r"  bool get autoImport => _service\.autoImport;",
      "  bool get autoImport => _service.autoImport;\n\n"
      "  /// Incluir audios de apps de mensajería y notas de voz.\n"
      "  bool get importMediaAudio => _service.importMediaAudio;",
      label="getter en el proveedor de ajustes")

patch("lib/providers/settings_provider.dart",
      r"  bool get importMediaAudio => _service\.importMediaAudio;",
      "  bool get importMediaAudio => _service.importMediaAudio;\n\n"
      "  Future<void> setImportMediaAudio(bool value) async {\n"
      "    await _service.setImportMediaAudio(value);\n"
      "    notifyListeners();\n"
      "  }",
      label="setter en el proveedor de ajustes")

# ============================================================ 2. Escaneo nativo
patch("lib/services/media_scanner.dart",
      r"  static Future<List<ScannedTrack>> queryAudio\(\) async \{\n"
      r"    try \{\n"
      r"      final List<dynamic>\? raw = await _channel\.invokeMethod<List<dynamic>>\('queryAudio'\);",
      "  static Future<List<ScannedTrack>> queryAudio({bool includeNonMusic = false}) async {\n"
      "    try {\n"
      "      // `includeNonMusic` decide si se incluyen los audios que Android no\n"
      "      // marca como música (notas de voz de WhatsApp, Telegram…).\n"
      "      final List<dynamic>? raw = await _channel.invokeMethod<List<dynamic>>(\n"
      "        'queryAudio',\n"
      "        <String, dynamic>{'includeNonMusic': includeNonMusic},\n"
      "      );",
      label="parámetro de escaneo")

patch("android/app/src/main/kotlin/com/botmp3/app/MainActivity.kt",
      r'        val selection = "\$\{MediaStore\.Audio\.Media\.IS_MUSIC\} != 0"',
      '        // Solo música por defecto. Si el usuario activa «importar audios de\n'
      '        // apps», se incluyen también las pistas que Android no marca como\n'
      '        // música (notas de voz de WhatsApp, Telegram…), pero no los sonidos\n'
      '        // cortos del sistema (menos de 15 s).\n'
      '        val incluirAudiosDeApps = call.argument<Boolean>("includeNonMusic") ?: false\n'
      '        val selection = if (incluirAudiosDeApps) {\n'
      '            "(${MediaStore.Audio.Media.IS_MUSIC} != 0 OR ${MediaStore.Audio.Media.DURATION} >= 15000)"\n'
      '        } else {\n'
      '            "${MediaStore.Audio.Media.IS_MUSIC} != 0"\n'
      '        }',
      label="selección nativa según el ajuste")

# ============================================================ 3. Proveedor
patch("lib/providers/library_provider.dart",
      r"      final List<ScannedTrack> tracks = await MediaScanner\.queryAudio\(\);",
      "      final bool incluirAudios =\n"
      "          SettingsService.actual?.importMediaAudio ?? false;\n"
      "      final List<ScannedTrack> tracks =\n"
      "          await MediaScanner.queryAudio(includeNonMusic: incluirAudios);",
      label="escaneo con el ajuste")

patch("lib/providers/library_provider.dart",
      r"  /// Resultado de aplicar la consulta y los filtros activos\.\n"
      r"  List<Song> get visibleSongs => _service\.search\(\n"
      r"        _query,\n"
      r"        genre: _genreFilter,\n"
      r"        artist: _artistFilter,\n"
      r"        yearFrom: _yearFrom,\n"
      r"        yearTo: _yearTo,\n"
      r"        tags: _tagFilters\.toList\(\),\n"
      r"        favoritesOnly: _favoritesOnly,\n"
      r"      \);",
      "  /// Resultado de aplicar la consulta y los filtros activos.\n"
      "  List<Song> get visibleSongs {\n"
      "    final List<Song> lista = _service.search(\n"
      "      _query,\n"
      "      genre: _genreFilter,\n"
      "      artist: _artistFilter,\n"
      "      yearFrom: _yearFrom,\n"
      "      yearTo: _yearTo,\n"
      "      tags: _tagFilters.toList(),\n"
      "      favoritesOnly: _favoritesOnly,\n"
      "    );\n"
      "    // Los audios de apps y las notas de voz solo se muestran si el usuario\n"
      "    // activa la opción (así también desaparecen los ya importados antes).\n"
      "    if (SettingsService.actual?.importMediaAudio ?? false) return lista;\n"
      "    return lista\n"
      "        .where((Song song) => !pareceAudioDeApp(song))\n"
      "        .toList(growable: false);\n"
      "  }",
      label="ocultar audios de apps")

provider = read("lib/providers/library_provider.dart")
if "text_utils.dart" not in provider:
    patch("lib/providers/library_provider.dart",
          r"import '\.\./services/library_service\.dart';",
          "import '../core/text_utils.dart';\n"
          "import '../services/library_service.dart';\n"
          "import '../services/settings_service.dart';",
          label="imports (proveedor)")

# ============================================================ 4. Orden y menú
patch("lib/screens/songs_screen.dart",
      r"  List<Song> _sorted\(List<Song> input\) \{\n"
      r"    final List<Song> songs = List<Song>\.from\(input\);\n"
      r"    switch \(_sort\) \{\n"
      r"      case _SortMode\.recientes:\n"
      r"        songs\.sort\(\(Song a, Song b\) => b\.addedAt\.compareTo\(a\.addedAt\)\);\n"
      r"      case _SortMode\.titulo:\n"
      r"        songs\.sort\(\(Song a, Song b\) => a\.title\.toLowerCase\(\)\.compareTo\(b\.title\.toLowerCase\(\)\)\);\n"
      r"      case _SortMode\.artista:\n"
      r"        songs\.sort\(\(Song a, Song b\) => a\.artist\.toLowerCase\(\)\.compareTo\(b\.artist\.toLowerCase\(\)\)\);\n"
      r"      case _SortMode\.album:\n"
      r"        songs\.sort\(\(Song a, Song b\) => a\.album\.toLowerCase\(\)\.compareTo\(b\.album\.toLowerCase\(\)\)\);\n"
      r"      case _SortMode\.anio:\n"
      r"        songs\.sort\(\(Song a, Song b\) => b\.year\.compareTo\(a\.year\)\);\n"
      r"      case _SortMode\.duracion:\n"
      r"        songs\.sort\(\(Song a, Song b\) => b\.durationMs\.compareTo\(a\.durationMs\)\);\n"
      r"      case _SortMode\.reproducciones:\n"
      r"        songs\.sort\(\(Song a, Song b\) => b\.playCount\.compareTo\(a\.playCount\)\);\n"
      r"    \}\n"
      r"    return songs;\n"
      r"  \}",
      "  List<Song> _sorted(List<Song> input) {\n"
      "    final List<Song> songs = List<Song>.from(input);\n"
      "    switch (_sort) {\n"
      "      case _SortMode.recientes:\n"
      "        songs.sort((Song a, Song b) {\n"
      "          final int porFecha = b.addedAt.compareTo(a.addedAt);\n"
      "          return porFecha != 0 ? porFecha : compararTextos(a.title, b.title);\n"
      "        });\n"
      "      case _SortMode.titulo:\n"
      "        songs.sort((Song a, Song b) => compararTextos(a.title, b.title));\n"
      "      case _SortMode.artista:\n"
      "        songs.sort((Song a, Song b) {\n"
      "          final int porArtista = compararTextos(a.artist, b.artist);\n"
      "          return porArtista != 0 ? porArtista : compararTextos(a.title, b.title);\n"
      "        });\n"
      "      case _SortMode.album:\n"
      "        songs.sort((Song a, Song b) {\n"
      "          final int porAlbum = compararTextos(a.album, b.album);\n"
      "          return porAlbum != 0 ? porAlbum : compararTextos(a.title, b.title);\n"
      "        });\n"
      "      case _SortMode.anio:\n"
      "        songs.sort((Song a, Song b) {\n"
      "          // Los años desconocidos (0) van al final, no al principio.\n"
      "          final int ya = a.year <= 0 ? -1 : a.year;\n"
      "          final int yb = b.year <= 0 ? -1 : b.year;\n"
      "          if (ya != yb) return yb.compareTo(ya);\n"
      "          return compararTextos(a.title, b.title);\n"
      "        });\n"
      "      case _SortMode.duracion:\n"
      "        songs.sort((Song a, Song b) => b.durationMs.compareTo(a.durationMs));\n"
      "      case _SortMode.reproducciones:\n"
      "        songs.sort((Song a, Song b) {\n"
      "          final int porReproducciones = b.playCount.compareTo(a.playCount);\n"
      "          return porReproducciones != 0\n"
      "              ? porReproducciones\n"
      "              : compararTextos(a.title, b.title);\n"
      "        });\n"
      "    }\n"
      "    return songs;\n"
      "  }",
      label="orden sin acentos y sin encabezar vacíos")

patch("lib/screens/songs_screen.dart",
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.recientes, child: Text\('Añadidas recientemente'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.titulo, child: Text\('Título \(A-Z\)'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.artista, child: Text\('Artista \(A-Z\)'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.album, child: Text\('Álbum \(A-Z\)'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.anio, child: Text\('Año \(nuevo primero\)'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.duracion, child: Text\('Duración'\)\),\n"
      r"                    const PopupMenuItem<_SortMode>\(value: _SortMode\.reproducciones, child: Text\('Más escuchadas'\)\),",
      "                    _ordenItem('Añadidas recientemente', _SortMode.recientes),\n"
      "                    _ordenItem('Título (A-Z)', _SortMode.titulo),\n"
      "                    _ordenItem('Artista (A-Z)', _SortMode.artista),\n"
      "                    _ordenItem('Álbum (A-Z)', _SortMode.album),\n"
      "                    _ordenItem('Año (nuevo primero)', _SortMode.anio),\n"
      "                    _ordenItem('Duración (larga primero)', _SortMode.duracion),\n"
      "                    _ordenItem('Más escuchadas', _SortMode.reproducciones),",
      label="menú con marca de opción activa")

patch("lib/screens/songs_screen.dart",
      r"  List<Song> _sorted\(List<Song> input\) \{",
      "  /// Opción del menú de orden, marcada si está activa.\n"
      "  PopupMenuItem<_SortMode> _ordenItem(String texto, _SortMode modo) {\n"
      "    final bool activo = _sort == modo;\n"
      "    return CheckedPopupMenuItem<_SortMode>(\n"
      "      value: modo,\n"
      "      checked: activo,\n"
      "      child: Text(\n"
      "        texto,\n"
      "        style: TextStyle(fontWeight: activo ? FontWeight.w700 : FontWeight.w400),\n"
      "      ),\n"
      "    );\n"
      "  }\n\n"
      "  List<Song> _sorted(List<Song> input) {",
      label="helper del menú")

songs = read("lib/screens/songs_screen.dart")
if "text_utils.dart" not in songs:
    patch("lib/screens/songs_screen.dart",
          r"import '\.\./models/song\.dart';",
          "import '../core/text_utils.dart';\n"
          "import '../models/song.dart';",
          label="import de utilidades (lista)")

# ============================================================ 5. Ajustes (UI)
patch("lib/screens/settings_screen.dart",
      r"          ListTile\(\n"
      r"            leading: library\.isScanning",
      "          SwitchListTile(\n"
      "            value: settings.importMediaAudio,\n"
      "            onChanged: (bool value) async {\n"
      "              await settings.setImportMediaAudio(value);\n"
      "              if (!context.mounted) return;\n"
      "              // Se vuelve a escanear para importar (o dejar de mostrar)\n"
      "              // estos audios sin reiniciar la app.\n"
      "              await library.autoScan(force: true);\n"
      "              if (!context.mounted) return;\n"
      "              ScaffoldMessenger.of(context).showSnackBar(\n"
      "                SnackBar(\n"
      "                  content: Text(\n"
      "                    value\n"
      "                        ? 'Se incluirán los audios de apps y notas de voz'\n"
      "                        : 'Solo se mostrará música',\n"
      "                  ),\n"
      "                ),\n"
      "              );\n"
      "            },\n"
      "            title: const Text('Importar audios de apps y notas de voz'),\n"
      "            subtitle: const Text(\n"
      "              'Incluye los audios de WhatsApp, Telegram… y las grabaciones de '\n"
      "              'voz. Desactivado (recomendado) solo se importa música.',\n"
      "            ),\n"
      "          ),\n"
      "          ListTile(\n"
      "            leading: library.isScanning",
      label="interruptor de audios de apps")

# ============================================================ 6. Reescaneo
patch("lib/screens/home_shell.dart",
      r"class _HomeShellState extends State<HomeShell> \{",
      "class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {",
      label="observador del ciclo de vida")

patch("lib/screens/home_shell.dart",
      r"  bool _autoImportStarted = false;\n\n"
      r"  @override\n"
      r"  void initState\(\) \{\n"
      r"    super\.initState\(\);\n"
      r"    // Importación automática de la música del dispositivo al abrir la app\.\n"
      r"    WidgetsBinding\.instance\.addPostFrameCallback\(\(_\) => _runAutoImport\(\)\);\n"
      r"  \}",
      "  bool _autoImportStarted = false;\n"
      "  DateTime _ultimoEscaneo = DateTime.fromMillisecondsSinceEpoch(0);\n\n"
      "  @override\n"
      "  void initState() {\n"
      "    super.initState();\n"
      "    // Importación automática al abrir la app y cada vez que vuelves a ella\n"
      "    // (así aparecen las canciones nuevas sin reiniciar).\n"
      "    WidgetsBinding.instance.addObserver(this);\n"
      "    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoImport());\n"
      "  }\n\n"
      "  @override\n"
      "  void dispose() {\n"
      "    WidgetsBinding.instance.removeObserver(this);\n"
      "    super.dispose();\n"
      "  }\n\n"
      "  @override\n"
      "  void didChangeAppLifecycleState(AppLifecycleState state) {\n"
      "    if (state == AppLifecycleState.resumed) {\n"
      "      _runAutoImport(silencioso: true);\n"
      "    }\n"
      "  }",
      label="reescaneo al volver a la app")

patch("lib/screens/home_shell.dart",
      r"  Future<void> _runAutoImport\(\) async \{\n"
      r"    if \(_autoImportStarted \|\| !mounted\) return;\n"
      r"    _autoImportStarted = true;\n"
      r"    final SettingsProvider settings = context\.read<SettingsProvider>\(\);\n"
      r"    if \(!settings\.autoImport\) return;\n"
      r"    await MediaImporter\.ensureAudioPermission\(\);\n"
      r"    // Android 13\+: sin este permiso no hay notificación ni controles\.\n"
      r"    await MediaImporter\.ensureNotificationPermission\(\);\n"
      r"    final LibraryProvider library = context\.read<LibraryProvider>\(\);",
      "  Future<void> _runAutoImport({bool silencioso = false}) async {\n"
      "    if (!mounted) return;\n"
      "    final SettingsProvider settings = context.read<SettingsProvider>();\n"
      "    if (!settings.autoImport) return;\n"
      "    if (silencioso) {\n"
      "      // Margen mínimo entre escaneos automáticos (evita repetirlos si\n"
      "      // vuelves a la app varias veces seguidas).\n"
      "      if (DateTime.now().difference(_ultimoEscaneo) <\n"
      "          const Duration(seconds: 20)) {\n"
      "        return;\n"
      "      }\n"
      "    } else if (_autoImportStarted) {\n"
      "      return;\n"
      "    }\n"
      "    _autoImportStarted = true;\n"
      "    _ultimoEscaneo = DateTime.now();\n"
      "    await MediaImporter.ensureAudioPermission();\n"
      "    // Android 13+: sin este permiso no hay notificación ni controles.\n"
      "    await MediaImporter.ensureNotificationPermission();\n"
      "    if (!mounted) return;\n"
      "    final LibraryProvider library = context.read<LibraryProvider>();",
      label="escaneo repetible")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
