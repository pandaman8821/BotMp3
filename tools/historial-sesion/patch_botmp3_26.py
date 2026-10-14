"""BotMp3 v1.4.3 — «Acerca de» con la versión real y sus novedades.

La versión estaba escrita a mano («Versión 1.0.0») y nunca cambiaba. Ahora se lee
del APK instalado (canal nativo `botmp3/appinfo`) y se muestran las novedades de
esa compilación concreta.
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
        return handle.text() if False else handle.read()


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


# ============================================== 1. Kotlin: canal con la versión
MAIN = "android/app/src/main/kotlin/com/botmp3/app/MainActivity.kt"

patch(MAIN,
      r"    private val notificationChannelName = \"botmp3/notifications\"",
      "    private val notificationChannelName = \"botmp3/notifications\"\n"
      "    private val appInfoChannelName = \"botmp3/appinfo\"",
      label="nombre del canal de información")

patch(MAIN,
      r"                    else -> result\.notImplemented\(\)\n                \}\n            \}\n    \}",
      "                    else -> result.notImplemented()\n"
      "                }\n"
      "            }\n\n"
      "        // -------- Versión real del APK instalado --------\n"
      "        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appInfoChannelName)\n"
      "            .setMethodCallHandler { call, result ->\n"
      "                when (call.method) {\n"
      "                    \"version\" -> {\n"
      "                        val info = packageManager.getPackageInfo(packageName, 0)\n"
      "                        @Suppress(\"DEPRECATION\")\n"
      "                        val codigo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {\n"
      "                            info.longVersionCode\n"
      "                        } else {\n"
      "                            info.versionCode.toLong()\n"
      "                        }\n"
      "                        result.success(\n"
      "                            mapOf(\n"
      "                                \"name\" to (info.versionName ?: \"\"),\n"
      "                                \"code\" to codigo,\n"
      "                            ),\n"
      "                        )\n"
      "                    }\n\n"
      "                    else -> result.notImplemented()\n"
      "                }\n"
      "            }\n"
      "    }",
      label="canal con la versión del APK")

# ============================================== 2. Novedades por versión
patch("lib/core/constants.dart",
      r"/// Claves de almacenamiento local\.",
      "/// Novedades de cada compilación (se muestran en «Acerca de»).\n"
      "class AppChangelog {\n"
      "  const AppChangelog._();\n\n"
      "  static const Map<int, String> novedades = <int, String>{\n"
      "    14: 'Ranking más claro, versión real en «Acerca de» y detalles pulidos.',\n"
      "    13: 'Controles del bloqueo corregidos y pantalla de Diagnóstico de reproducción.',\n"
      "    12: 'Pestaña IA arreglada (Tendencias como chip en las acciones).',\n"
      "    11: 'Ranking de lo más escuchado y tendencias con aviso diario.',\n"
      "    10: 'Siguiente y anterior en la pantalla de bloqueo.',\n"
      "    9: 'Modelos de IA al día (deepseek-flash / deepseek-v4-pro).',\n"
      "    8: 'Notificación de reproducción con controles en el bloqueo.',\n"
      "    7: 'Transición visible en todas las pestañas.',\n"
      "    6: 'Tocar una canción la reproduce al instante.',\n"
      "    5: 'Efecto cristal (Liquid Glass) en barras y paneles.',\n"
      "    4: 'Icono nuevo y gestión de espacio en caché.',\n"
      "  };\n\n"
      "  static String? forCode(int code) => novedades[code];\n"
      "}\n\n"
      "/// Claves de almacenamiento local.",
      label="novedades por versión")

# ============================================== 3. «Acerca de» con datos reales
patch("lib/screens/settings_screen.dart",
      r"          const _SectionTitle\('Acerca de BotMp3'\),\n"
      r"          const ListTile\(\n"
      r"            leading: Icon\(Icons\.info_outline\),\n"
      r"            title: Text\('Versión 1\.0\.0'\),\n"
      r"            subtitle: Text\(\n"
      r"              'Reproductor local con IA multimodelo \(OpenAI, DeepSeek, Gemini, Claude\)\.\\n'\n"
      r"              'Modo offline total: la música nunca sale del dispositivo\.',\n"
      r"            \),\n"
      r"          \),",
      "          const _SectionTitle('Acerca de BotMp3'),\n"
      "          FutureBuilder<String>(\n"
      "            future: AppInfoService.etiquetaVersion(),\n"
      "            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {\n"
      "              final String version = snapshot.data ?? 'Comprobando…';\n"
      "              final int? codigo = AppInfoService.codigoCache;\n"
      "              final String? novedades =\n"
      "                  codigo == null ? null : AppChangelog.forCode(codigo);\n"
      "              return ListTile(\n"
      "                leading: const Icon(Icons.info_outline),\n"
      "                title: Text(version),\n"
      "                subtitle: Text(\n"
      "                  'Reproductor local con IA multimodelo (OpenAI, DeepSeek, Gemini, '\n"
      "                  'Claude), efecto cristal, ranking propio y tendencias.\\n'\n"
      "                  'Modo offline total: la música nunca sale del dispositivo.'\n"
      "                  '${novedades == null ? '' : '\\n\\nNovedades: $novedades'}',\n"
      "                ),\n"
      "                isThreeLine: true,\n"
      "              );\n"
      "            },\n"
      "          ),",
      label="«Acerca de» con la versión real")

settings_text = read("lib/screens/settings_screen.dart")
if "app_info_service.dart" not in settings_text:
    patch("lib/screens/settings_screen.dart",
          r"import '\.\./services/secure_keys_service\.dart';",
          "import '../services/app_info_service.dart';\n"
          "import '../services/secure_keys_service.dart';",
          label="import del servicio de versión")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
