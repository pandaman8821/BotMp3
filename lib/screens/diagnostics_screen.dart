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
    final AppLocalizations loc = AppLocalizations.of(context);
    String siNo(bool? valor) => valor == null ? '?' : (valor ? loc.diagYes : loc.diagNo);

    // Antes varias líneas llevaban el CÓDIGO dentro del texto (se copiaba
    // literalmente "AppLocalizations.of(context).trendsTitle:").
    final String informe = <String>[
      loc.diagReportTitle,
      'just_audio + just_audio_background',
      '${loc.diagNotifications}: ${siNo(_notificaciones)}',
      '${loc.diagBattery}: ${siNo(_bateriaLibre)}',
      '${loc.trendsTitle}: ${siNo(settings.trendsNotify)}',
      'Glass: ${siNo(settings.glassActive)}',
      '${loc.tabSongs}: ${player.service.queue.length}',
      '${loc.diagSources}: $secuencia',
      '${loc.diagIndexNow}: ${player.service.currentIndex}',
      '${loc.diagPlayingF}: ${siNo(player.playing)}',
      '${loc.diagStateF}: ${player.service.player.processingState.name}',
      '${loc.diagSongF}: ${player.current?.title ?? '—'}',
      '${loc.diagRecentErrors}: ${errores.isEmpty ? loc.diagNone : errores.length}',
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
            loc.diagNotifications,
            _notificaciones == null ? '…' : (_notificaciones! ? loc.diagGranted : loc.diagDenied),
            ok: _notificaciones,
            ayuda: loc.diagNotifHelp,
          ),
          _fila(
            loc.diagBattery,
            _bateriaLibre == null ? '…' : (_bateriaLibre! ? loc.diagYes : loc.diagNo),
            ok: _bateriaLibre,
            ayuda: loc.diagBatteryHelp,
          ),
          _Section(loc.diagMediaSession),
          _fila(
            loc.diagSources,
            '$secuencia',
            ok: secuencia == player.service.queue.length,
            ayuda: loc.diagSourcesHelp('${player.service.queue.length}'),
          ),
          _fila(loc.diagIndexNow, '${player.service.currentIndex}'),
          _fila(loc.diagPlayingF, player.playing ? loc.diagYes : loc.diagNo),
          _fila(loc.diagStateF, player.service.player.processingState.name),
          _fila(loc.diagSongF, player.current?.title ?? '—'),
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
