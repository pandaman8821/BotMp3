"""Conecta el motor de acciones con el proveedor de IA y la interfaz.

  1. AiAssistantProvider: parsea/ejecuta órdenes, barra de comandos y autocompletado.
  2. HomeShell: dispara la importación automática al abrir la app.
  3. Ajustes: interruptor de importación automática + "escanear ahora".
  4. Pantalla de IA: muestra las órdenes ejecutadas.
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


def patch(rel: str, pattern: str, replacement: str, *, count: int = 1,
          flags: int = 0, label: str = "") -> None:
    text = read(rel)
    new, n = re.subn(pattern, replacement, text, count=count, flags=flags)
    if n:
        write(rel, new)
        ok.append(f"{rel}: {label or pattern[:40]}")
    else:
        fail.append(f"{rel}: NO ENCONTRADO -> {label or pattern[:70]}")


# ============================================================ 1. AiAssistantProvider
patch("lib/providers/ai_provider.dart",
      r"import '\.\./services/ai/ai_orchestrator\.dart';",
      "import '../services/ai/action_executor.dart';\n"
      "import '../services/ai/ai_actions.dart';\n"
      "import '../services/ai/ai_bridge.dart';\n"
      "import '../services/ai/ai_orchestrator.dart';",
      label="imports del motor de acciones")

patch("lib/providers/ai_provider.dart",
      r"import 'library_provider\.dart';",
      "import 'library_provider.dart';\nimport 'player_provider.dart';\nimport 'settings_provider.dart';",
      label="imports de proveedores")

patch("lib/providers/ai_provider.dart",
      r"  String _status = 'Listo';",
      "  String _status = 'Listo';\n\n"
      "  /// Últimas órdenes ejecutadas (se muestran en la pantalla de IA).\n"
      "  List<ActionOutcome> _lastOutcomes = <ActionOutcome>[];\n"
      "  bool _executing = false;",
      label="estado de órdenes")

patch("lib/providers/ai_provider.dart",
      r"  String get status => _status;",
      "  String get status => _status;\n"
      "  List<ActionOutcome> get lastOutcomes => List<ActionOutcome>.unmodifiable(_lastOutcomes);\n"
      "  bool get executing => _executing;",
      label="getters de órdenes")

patch("lib/providers/ai_provider.dart",
      r"      _lastError = null;\n    \} catch \(error\) \{\n      final String message =",
      "      _lastError = null;\n"
      "      await _executeFromReply(reply, clean);\n"
      "    } catch (error) {\n      final String message =",
      label="ejecutar órdenes tras responder")

patch("lib/providers/ai_provider.dart",
      r"  /// Recomendaciones personalizadas según género, artista, mood o lista actual\.",
      "  // ------------------------------------------------------- motor de acciones\n\n"
      "  /// Ejecuta las órdenes que la IA incluyó en su respuesta y, si no hay\n"
      "  /// ninguna, interpreta el mensaje del usuario con las reglas locales.\n"
      "  Future<void> _executeFromReply(String reply, String userText) async {\n"
      "    final (String _, List<AiAction> fromAi) = AiActionParser.fromAiReply(reply);\n"
      "    final List<AiAction> actions = fromAi.isNotEmpty\n"
      "        ? fromAi\n"
      "        : AiActionParser.fromNaturalLanguage(userText);\n"
      "    if (actions.isEmpty) return;\n"
      "    await _runActions(actions);\n"
      "  }\n\n"
      "  /// Ejecuta una orden escrita en la barra de comandos (\"hazlo ya\").\n"
      "  Future<List<ActionOutcome>> runCommand(String text) async {\n"
      "    List<AiAction> actions = AiActionParser.fromNaturalLanguage(text);\n"
      "    if (actions.isEmpty) {\n"
      "      final AiOrchestrator? orchestrator = buildOrchestrator();\n"
      "      if (orchestrator != null) {\n"
      "        try {\n"
      "          final String reply = await orchestrator.chat(<AiMessage>[\n"
      "            AiMessage(\n"
      "              role: 'user',\n"
      "              content: 'Ordena la ejecución de: $text',\n"
      "              createdAt: DateTime.now(),\n"
      "            ),\n"
      "          ]);\n"
      "          final (String _, List<AiAction> fromAi) = AiActionParser.fromAiReply(reply);\n"
      "          actions = fromAi;\n"
      "        } catch (error) {\n"
      "          _lastError = error is AiRequestException ? error.message : error.toString();\n"
      "        }\n"
      "      }\n"
      "    }\n"
      "    if (actions.isEmpty) {\n"
      "      _lastOutcomes = <ActionOutcome>[\n"
      "        const ActionOutcome(\n"
      "          AiAction(AiActionType.help),\n"
      "          'No entendí la orden. Escribe «ayuda» para ver ejemplos.',\n"
      "          ok: false,\n"
      "        ),\n"
      "      ];\n"
      "      notifyListeners();\n"
      "      return _lastOutcomes;\n"
      "    }\n"
      "    return _runActions(actions);\n"
      "  }\n\n"
      "  Future<List<ActionOutcome>> _runActions(List<AiAction> actions) async {\n"
      "    final PlayerProvider? player = AiBridge.player;\n"
      "    final SettingsProvider? settings = AiBridge.settings;\n"
      "    if (player == null || settings == null) return <ActionOutcome>[];\n\n"
      "    _executing = true;\n"
      "    notifyListeners();\n"
      "    final ActionExecutor executor = ActionExecutor(\n"
      "      library: _library,\n"
      "      player: player,\n"
      "      settings: settings,\n"
      "    );\n"
      "    try {\n"
      "      final List<ActionOutcome> outcomes = await executor.runAll(actions);\n"
      "      _lastOutcomes = outcomes\n"
      "          .where((ActionOutcome outcome) => outcome.message.isNotEmpty)\n"
      "          .toList();\n"
      "      if (_lastOutcomes.isNotEmpty) {\n"
      "        _messages.add(\n"
      "          AiMessage(\n"
      "            role: 'assistant',\n"
      "            content: '⚡ ${_lastOutcomes.map((ActionOutcome o) => o.message).join('\\n')}',\n"
      "            provider: activeProvider,\n"
      "            createdAt: DateTime.now(),\n"
      "          ),\n"
      "        );\n"
      "        await _persistHistory();\n"
      "      }\n"
      "      return _lastOutcomes;\n"
      "    } finally {\n"
      "      _executing = false;\n"
      "      notifyListeners();\n"
      "    }\n"
      "  }\n\n"
      "  /// Pide a la IA metadatos corregidos para el editor simplificado.\n"
      "  Future<Map<String, String>?> suggestMetadata(Song song) async {\n"
      "    final AiOrchestrator? orchestrator = buildOrchestrator();\n"
      "    if (orchestrator == null) return null;\n"
      "    _setBusy(true, 'Completando los datos de la canción…');\n"
      "    try {\n"
      "      return await orchestrator.suggestMetadata(song);\n"
      "    } catch (error) {\n"
      "      _lastError = error is AiRequestException ? error.message : error.toString();\n"
      "      return null;\n"
      "    } finally {\n"
      "      _setBusy(false, 'Listo');\n"
      "    }\n"
      "  }\n\n"
      "  /// Recomendaciones personalizadas según género, artista, mood o lista actual.",
      label="motor de acciones + autocompletado")

# ==================================================================== 2. HomeShell
patch("lib/screens/home_shell.dart",
      r"import '\.\./providers/settings_provider\.dart';",
      "import '../providers/settings_provider.dart';\nimport '../services/media_importer.dart';",
      label="import MediaImporter")

patch("lib/screens/home_shell.dart",
      r"  \];\n\n  @override\n  Widget build\(BuildContext context\) \{",
      "  ];\n\n"
      "  bool _autoImportStarted = false;\n\n"
      "  @override\n"
      "  void initState() {\n"
      "    super.initState();\n"
      "    // Importación automática de la música del dispositivo al abrir la app.\n"
      "    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoImport());\n"
      "  }\n\n"
      "  /// Escanea MediaStore (si está activado) y avisa de las canciones nuevas.\n"
      "  Future<void> _runAutoImport() async {\n"
      "    if (_autoImportStarted || !mounted) return;\n"
      "    _autoImportStarted = true;\n"
      "    final SettingsProvider settings = context.read<SettingsProvider>();\n"
      "    if (!settings.autoImport) return;\n"
      "    await MediaImporter.ensureAudioPermission();\n"
      "    final int added = await context.read<LibraryProvider>().autoScan();\n"
      "    if (!mounted || added <= 0) return;\n"
      "    ScaffoldMessenger.of(context).showSnackBar(\n"
      "      SnackBar(content: Text('$added canciones añadidas a tu biblioteca 🎵')),\n"
      "    );\n"
      "  }\n\n"
      "  @override\n"
      "  Widget build(BuildContext context) {",
      label="initState + importación automática")

# ====================================================================== 3. Ajustes
patch("lib/screens/settings_screen.dart",
      r"          const _SectionTitle\('Biblioteca y respaldo'\),",
      "          const _SectionTitle('Biblioteca y respaldo'),\n"
      "          SwitchListTile(\n"
      "            value: settings.autoImport,\n"
      "            onChanged: (bool value) => settings.setAutoImport(value),\n"
      "            title: const Text('Importar canciones automáticamente'),\n"
      "            subtitle: const Text(\n"
      "              'Escanea la música del dispositivo al abrir la app y añade lo nuevo.',\n"
      "            ),\n"
      "          ),\n"
      "          ListTile(\n"
      "            leading: library.isScanning\n"
      "                ? const SizedBox(\n"
      "                    width: 22,\n"
      "                    height: 22,\n"
      "                    child: CircularProgressIndicator(strokeWidth: 2),\n"
      "                  )\n"
      "                : const Icon(Icons.refresh),\n"
      "            title: const Text('Escanear ahora'),\n"
      "            subtitle: Text(library.scanMessage ?? 'Busca música nueva en el dispositivo'),\n"
      "            onTap: () async {\n"
      "              final int added = await library.autoScan(force: true);\n"
      "              if (!context.mounted) return;\n"
      "              ScaffoldMessenger.of(context).showSnackBar(\n"
      "                SnackBar(\n"
      "                  content: Text(\n"
      "                    added == 0\n"
      "                        ? 'No hay canciones nuevas'\n"
      "                        : '$added canciones añadidas',\n"
      "                  ),\n"
      "                ),\n"
      "              );\n"
      "            },\n"
      "          ),",
      label="interruptor + escanear ahora")

# ================================================================ 4. Pantalla de IA
patch("lib/screens/ai_screen.dart",
      r"import '\.\./providers/ai_provider\.dart';",
      "import '../providers/ai_provider.dart';\nimport '../services/ai/action_executor.dart';",
      label="import ActionOutcome")

patch("lib/screens/ai_screen.dart",
      r"          _quickActions\(context, ai, library\),",
      "          _executedActions(ai),\n          _quickActions(context, ai, library),",
      label="mostrar órdenes ejecutadas")

patch("lib/screens/ai_screen.dart",
      r"  Widget _quickActions\(",
      "  /// Chips con las últimas órdenes que la IA ejecutó sobre la app.\n"
      "  Widget _executedActions(AiAssistantProvider ai) {\n"
      "    final List<ActionOutcome> outcomes = ai.lastOutcomes;\n"
      "    if (outcomes.isEmpty) return const SizedBox.shrink();\n"
      "    return Padding(\n"
      "      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),\n"
      "      child: Column(\n"
      "        crossAxisAlignment: CrossAxisAlignment.start,\n"
      "        children: <Widget>[\n"
      "          const Text(\n"
      "            'Órdenes ejecutadas',\n"
      "            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),\n"
      "          ),\n"
      "          const SizedBox(height: 6),\n"
      "          Wrap(\n"
      "            spacing: 6,\n"
      "            runSpacing: 6,\n"
      "            children: outcomes\n"
      "                .map(\n"
      "                  (ActionOutcome outcome) => Chip(\n"
      "                    avatar: Icon(\n"
      "                      outcome.ok ? Icons.check_circle : Icons.error_outline,\n"
      "                      size: 16,\n"
      "                      color: outcome.ok ? AppColors.green : AppColors.warn,\n"
      "                    ),\n"
      "                    label: Text(\n"
      "                      outcome.message,\n"
      "                      style: const TextStyle(fontSize: 11),\n"
      "                    ),\n"
      "                    visualDensity: VisualDensity.compact,\n"
      "                  ),\n"
      "                )\n"
      "                .toList(),\n"
      "          ),\n"
      "        ],\n"
      "      ),\n"
      "    );\n"
      "  }\n\n"
      "  Widget _quickActions(",
      label="widget de órdenes")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
print(f"total: {len(ok)} aplicados, {len(fail)} fallidos")
sys.exit(0 if not fail else 1)
