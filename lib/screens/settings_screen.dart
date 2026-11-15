import '../services/ai/model_catalog_service.dart';
import '../services/m3u_service.dart';
import '../widgets/modern_app_bar.dart';
import '../models/playlist.dart';
import 'stats_screen.dart';
import '../l10n/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../providers/ai_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_importer.dart';
import '../services/app_info_service.dart';
import '../services/storage_service.dart';
import '../services/secure_keys_service.dart';
import '../services/notification_service.dart';
import '../services/trends_service.dart';
import 'ranking_screen.dart';
import 'diagnostics_screen.dart';
import 'trends_screen.dart';
import '../services/voice_service.dart';
import '../widgets/dialogs.dart';
import 'duplicates_screen.dart';
import 'folder_screen.dart';
import 'history_screen.dart';
import '../widgets/theme_picker.dart';

part 'settings/seccion_general.dart';
part 'settings/seccion_reproduccion.dart';
part 'settings/seccion_biblioteca.dart';
part 'settings/seccion_acerca.dart';

/// Ajustes: apariencia, IA multimodelo (API keys cifradas), reproducción,
/// rendimiento, voz y gestión de la biblioteca.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with _SeccionesGenerales, _SeccionesReproduccion, _SeccionBiblioteca, _SeccionAcerca {
  final TextEditingController _buscador = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _anclas = <String, GlobalKey>{};

  /// Palabras clave por seccion (sin acentos) para el buscador.
  static const Map<String, List<String>> _indice = <String, List<String>>{
    'tendencias': <String>['tendencia', 'trend', 'pais', 'notificacion', 'aviso'],
    'apariencia': <String>['tema', 'theme', 'color', 'cristal', 'glass', 'animacion', 'caratula'],
    'ia': <String>['ia', 'ai', 'modelo', 'clave', 'api', 'gemini', 'deepseek', 'openai', 'claude'],
    'reproduccion': <String>['reproduc', 'playback', 'volumen', 'normaliza', 'replaygain', 'fundido', 'fade', 'auricular', 'bluetooth'],
    'rendimiento': <String>['rendimiento', 'cache', 'espacio', 'sqlite', 'indice'],
    'voz': <String>['voz', 'voice', 'tts', 'hablar', 'leer'],
    'biblioteca': <String>['biblioteca', 'escanear', 'scan', 'importar', 'exportar', 'copia', 'backup', 'm3u', 'json', 'duplicado'],
    'acerca': <String>['acerca', 'about', 'version', 'licencia', 'gpl', 'novedad'],
  };

  @override
  void dispose() {
    _buscador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _sinAcentos(String texto) {
    const Map<String, String> mapa = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    String salida = texto.toLowerCase();
    mapa.forEach((String k, String v) => salida = salida.replaceAll(k, v));
    return salida;
  }

  @override
  GlobalKey _ancla(String nombre) =>
      _anclas.putIfAbsent(nombre, () => GlobalKey());

  /// Nombre visible de cada seccion (para las sugerencias del buscador).
  String _tituloSeccion(BuildContext context, String clave) {
    final AppLocalizations loc = AppLocalizations.of(context);
    switch (clave) {
      case 'tendencias':
        return loc.trendsTitle;
      case 'apariencia':
        return loc.secAppearance;
      case 'ia':
        return loc.secAi;
      case 'reproduccion':
        return loc.secPlayback;
      case 'rendimiento':
        return loc.secPerformance;
      case 'voz':
        return loc.secVoice;
      case 'biblioteca':
        return loc.secLibrary;
      default:
        return loc.aboutTitle;
    }
  }

  /// Secciones que coinciden con lo escrito (nombre o palabra clave).
  List<String> _coincidencias() {
    final String q = _sinAcentos(_buscador.text.trim());
    if (q.isEmpty) return const <String>[];
    return _indice.entries
        .where((MapEntry<String, List<String>> e) =>
            _sinAcentos(e.key).contains(q) ||
            e.value.any((String p) => _sinAcentos(p).contains(q)))
        .map((MapEntry<String, List<String>> e) => e.key)
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final AiAssistantProvider ai = context.watch<AiAssistantProvider>();
    final LibraryProvider library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TituloPantalla(text: AppLocalizations.of(context).tabSettings),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 40),
        children: <Widget>[
          // Buscador: escribe y salta a la seccion que corresponda.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _buscador,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: AppLocalizations.of(context).settingsSearch,
                suffixIcon: _buscador.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _buscador.clear();
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          // Sugerencias del buscador: toca para saltar a esa seccion.
          if (_buscador.text.trim().isNotEmpty)
            if (_coincidencias().isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  AppLocalizations.of(context).settingsSearchNone,
                  style: TextStyle(fontSize: 12, color: AppColors.darkTextDim),
                ),
              )
            else
              for (final String clave in _coincidencias())
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.arrow_forward, size: 18),
                  title: Text(_tituloSeccion(context, clave)),
                  subtitle: Text(AppLocalizations.of(context).settingsGoTo),
                  onTap: () {
                    final BuildContext? alvo = _anclas[clave]?.currentContext;
                    if (alvo != null) {
                      Scrollable.ensureVisible(
                        alvo,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                    _buscador.clear();
                    setState(() {});
                  },
                ),
          ..._seccionTendencias(context, settings, ai, library),
          ..._seccionApariencia(context, settings, ai, library),
          ..._seccionIa(context, settings, ai, library),
          ..._seccionReproduccion(context, settings, ai, library),
          ..._seccionVoz(context, settings, ai, library),
          ..._seccionBiblioteca(context, settings, ai, library),
          ..._seccionAcerca(context, settings, ai, library),
        ],
      ),
    );
  }
}

/// Permite escribir un identificador de modelo que no esté en la lista: los
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
      title: Text(AppLocalizations.of(context).modelOf(provider.label)),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).modelId,
          helperText: AppLocalizations.of(context).modelIdExample,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(AppLocalizations.of(context).useModel),
        ),
      ],
    ),
  );
  controller.dispose();
  if (escrito != null && escrito.isNotEmpty) {
    await ai.selectModel(provider, escrito);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Tarjeta de configuración de un proveedor de IA (clave + modelo + prueba).
class _ApiKeyCard extends StatefulWidget {
  const _ApiKeyCard({required this.provider, required this.ai});

  final AiProvider provider;
  final AiAssistantProvider ai;

  @override
  State<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends State<_ApiKeyCard> {
  late final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  bool _buscandoModelos = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AiProvider provider = widget.provider;
    final AiAssistantProvider ai = widget.ai;
    final String mask = ai.maskFor(provider);
    final bool configured = ai.keyFor(provider) != null;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final String model = settings.modelFor(provider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(provider.icon, size: 20, color: AppColors.aiCyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (configured)
                  Icon(Icons.verified_user, size: 16, color: AppColors.green),
                IconButton(
                  tooltip: AppLocalizations.of(context).refreshModels,
                  icon: _buscandoModelos
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 18),
                  onPressed: _buscandoModelos
                      ? null
                      : () async {
                          final String? clave = ai.keyFor(provider);
                          if (clave == null || clave.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context).aiKeyMissingFirst,
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _buscandoModelos = true);
                          int total = 0;
                          try {
                            total = await ModelCatalogService.instance
                                .actualizar(provider, clave);
                          } catch (_) {
                            total = 0;
                          }
                          if (!context.mounted) return;
                          setState(() => _buscandoModelos = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                total > 0
                                    ? AppLocalizations.of(context)
                                        .modelsRefreshed('$total')
                                    : AppLocalizations.of(context)
                                        .modelsRefreshFailed,
                              ),
                            ),
                          );
                        },
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).getApiKey,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: provider.keysUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)
                              .linkCopied(provider.keysUrl),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (mask.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  AppLocalizations.of(context).keySaved(mask),
                  style: TextStyle(fontSize: 12, color: AppColors.green),
                ),
              ),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: configured ? AppLocalizations.of(context).replaceKey : provider.hint,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                ...provider.models.map((String value) {
                  final bool gratis = esModeloGratis(provider, value);
                  return ChoiceChip(
                    avatar: gratis
                        ? Tooltip(
                            message: AppLocalizations.of(context).freeBadge,
                            child: Icon(
                              Icons.bolt,
                              size: 15,
                              color: AppColors.green,
                            ),
                          )
                        : null,
                    label: Text(value, style: const TextStyle(fontSize: 12)),
                    selected: model == value,
                    onSelected: (_) => ai.selectModel(provider, value),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.edit_outlined, size: 15),
                  label: Text(AppLocalizations.of(context).otherOption, style: const TextStyle(fontSize: 12)),
                  onPressed: () =>
                      escribirModeloPersonalizado(context, ai, provider, model),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppLocalizations.of(context).modelsAutoHint,
                style: TextStyle(fontSize: 11, color: AppColors.darkTextDim),
              ),
            ),
            if (provider.hintFor(model) != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.info_outline, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        provider.hintFor(model)!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await ai.saveKey(provider, _controller.text);
                      _controller.clear();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ai.keyFor(provider) == null
                                ? AppLocalizations.of(context).keyRemovedFor(provider.label)
                                : AppLocalizations.of(context).keyStoredFor(provider.label),
                          ),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context).btnSave),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _testing || !configured
                        ? null
                        : () async {
                            setState(() => _testing = true);
                            final bool ok = await ai.testConnection();
                            if (!mounted || !context.mounted) return;
                            setState(() => _testing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${provider.label}: ${ai.status}'
                                      : ai.lastError ?? AppLocalizations.of(context).aiErrorConnection,
                                ),
                              ),
                            );
                          },
                    child: _testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context).btnTest),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// Utilidad de enmascarado expuesta para otras pantallas.
String maskKey(String key) => SecureKeysService.mask(key);

/// Ajuste compacto: titulo y subtitulo a lo ancho (maximo 2 lineas) y los
/// controles debajo, para que no se apilen el texto ni ocupen media pantalla.
class _AjusteApilado extends StatelessWidget {
  const _AjusteApilado({
    required this.icono,
    required this.titulo,
    required this.child,
    this.subtitulo,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icono, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                subtitulo!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.darkTextDim),
              ),
            ),
          Padding(padding: const EdgeInsets.only(left: 34, top: 8), child: child),
        ],
      ),
    );
  }
}
