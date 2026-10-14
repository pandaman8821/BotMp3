"""BotMp3 v1.4.2 (parte 2) — comprobaciones nativas para el diagnóstico."""

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


# ================================================ 1. Dart: consultas de estado
patch("lib/services/notification_service.dart",
      r"  /// Programa un recordatorio diario a la hora indicada\.",
      "  /// ¿Están permitidas las notificaciones? (Android 13+ pueden denegarse).\n"
      "  Future<bool> estanActivas() async {\n"
      "    try {\n"
      "      return await _channel.invokeMethod<bool>('notificationsEnabled') ?? true;\n"
      "    } catch (_) {\n"
      "      return true;\n"
      "    }\n"
      "  }\n\n"
      "  /// ¿La app está excluida de la optimización de batería?\n"
      "  Future<bool> sinRestriccionesDeBateria() async {\n"
      "    try {\n"
      "      return await _channel.invokeMethod<bool>('ignoringBatteryOptimizations') ?? false;\n"
      "    } catch (_) {\n"
      "      return false;\n"
      "    }\n"
      "  }\n\n"
      "  /// Programa un recordatorio diario a la hora indicada.",
      label="consultas de estado de notificaciones")

# ================================================ 2. Kotlin: métodos nativos
MAIN = "android/app/src/main/kotlin/com/botmp3/app/MainActivity.kt"

patch(MAIN,
      r"import android\.app\.AlarmManager",
      "import android.app.AlarmManager\nimport android.os.Build\nimport android.os.PowerManager",
      label="imports de Build y PowerManager")

patch(MAIN,
      r"                    \"cancelReminder\" -> \{",
      "                    \"notificationsEnabled\" -> {\n"
      "                        val manager =\n"
      "                            getSystemService(android.app.NotificationManager::class.java)\n"
      "                        result.success(manager?.areNotificationsEnabled() ?: true)\n"
      "                    }\n\n"
      "                    \"ignoringBatteryOptimizations\" -> {\n"
      "                        val power = getSystemService(PowerManager::class.java)\n"
      "                        val libre = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {\n"
      "                            power?.isIgnoringBatteryOptimizations(packageName) ?: false\n"
      "                        } else {\n"
      "                            true\n"
      "                        }\n"
      "                        result.success(libre)\n"
      "                    }\n\n"
      "                    \"cancelReminder\" -> {",
      label="métodos de permisos y batería")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
