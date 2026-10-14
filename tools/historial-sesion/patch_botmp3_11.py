"""BotMp3 v1.3.0 — aplica el sistema de cristal (Liquid Glass).

  1. Ajustes persistentes: activar/desactivar e intensidad del cristal.
  2. Barra inferior flotante de cristal + mini reproductor de cristal, sobre un
     fondo con la carátula del álbum difuminada (tinte adaptativo real).
  3. El cristal se apaga automáticamente con el ahorro de batería.
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


# ==================================================== 1. SettingsService
patch("lib/services/settings_service.dart",
      r"  /// Importa automáticamente la música del dispositivo al abrir la app\.",
      "  /// Efecto cristal (Liquid Glass) en barras y paneles.\n"
      "  bool get glassEnabled => _prefs.getBool('glass_enabled') ?? true;\n\n"
      "  Future<void> setGlassEnabled(bool value) async {\n"
      "    await _prefs.setBool('glass_enabled', value);\n"
      "  }\n\n"
      "  /// Intensidad del cristal (0.2 sutil · 1.0 máximo).\n"
      "  double get glassIntensity => _prefs.getDouble('glass_intensity') ?? 0.75;\n\n"
      "  Future<void> setGlassIntensity(double value) async {\n"
      "    await _prefs.setDouble('glass_intensity', value);\n"
      "  }\n\n"
      "  /// Importa automáticamente la música del dispositivo al abrir la app.",
      label="ajustes de cristal")

# ==================================================== 2. SettingsProvider
patch("lib/providers/settings_provider.dart",
      r"import '\.\./services/ai/ai_bridge\.dart';",
      "import '../services/ai/ai_bridge.dart';\nimport '../widgets/glass.dart';",
      label="import del cristal")

patch("lib/providers/settings_provider.dart",
      r"  bool get autoImport => _service\.autoImport;",
      "  bool get autoImport => _service.autoImport;\n"
      "  bool get glassEnabled => _service.glassEnabled;\n"
      "  double get glassIntensity => _service.glassIntensity;\n\n"
      "  /// El cristal se desactiva con el ahorro de batería.\n"
      "  bool get glassActive => _service.glassEnabled && !_service.batterySaver;\n\n"
      "  /// Calidad efectiva del cristal según los ajustes.\n"
      "  GlassQuality get glassQuality =>\n"
      "      glassQualityFor(enabled: glassActive, intensity: _service.glassIntensity);\n\n"
      "  Future<void> setGlassEnabled(bool value) async {\n"
      "    await _service.setGlassEnabled(value);\n"
      "    notifyListeners();\n"
      "  }\n\n"
      "  Future<void> setGlassIntensity(double value) async {\n"
      "    await _service.setGlassIntensity(value);\n"
      "    notifyListeners();\n"
      "  }",
      label="getters y setters de cristal")

# ==================================================== 3. glassQualityFor
patch("lib/widgets/glass.dart",
      r"/// Barra de navegación inferior flotante de cristal con indicador que se",
      "/// Traduce los ajustes del usuario a una calidad de cristal concreta.\n"
      "GlassQuality glassQualityFor({\n"
      "  required bool enabled,\n"
      "  required double intensity,\n"
      "  bool batterySaver = false,\n"
      "}) {\n"
      "  if (!enabled || batterySaver) return GlassQuality.off;\n"
      "  if (intensity < 0.4) return GlassQuality.light;\n"
      "  if (intensity < 0.85) return GlassQuality.standard;\n"
      "  return GlassQuality.high;\n"
      "}\n\n"
      "/// Barra de navegación inferior flotante de cristal con indicador que se",
      label="glassQualityFor")

# ==================================================== 4. HomeShell
patch("lib/screens/home_shell.dart",
      r"import 'package:flutter/material\.dart';\nimport 'package:provider/provider\.dart';",
      "import 'dart:io';\nimport 'dart:ui' as ui;\n\n"
      "import 'package:flutter/material.dart';\n"
      "import 'package:provider/provider.dart';",
      label="imports dart:io / dart:ui")

patch("lib/screens/home_shell.dart",
      r"import '\.\./widgets/mini_player\.dart';",
      "import '../core/theme.dart';\n"
      "import '../models/song.dart';\n"
      "import '../widgets/glass.dart';\n"
      "import '../widgets/mini_player.dart';",
      label="imports del cristal")

nuevo_bottom = """      bottomNavigationBar: GlassGroup(
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
                  onChanged: (int value) => setState(() => _index = value),
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
}"""

patch("lib/screens/home_shell.dart",
      r"      bottomNavigationBar: Column\(.*?\n        \],\n      \),\n    \);\n  \}\n\}",
      nuevo_bottom,
      flags=re.DOTALL,
      label="barra de cristal + fondo")

# ==================================================== 5. MiniPlayer transparente
patch("lib/widgets/mini_player.dart",
      r"      color: Theme\.of\(context\)\.colorScheme\.surfaceContainerHighest,",
      "      color: Colors.transparent,",
      label="mini reproductor sin fondo opaco")

# ==================================================== 6. Ajustes: sección cristal
patch("lib/screens/settings_screen.dart",
      r"          const _SectionTitle\('Biblioteca y respaldo'\),",
      "          const _SectionTitle('Apariencia'),\n"
      "          SwitchListTile(\n"
      "            value: settings.glassEnabled,\n"
      "            onChanged: (bool value) => settings.setGlassEnabled(value),\n"
      "            secondary: const Icon(Icons.blur_on),\n"
      "            title: const Text('Efecto cristal (Liquid Glass)'),\n"
      "            subtitle: const Text(\n"
      "              'Barras y paneles translúcidos con desenfoque real del fondo.',\n"
      "            ),\n"
      "          ),\n"
      "          ListTile(\n"
      "            leading: const Icon(Icons.opacity),\n"
      "            title: const Text('Intensidad del cristal'),\n"
      "            subtitle: Slider(\n"
      "              value: settings.glassIntensity,\n"
      "              min: 0.2,\n"
      "              max: 1.0,\n"
      "              divisions: 8,\n"
      "              label: '${(settings.glassIntensity * 100).round()}%',\n"
      "              onChanged: settings.glassEnabled\n"
      "                  ? (double value) => settings.setGlassIntensity(value)\n"
      "                  : null,\n"
      "            ),\n"
      "            onTap: null,\n"
      "          ),\n"
      "          const _SectionTitle('Biblioteca y respaldo'),",
      label="sección de cristal en Ajustes")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
