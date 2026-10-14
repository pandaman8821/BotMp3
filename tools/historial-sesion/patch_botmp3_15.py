"""BotMp3 v1.3.3 — controles de reproducción en la pantalla de bloqueo.

Causas corregidas:
  1. `main.dart` no indicaba `androidNotificationIcon`, así que se usaba el
     icono ADAPTATIVO (`mipmap/ic_launcher`, un XML `<adaptive-icon>`). Android
     lo rechaza como icono de notificación: la notificación no se crea y con
     ella desaparecen los controles (bloqueo, auriculares, reloj…).
     Ahora se usa un icono monocromo propio (`drawable/ic_stat_botmp3`).
  2. El permiso POST_NOTIFICATIONS (Android 13+) no se pedía nunca: sin él la
     notificación no se muestra. Se solicita junto al permiso de audio.
  3. La sesión de audio no se configuraba como música (foco y controles).
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


# =============================================== 1. main.dart: icono + sesión
patch("lib/main.dart",
      r"import 'package:flutter/material\.dart';\nimport 'package:just_audio_background/just_audio_background\.dart';",
      "import 'package:audio_session/audio_session.dart';\n"
      "import 'package:flutter/material.dart';\n"
      "import 'package:just_audio_background/just_audio_background.dart';",
      label="import de audio_session")

patch("lib/main.dart",
      r"  await JustAudioBackground\.init\(\n"
      r"    androidNotificationChannelId: 'com\.botmp3\.app\.channel\.audio',\n"
      r"    androidNotificationChannelName: 'Reproducción BotMp3',\n"
      r"    androidNotificationOngoing: true,\n"
      r"    androidStopForegroundOnPause: true,\n"
      r"  \);",
      "  await JustAudioBackground.init(\n"
      "    androidNotificationChannelId: 'com.botmp3.app.channel.audio',\n"
      "    androidNotificationChannelName: 'Reproducción BotMp3',\n"
      "    androidNotificationOngoing: true,\n"
      "    androidStopForegroundOnPause: true,\n"
      "    // Icono MONOCROMO obligatorio: con el icono adaptativo Android no crea\n"
      "    // la notificación y se pierden los controles de la pantalla de bloqueo.\n"
      "    androidNotificationIcon: 'drawable/ic_stat_botmp3',\n"
      "  );\n\n"
      "  // Sesión de audio como reproductor de música: foco correcto y controles\n"
      "  // del sistema (bloqueo, auriculares, reloj, Android Auto…).\n"
      "  final AudioSession session = await AudioSession.instance;\n"
      "  await session.configure(const AudioSessionConfiguration.music());",
      label="icono de notificación + sesión de música")

# =============================================== 2. Permiso de notificaciones
patch("lib/services/media_importer.dart",
      r"  static Future<bool> ensureAudioPermission\(\) async \{",
      "  /// Pide el permiso de notificaciones (Android 13+). Sin él, la notificación\n"
      "  /// de reproducción no se muestra y el móvil bloqueado no ofrece controles.\n"
      "  static Future<void> ensureNotificationPermission() async {\n"
      "    try {\n"
      "      final PermissionStatus estado = await Permission.notification.status;\n"
      "      if (!estado.isGranted) {\n"
      "        await Permission.notification.request();\n"
      "      }\n"
      "    } catch (error) {\n"
      "      debugPrint('No se pudo pedir el permiso de notificaciones: $error');\n"
      "    }\n"
      "  }\n\n"
      "  static Future<bool> ensureAudioPermission() async {",
      label="método de permiso de notificaciones")

# =============================================== 3. Pedirlo en el arranque
patch("lib/screens/home_shell.dart",
      r"    await MediaImporter\.ensureAudioPermission\(\);",
      "    await MediaImporter.ensureAudioPermission();\n"
      "    // Android 13+: sin este permiso no hay notificación ni controles.\n"
      "    await MediaImporter.ensureNotificationPermission();",
      label="pedir permiso de notificaciones al arrancar")

# =============================================== 4. Aviso en Ajustes (HyperOS)
patch("lib/screens/settings_screen.dart",
      r"          const _SectionTitle\('Apariencia'\),",
      "          const _SectionTitle('Apariencia'),\n"
      "          const ListTile(\n"
      "            leading: Icon(Icons.notifications_active_outlined),\n"
      "            title: Text('Controles en la pantalla de bloqueo'),\n"
      "            subtitle: Text(\n"
      "              'Si la música se para al bloquear el móvil o no aparecen los '\n"
      "              'controles, concede a BotMp3 el permiso de notificaciones y, en '\n"
      "              'HyperOS/MIUI, activa «Inicio automático» y pon la batería en '\n"
      "              '«Sin restricciones».',\n"
      "            ),\n"
      "          ),",
      label="aviso de controles en Ajustes")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
