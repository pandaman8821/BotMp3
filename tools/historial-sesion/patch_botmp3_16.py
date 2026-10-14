"""BotMp3 v1.3.4 — modelos de IA al día (DeepSeek incluido).

La API de DeepSeek retiró `deepseek-chat` y `deepseek-reasoner`. Los vigentes son
`deepseek-flash` (rápido y económico) y `deepseek-v4-pro` (más capaz). Además, la
API activa el modo «thinking» por defecto, lo que hace lentas las tareas simples.

Cambios:
  1. Lista de modelos de DeepSeek actualizada + pista por modelo en la interfaz.
  2. Migración automática: si tenías guardado un modelo retirado, se usa el nuevo.
  3. Modo «thinking» desactivado en las tareas con salida JSON (metadatos, listas,
     búsqueda, órdenes) y activado en la conversación.
  4. Opción «Otro…» para escribir cualquier identificador de modelo.
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


# ============================================ 1. Modelos vigentes + pistas
patch("lib/core/constants.dart",
      r"      case AiProvider\.deepseek:\n        return <String>\['deepseek-chat', 'deepseek-reasoner'\];",
      "      case AiProvider.deepseek:\n"
      "        // Nombres VIGENTES de la API de DeepSeek. Los antiguos\n"
      "        // `deepseek-chat` y `deepseek-reasoner` ya no existen.\n"
      "        return <String>['deepseek-flash', 'deepseek-v4-pro'];",
      label="modelos de DeepSeek actualizados")

pistas = """  String get defaultModel => models.first;

  /// Pista corta sobre un modelo concreto (se muestra bajo el selector).
  String? hintFor(String model) {
    switch (model) {
      case 'deepseek-flash':
        return 'Recomendado: el más rápido y económico (ideal para toda la app).';
      case 'deepseek-v4-pro':
        return 'Más capaz en razonamiento; cuesta unas 4 veces más por uso.';
      case 'deepseek-chat':
      case 'deepseek-reasoner':
        return 'Nombre retirado por DeepSeek: usa deepseek-flash o deepseek-v4-pro.';
      case 'gpt-4o':
        return 'Equilibrado y con buen español; buen equilibrio calidad/precio.';
      case 'gpt-4o-mini':
        return 'Muy rápido y barato; suficiente para metadatos y listas.';
      case 'o1':
      case 'o1-mini':
        return 'Razonamiento: más lento y caro; con estos la app omite el modo JSON.';
      case 'gemini-2.0-flash':
      case 'gemini-1.5-flash':
        return 'Rápido y con cuota gratuita generosa de Google.';
      case 'gemini-1.5-pro':
        return 'Más capaz; consume antes la cuota gratuita.';
      case 'claude-3-5-haiku-latest':
        return 'El más rápido y económico de Claude.';
      case 'claude-3-5-sonnet-latest':
        return 'Equilibrado; muy buena redacción en español.';
      case 'claude-3-opus-latest':
        return 'El más potente de Claude y también el más caro.';
    }
    return null;
  }"""

patch("lib/core/constants.dart",
      r"  String get defaultModel => models\.first;",
      pistas,
      label="pistas por modelo")

# ============================================ 2. Migración de nombres retirados
patch("lib/services/settings_service.dart",
      r"  String modelFor\(AiProvider provider\) =>\n"
      r"      _prefs\.getString\('ai_model_\$\{provider\.id\}'\) \?\? provider\.defaultModel;",
      "  /// Nombres de modelo retirados por los proveedores → sustituto vigente.\n"
      "  static const Map<String, String> _modelosRetirados = <String, String>{\n"
      "    'deepseek-chat': 'deepseek-flash',\n"
      "    'deepseek-reasoner': 'deepseek-v4-pro',\n"
      "  };\n\n"
      "  String modelFor(AiProvider provider) {\n"
      "    final String? guardado = _prefs.getString('ai_model_${provider.id}');\n"
      "    if (guardado == null || guardado.trim().isEmpty) return provider.defaultModel;\n"
      "    // Si el proveedor retiró ese modelo, se migra solo al equivalente actual.\n"
      "    return _modelosRetirados[guardado.trim()] ?? guardado.trim();\n"
      "  }",
      label="migración de modelos retirados")

# ============================================ 3. Control del modo «thinking»
patch("lib/services/ai/openai_client.dart",
      r"    final Map<String, dynamic> body = <String, dynamic>\{\n"
      r"      'model': model,\n"
      r"      'messages': payloadMessages,\n"
      r"      if \(!reasoningModel\) 'temperature': temperature,\n"
      r"      'max_tokens': maxTokens,\n"
      r"      if \(json && !reasoningModel\) 'response_format': <String, String>\{'type': 'json_object'\},\n"
      r"    \};",
      "    // La API de DeepSeek activa el modo «thinking» por defecto. En las tareas\n"
      "    // con salida JSON (metadatos, listas, búsqueda, órdenes) se desactiva:\n"
      "    // responde antes, cuesta menos y no arriesga el formato. En conversación\n"
      "    // se deja activado para ganar calidad.\n"
      "    final bool esDeepSeek = baseUrl.contains('deepseek');\n\n"
      "    final Map<String, dynamic> body = <String, dynamic>{\n"
      "      'model': model,\n"
      "      'messages': payloadMessages,\n"
      "      if (!reasoningModel) 'temperature': temperature,\n"
      "      'max_tokens': maxTokens,\n"
      "      if (json && !reasoningModel)\n"
      "        'response_format': <String, String>{'type': 'json_object'},\n"
      "      if (esDeepSeek)\n"
      "        'thinking': <String, String>{'type': json ? 'disabled' : 'enabled'},\n"
      "    };",
      label="modo thinking según la tarea")

# ============================================ 4. Interfaz: pista + «Otro…»
patch("lib/screens/settings_screen.dart",
      r"            Wrap\(\n"
      r"              spacing: 8,\n"
      r"              runSpacing: 4,\n"
      r"              children: provider\.models\.map\(\(String value\) \{\n"
      r"                return ChoiceChip\(\n"
      r"                  label: Text\(value, style: const TextStyle\(fontSize: 12\)\),\n"
      r"                  selected: model == value,\n"
      r"                  onSelected: \(_\) => ai\.selectModel\(provider, value\),\n"
      r"                \);\n"
      r"              \}\)\.toList\(\),\n"
      r"            \),",
      "            Wrap(\n"
      "              spacing: 8,\n"
      "              runSpacing: 4,\n"
      "              children: <Widget>[\n"
      "                ...provider.models.map((String value) {\n"
      "                  return ChoiceChip(\n"
      "                    label: Text(value, style: const TextStyle(fontSize: 12)),\n"
      "                    selected: model == value,\n"
      "                    onSelected: (_) => ai.selectModel(provider, value),\n"
      "                  );\n"
      "                }),\n"
      "                ActionChip(\n"
      "                  avatar: const Icon(Icons.edit_outlined, size: 15),\n"
      "                  label: const Text('Otro…', style: TextStyle(fontSize: 12)),\n"
      "                  onPressed: () =>\n"
      "                      escribirModeloPersonalizado(context, ai, provider, model),\n"
      "                ),\n"
      "              ],\n"
      "            ),\n"
      "            if (provider.hintFor(model) != null)\n"
      "              Padding(\n"
      "                padding: const EdgeInsets.only(top: 6),\n"
      "                child: Row(\n"
      "                  crossAxisAlignment: CrossAxisAlignment.start,\n"
      "                  children: <Widget>[\n"
      "                    const Icon(Icons.info_outline, size: 15),\n"
      "                    const SizedBox(width: 6),\n"
      "                    Expanded(\n"
      "                      child: Text(\n"
      "                        provider.hintFor(model)!,\n"
      "                        style: const TextStyle(fontSize: 11.5),\n"
      "                      ),\n"
      "                    ),\n"
      "                  ],\n"
      "                ),\n"
      "              ),",
      label="pista del modelo + chip Otro…")

ayuda = """/// Permite escribir un identificador de modelo que no esté en la lista: los
/// proveedores renombran y retiran modelos con frecuencia.
Future<void> escribirModeloPersonalizado(
  BuildContext context,
  AiAssistantProvider ai,
  AiProvider provider,
  String actual,
) async {
  final TextEditingController controller = TextEditingController(text: actual);
  final String? escrito = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text('Modelo de ${provider.label}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Identificador del modelo',
          helperText: 'Ej.: deepseek-flash, gpt-4o-mini, gemini-2.0-flash…',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Usar'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (escrito != null && escrito.isNotEmpty) {
    await ai.selectModel(provider, escrito);
  }
}

class _SectionTitle extends StatelessWidget {"""

patch("lib/screens/settings_screen.dart",
      r"class _SectionTitle extends StatelessWidget \{",
      ayuda,
      label="función de modelo personalizado")

print("APLICADOS:")
for item in ok:
    print("  +", item)
if fail:
    print("FALLOS:")
    for item in fail:
        print("  !", item)
sys.exit(0 if not fail else 1)
