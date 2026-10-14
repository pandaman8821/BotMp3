"""BotMp3 v1.4.0 (parte 1) — ranking de más escuchadas y tendencias (Dart).

  1. Historial de reproducciones (fichero aparte) → rankings por periodo.
  2. Top de canciones, artistas, álbumes y géneros.
  3. Ajustes: país de las listas, aviso diario y hora.
  4. Accesos a Ranking (barra de Canciones) y Tendencias (pantalla de IA y Ajustes).
  5. Recordatorio programado al arrancar.
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


# ================================================== 1. Claves de almacenamiento
patch("lib/core/constants.dart",
      r"  static const String importedDir = 'imported';",
      "  static const String trendsFile = 'botmp3_trends_v1.json';\n"
      "  static const String playLogFile = 'botmp3_playlog_v1.json';\n"
      "  static const String importedDir = 'imported';",
      label="claves de tendencias e historial")

# ================================================== 2. Historial + rankings
nuevo_register = """  /// Historial de reproducciones (para el ranking por periodo).
  final List<Map<String, dynamic>> _playLog = <Map<String, dynamic>>[];
  bool _historialCargado = false;

  /// Registra una reproducción (para estadísticas, ranking y recomendaciones).
  Future<void> registerPlay(String id) async {
    final Song? song = songById(id);
    if (song == null) return;
    final int index = _songs.indexWhere((Song s) => s.id == id);
    if (index < 0) return;
    final DateTime ahora = DateTime.now();
    _songs[index] = song.copyWith(
      playCount: song.playCount + 1,
      lastPlayedAt: ahora,
    );
    _playLog.add(<String, dynamic>{'id': id, 'at': ahora.toIso8601String()});
    // Se conservan las últimas 3000 reproducciones: suficiente para el ranking.
    if (_playLog.length > 3000) {
      _playLog.removeRange(0, _playLog.length - 3000);
    }
    await _persist();
    unawaited(_persistirHistorial());
  }

  Future<void> _persistirHistorial() async {
    try {
      await StorageService.instance.writeJson(StorageKeys.playLogFile, _playLog);
    } catch (error) {
      debugPrint('No se pudo guardar el historial de reproducciones: $error');
    }
  }

  /// Carga el historial desde disco (lo llama el proveedor al iniciar).
  Future<void> cargarHistorial() async {
    if (_historialCargado) return;
    _historialCargado = true;
    try {
      final List<dynamic>? datos =
          await StorageService.instance.readJsonList(StorageKeys.playLogFile);
      if (datos == null) return;
      _playLog
        ..clear()
        ..addAll(datos.whereType<Map<String, dynamic>>());
    } catch (error) {
      debugPrint('No se pudo leer el historial de reproducciones: $error');
    }
  }

  /// Reproducciones por canción desde una fecha (null = todo el historial).
  /// Si aún no hay historial, se usa el contador acumulado de cada canción.
  Map<String, int> playsSince(DateTime? from) {
    final Map<String, int> conteo = <String, int>{};
    if (_playLog.isEmpty) {
      if (from != null) return conteo;
      for (final Song song in _songs) {
        if (song.playCount > 0) conteo[song.id] = song.playCount;
      }
      return conteo;
    }
    for (final Map<String, dynamic> entrada in _playLog) {
      final String? id = entrada['id']?.toString();
      if (id == null) continue;
      if (from != null) {
        final DateTime? at = DateTime.tryParse(entrada['at']?.toString() ?? '');
        if (at == null || at.isBefore(from)) continue;
      }
      conteo[id] = (conteo[id] ?? 0) + 1;
    }
    return conteo;
  }

  /// Canciones ordenadas por número de reproducciones.
  List<Song> topCanciones({DateTime? from, int limit = 100}) {
    final Map<String, int> conteo = playsSince(from);
    final List<Song> ordenadas = _songs.toList()
      ..sort((Song a, Song b) {
        final int ca = conteo[a.id] ?? 0;
        final int cb = conteo[b.id] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return (b.lastPlayedAt ?? DateTime(0)).compareTo(a.lastPlayedAt ?? DateTime(0));
      });
    return ordenadas
        .where((Song song) => (conteo[song.id] ?? 0) > 0 || song.playCount > 0)
        .take(limit)
        .toList();
  }

  /// Agrupa las reproducciones por un campo de texto (artista, álbum, género).
  List<MapEntry<String, int>> _topPor(
    String Function(Song song) clave, {
    DateTime? from,
  }) {
    final bool hayHistorial = _playLog.isNotEmpty;
    final Map<String, int> conteo = playsSince(from);
    final Map<String, int> total = <String, int>{};
    for (final Song song in _songs) {
      final String k = clave(song).trim();
      if (k.isEmpty || k == 'Artista desconocido') continue;
      final int reproducciones =
          hayHistorial ? (conteo[song.id] ?? 0) : song.playCount;
      if (reproducciones <= 0) continue;
      total[k] = (total[k] ?? 0) + reproducciones;
    }
    final List<MapEntry<String, int>> lista = total.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );
    return lista.take(50).toList();
  }

  List<MapEntry<String, int>> topArtistas({DateTime? from}) =>
      _topPor((Song song) => song.artist, from: from);

  List<MapEntry<String, int>> topAlbumes({DateTime? from}) =>
      _topPor((Song song) => song.album, from: from);

  List<MapEntry<String, int>> topGeneros({DateTime? from}) =>
      _topPor((Song song) => song.genre, from: from);"""

patch("lib/services/library_service.dart",
      r"  /// Registra una reproducción \(para estadísticas y recomendaciones de la IA\)\.\n"
      r"  Future<void> registerPlay\(String id\) async \{.*?\n  \}",
      nuevo_register,
      flags=re.DOTALL,
      label="historial + rankings")

# Importes necesarios en library_service
servicio_text = read("lib/services/library_service.dart")
if "dart:async" not in servicio_text:
    patch("lib/services/library_service.dart",
          r"import 'dart:convert';",
          "import 'dart:async';\nimport 'dart:convert';",
          label="import dart:async")
if "storage_service.dart" not in servicio_text:
    patch("lib/services/library_service.dart",
          r"(import '\.\./core/constants\.dart';)",
          r"\1\nimport 'storage_service.dart';",
          label="import StorageService")

# ================================================== 3. Cargar historial al iniciar
patch("lib/providers/library_provider.dart",
      r"  Future<void> _load\(\) async \{\n    await _service\.load\(\);",
      "  Future<void> _load() async {\n"
      "    await _service.load();\n"
      "    // Historial de reproducciones para el ranking por periodo.\n"
      "    await _service.cargarHistorial();",
      label="cargar historial al iniciar")

# ================================================== 4. Ajustes de tendencias
patch("lib/services/settings_service.dart",
      r"  /// Efecto cristal \(Liquid Glass\) en barras y paneles\.",
      "  /// País de las listas de tendencias (código de tienda: es, mx, us…).\n"
      "  String get trendsCountry => _prefs.getString('trends_country') ?? 'es';\n\n"
      "  Future<void> setTrendsCountry(String value) async {\n"
      "    await _prefs.setString('trends_country', value);\n"
      "  }\n\n"
      "  /// Aviso diario con las canciones en tendencia.\n"
      "  bool get trendsNotify => _prefs.getBool('trends_notify') ?? false;\n\n"
      "  Future<void> setTrendsNotify(bool value) async {\n"
      "    await _prefs.setBool('trends_notify', value);\n"
      "  }\n\n"
      "  /// Hora del aviso diario (0-23).\n"
      "  int get trendsHour => _prefs.getInt('trends_hour') ?? 20;\n\n"
      "  Future<void> setTrendsHour(int value) async {\n"
      "    await _prefs.setInt('trends_hour', value);\n"
      "  }\n\n"
      "  /// Efecto cristal (Liquid Glass) en barras y paneles.",
      label="ajustes de tendencias")

patch("lib/providers/settings_provider.dart",
      r"  bool get glassEnabled => _service\.glassEnabled;",
      "  bool get glassEnabled => _service.glassEnabled;\n"
      "  String get trendsCountry => _service.trendsCountry;\n"
      "  bool get trendsNotify => _service.trendsNotify;\n"
      "  int get trendsHour => _service.trendsHour;\n\n"
      "  Future<void> setTrendsCountry(String value) async {\n"
      "    await _service.setTrendsCountry(value);\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  Future<void> setTrendsNotify(bool value) async {\n"
      "    await _service.setTrendsNotify(value);\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  Future<void> setTrendsHour(int value) async {\n"
      "    await _service.setTrendsHour(value);\n"
      "    notifyListeners();\n"
      "  }",
      label="accesos de tendencias en el proveedor")

# ================================================== 5. Ranking desde Canciones
patch("lib/screens/songs_screen.dart",
      r"                IconButton\(\n                  tooltip: 'Filtros avanzados',",
      "                IconButton(\n"
      "                  tooltip: 'Ranking de lo más escuchado',\n"
      "                  icon: const Icon(Icons.leaderboard_outlined),\n"
      "                  onPressed: () => Navigator.of(context).push(\n"
      "                    MaterialPageRoute<void>(builder: (_) => const RankingScreen()),\n"
      "                  ),\n"
      "                ),\n"
      "                IconButton(\n                  tooltip: 'Filtros avanzados',",
      label="botón de ranking")

if "ranking_screen.dart" not in read("lib/screens/songs_screen.dart"):
    patch("lib/screens/songs_screen.dart",
          r"(import '\.\./providers/player_provider\.dart';)",
          r"\1\nimport 'ranking_screen.dart';",
          label="import RankingScreen")

# ================================================== 6. Tendencias desde la IA
patch("lib/screens/ai_screen.dart",
      r"          _executedActions\(ai\),",
      "          _trendsCard(context),\n          _executedActions(ai),",
      label="tarjeta de tendencias")

patch("lib/screens/ai_screen.dart",
      r"  /// Chips con las últimas órdenes que la IA ejecutó sobre la app\.",
      "  /// Acceso a las tendencias de internet (con opción de avisos).\n"
      "  Widget _trendsCard(BuildContext context) {\n"
      "    return GlassCard(\n"
      "      margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),\n"
      "      padding: const EdgeInsets.all(12),\n"
      "      child: Row(\n"
      "        children: <Widget>[\n"
      "          const Icon(Icons.local_fire_department, color: AppColors.warning),\n"
      "          const SizedBox(width: 10),\n"
      "          const Expanded(\n"
      "            child: Column(\n"
      "              crossAxisAlignment: CrossAxisAlignment.start,\n"
      "              children: <Widget>[\n"
      "                Text(\n"
      "                  'Tendencias en internet',\n"
      "                  style: TextStyle(fontWeight: FontWeight.w700),\n"
      "                ),\n"
      "                SizedBox(height: 2),\n"
      "                Text(\n"
      "                  'Mira qué suena ahora y recibe avisos',\n"
      "                  style: TextStyle(fontSize: 12),\n"
      "                ),\n"
      "              ],\n"
      "            ),\n"
      "          ),\n"
      "          FilledButton.tonal(\n"
      "            onPressed: () => Navigator.of(context).push(\n"
      "              MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),\n"
      "            ),\n"
      "            child: const Text('Ver'),\n"
      "          ),\n"
      "        ],\n"
      "      ),\n"
      "    );\n"
      "  }\n\n"
      "  /// Chips con las últimas órdenes que la IA ejecutó sobre la app.",
      label="método de la tarjeta de tendencias")

ai_text = read("lib/screens/ai_screen.dart")
if "trends_screen.dart" not in ai_text:
    patch("lib/screens/ai_screen.dart",
          r"(import '\.\./providers/ai_provider\.dart';)",
          r"\1\nimport '../core/theme.dart';\nimport '../widgets/glass.dart';\nimport 'trends_screen.dart';",
          label="imports de tendencias en la IA")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
