"""BotMp3 v1.4.0 (parte 2) — canal nativo de notificaciones y ajustes.

  · MainActivity: segundo MethodChannel para notificaciones.
  · AndroidManifest: receptores del recordatorio y del arranque.
  · main.dart: reprograma el aviso al abrir la app.
  · Ajustes: sección de tendencias (país, hora, aviso diario, ver ahora).
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


# ==================================================== 1. MainActivity (Kotlin)
MAIN = "android/app/src/main/kotlin/com/botmp3/app/MainActivity.kt"

patch(MAIN,
      r"import android\.content\.ContentUris",
      "import android.app.AlarmManager\nimport android.content.ContentUris",
      label="import AlarmManager")

canal_nativo = """                    else -> result.notImplemented()
                }
            }

        // -------- Notificaciones propias (tendencias musicales) --------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        val id = (call.argument<Number>("id") ?: 1001).toInt()
                        val title = call.argument<String>("title") ?: "BotMp3"
                        val body = call.argument<String>("body") ?: ""
                        val channelId =
                            call.argument<String>("channelId") ?: NotificationHelper.CHANNEL_ID
                        val channelName =
                            call.argument<String>("channelName") ?: NotificationHelper.CHANNEL_NAME
                        NotificationHelper.show(this, id, title, body, channelId, channelName)
                        result.success(true)
                    }

                    "scheduleDaily" -> {
                        val hour = (call.argument<Number>("hour") ?: 20).toInt()
                        val minute = (call.argument<Number>("minute") ?: 0).toInt()
                        val proxima = java.util.Calendar.getInstance().apply {
                            add(java.util.Calendar.DAY_OF_YEAR, 1)
                            set(java.util.Calendar.HOUR_OF_DAY, hour)
                            set(java.util.Calendar.MINUTE, minute)
                            set(java.util.Calendar.SECOND, 0)
                        }
                        TrendsReminderReceiver.programar(
                            this,
                            AlarmManager.INTERVAL_DAY,
                            proxima.timeInMillis,
                        )
                        result.success(true)
                    }

                    "cancelReminder" -> {
                        TrendsReminderReceiver.cancelar(this)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }"""

patch(MAIN,
      r"                    else -> result\.notImplemented\(\)\n                \}\n            \}\n    \}",
      canal_nativo,
      label="canal de notificaciones")

patch(MAIN,
      r"    private val channelName = \"botmp3/media\"",
      "    private val channelName = \"botmp3/media\"\n"
      "    private val notificationChannelName = \"botmp3/notifications\"",
      label="nombre del canal de notificaciones")

# ==================================================== 2. AndroidManifest
MANIFEST = "android/app/src/main/AndroidManifest.xml"

patch(MANIFEST,
      r"    <uses-permission android:name=\"android\.permission\.POST_NOTIFICATIONS\" />",
      "    <uses-permission android:name=\"android.permission.POST_NOTIFICATIONS\" />\n"
      "    <!-- Reprogramar el aviso diario de tendencias tras reiniciar -->\n"
      "    <uses-permission android:name=\"android.permission.RECEIVE_BOOT_COMPLETED\" />",
      label="permiso de arranque")

patch(MANIFEST,
      r"        <!-- Flutter necesita esta marca para el arranque -->",
      "        <!-- ============ Avisos diarios de tendencias ============ -->\n"
      "        <receiver\n"
      "            android:name=\".TrendsReminderReceiver\"\n"
      "            android:exported=\"false\" />\n\n"
      "        <receiver\n"
      "            android:name=\".BootReceiver\"\n"
      "            android:exported=\"true\">\n"
      "            <intent-filter>\n"
      "                <action android:name=\"android.intent.action.BOOT_COMPLETED\" />\n"
      "            </intent-filter>\n"
      "        </receiver>\n\n"
      "        <!-- Flutter necesita esta marca para el arranque -->",
      label="receptores de tendencias")

# ==================================================== 3. main.dart
patch("lib/main.dart",
      r"import 'app\.dart';",
      "import 'app.dart';\nimport 'services/notification_service.dart';",
      label="import de notificaciones")

patch("lib/main.dart",
      r"  final SettingsService settings = await SettingsService\.instance\(\);\n  runApp\(",
      "  final SettingsService settings = await SettingsService.instance();\n\n"
      "  // Si el usuario pidió avisos de tendencias, se reprograman al abrir la app\n"
      "  // (Android borra las alarmas si apaga el móvil; el sistema las conserva si no).\n"
      "  if (settings.trendsNotify) {\n"
      "    await NotificationService.instance.programarDiario(\n"
      "      hour: settings.trendsHour,\n"
      "      minute: 0,\n"
      "    );\n"
      "  }\n\n"
      "  runApp(",
      label="reprogramar aviso al arrancar")

# ==================================================== 4. Ajustes: tendencias
seccion = """          const _SectionTitle('Tendencias musicales'),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('País de las listas'),
            subtitle: Text(
              TrendsService.paises[settings.trendsCountry] ??
                  settings.trendsCountry.toUpperCase(),
            ),
            onTap: () async {
              final String? elegido = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (BuildContext sheetContext) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: TrendsService.paises.entries
                        .map(
                          (MapEntry<String, String> entry) => ListTile(
                            title: Text(entry.value),
                            trailing: entry.key == settings.trendsCountry
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.of(sheetContext).pop(entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
              if (elegido != null) await settings.setTrendsCountry(elegido);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Hora del aviso diario'),
            subtitle: Text('${settings.trendsHour.toString().padLeft(2, '0')}:00'),
            onTap: () async {
              final TimeOfDay? hora = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: settings.trendsHour, minute: 0),
              );
              if (hora == null) return;
              await settings.setTrendsHour(hora.hour);
              if (settings.trendsNotify) {
                await NotificationService.instance
                    .programarDiario(hour: hora.hour, minute: 0);
              }
            },
          ),
          SwitchListTile(
            value: settings.trendsNotify,
            onChanged: (bool value) async {
              await settings.setTrendsNotify(value);
              if (value) {
                await NotificationService.instance
                    .programarDiario(hour: settings.trendsHour, minute: 0);
              } else {
                await NotificationService.instance.cancelarRecordatorio();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Te avisaré cada día a las ${settings.trendsHour}:00'
                        : 'Avisos de tendencias desactivados',
                  ),
                ),
              );
            },
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Avisarme de las tendencias'),
            subtitle: const Text(
              'Una notificación al día con lo más escuchado en internet.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Ver tendencias ahora'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard_outlined),
            title: const Text('Ver mi ranking'),
            subtitle: const Text('Tus canciones, artistas y géneros más escuchados.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RankingScreen()),
            ),
          ),
          const _SectionTitle('Apariencia'),"""

patch("lib/screens/settings_screen.dart",
      r"          const _SectionTitle\('Apariencia'\),",
      seccion,
      label="sección de tendencias y ranking")

settings_text = read("lib/screens/settings_screen.dart")
imports = ""
if "trends_service.dart" not in settings_text:
    imports += "import '../services/notification_service.dart';\nimport '../services/trends_service.dart';\n"
if "trends_screen.dart" not in settings_text:
    imports += "import 'ranking_screen.dart';\nimport 'trends_screen.dart';\n"
if imports:
    patch("lib/screens/settings_screen.dart",
          r"(import '\.\./services/settings_service\.dart';\n)",
          r"\1" + imports,
          label="imports de tendencias/ranking")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
