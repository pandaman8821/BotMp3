import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

/// Diagnóstico de la reproducción en segundo plano.
///
/// Sirve para comprobar, en el propio móvil, por qué no responden los controles
/// de la pantalla de bloqueo: si la sesión multimedia conoce la cola, cuántos
/// errores de reproducción ha habido y si los permisos están concedidos.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool? _notificaciones;
  bool? _bateriaLibre;

  @override
  void initState() {
    super.initState();
    _comprobar();
  }

  Future<void> _comprobar() async {
    final bool notificaciones = await NotificationService.instance.estanActivas();
    final bool bateria = await NotificationService.instance.sinRestriccionesDeBateria();
    if (!mounted) return;
    setState(() {
      _notificaciones = notificaciones;
      _bateriaLibre = bateria;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PlayerProvider player = context.watch<PlayerProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    // Fuentes que el reproductor tiene cargadas: la sesión multimedia
    // conoce exactamente estas, así que la pantalla de bloqueo puede
    // ofrecer siguiente/anterior cuando coinciden con la cola.
    final int secuencia = player.service.player.sequence.length;
    final List<String> errores = player.service.ultimosErrores;

    final String informe = <String>[
      'BotMp3 · diagnóstico de reproducción',
      'Artículo: just_audio + just_audio_background',
      'Notificaciones permitidas: ${_notificaciones == null ? '?' : (_notificaciones! ? 'sí' : 'NO')}',
      'Batería sin restricciones: ${_bateriaLibre == null ? '?' : (_bateriaLibre! ? 'sí' : 'NO')}',
      'AppLocalizations.of(context).trendsTitle: ${settings.trendsNotify ? AppLocalizations.of(context).diagYes : AppLocalizations.of(context).diagNo}',
      'Glass: ${settings.glassActive ? AppLocalizations.of(context).diagYes : AppLocalizations.of(context).diagNo}',
      'AppLocalizations.of(context).diagSources: ${player.service.queue.length}',
      'Fuentes cargadas en la sesión: $secuencia',
      'AppLocalizations.of(context).diagIndexNow: ${player.service.currentIndex}',
      'Suena: ${player.playing ? 'sí' : 'no'}',
      'AppLocalizations.of(context).diagStateF: ${player.service.player.processingState.name}',
      'Canción actual: ${player.current?.title ?? '—'}',
      'AppLocalizations.of(context).diagRecentErrors: ${errores.isEmpty ? AppLocalizations.of(context).diagNone : errores.length}',
      ...errores,
    ].join('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).playbackDiagnostics),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context).diagCopyReport,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: informe));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).diagReportCopied)),
              );
            },
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).diagRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _comprobar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: <Widget>[
          _Section(AppLocalizations.of(context).diagPermissions),
          _fila(
            'Notificaciones',
            _notificaciones == null ? '…' : (_notificaciones! ? 'Concedidas' : 'Sin conceder'),
            ok: _notificaciones,
            ayuda: 'Sin este permiso Android no muestra la notificación de '
                'reproducción y la pantalla de bloqueo se queda sin controles.',
          ),
          _fila(
            'Batería sin restricciones',
            _bateriaLibre == null ? '…' : (_bateriaLibre! ? 'Sí' : 'No'),
            ok: _bateriaLibre,
            ayuda: 'En HyperOS/MIUI conviene activar «Inicio automático» y quitar '
                'la restricción de batería para que el servicio no se detenga.',
          ),
          const _Section('Sesión multimedia'),
          _fila(
            'Fuentes cargadas en la sesión',
            '$secuencia',
            ok: secuencia == player.service.queue.length,
            ayuda: 'Debe coincidir con las canciones de la cola (${player.service.queue.length}). '
                'Si no coincide, la pantalla de bloqueo no podrá cambiar de pista.',
          ),
          _fila('Índice actual', '${player.service.currentIndex}'),
          _fila('Sonando', player.playing ? 'Sí' : 'No'),
          _fila('Estado', player.service.player.processingState.name),
          _fila('Canción', player.current?.title ?? '—'),
          _Section(AppLocalizations.of(context).diagRecentErrors),
          if (errores.isEmpty)
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: AppColors.green),
              title: Text(AppLocalizations.of(context).diagNoErrors),
              subtitle: Text(AppLocalizations.of(context).diagErrorsHere),
            )
          else
            for (final String error in errores)
              ListTile(
                leading: const Icon(Icons.error_outline, color: AppColors.danger),
                title: Text(error, style: const TextStyle(fontSize: 12.5)),
              ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context).diagCopyThis,
              style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String titulo, String valor, {bool? ok, String? ayuda}) {
    return ListTile(
      title: Text(titulo),
      subtitle: ayuda == null ? null : Text(ayuda, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          if (ok != null)
            Icon(
              ok ? Icons.check_circle : Icons.warning_amber_rounded,
              color: ok ? AppColors.green : AppColors.warning,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        titulo.toUpperCase(),
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }
}
