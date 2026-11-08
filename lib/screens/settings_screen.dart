import '../services/m3u_service.dart';
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

/// Ajustes: apariencia, IA multimodelo (API keys cifradas), reproducción,
/// rendimiento, voz y gestión de la biblioteca.
class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final AiAssistantProvider ai = context.watch<AiAssistantProvider>();
    final LibraryProvider library = context.watch<LibraryProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).tabSettings)),
      body: ListView(
        padding: EdgeInsets.only(bottom: 40),
        children: <Widget>[
          // ---------------------------------------------------- Apariencia
          const _SectionTitle('Tendencias musicales'),
          ListTile(
            leading: Icon(Icons.public),
            title: Text(AppLocalizations.of(context).countryForTrends),
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
            leading: Icon(Icons.schedule),
            title: Text(AppLocalizations.of(context).dailyAlertTime),
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
            secondary: Icon(Icons.notifications_active_outlined),
            title: Text(AppLocalizations.of(context).notifyTrends),
            subtitle: Text(AppLocalizations.of(context).subTrendsNotify),
          ),
          ListTile(
            leading: Icon(Icons.local_fire_department_outlined),
            title: Text(AppLocalizations.of(context).trendsNow),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => TrendsScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.health_and_safety_outlined),
            title: Text(AppLocalizations.of(context).playbackDiagnostics),
            subtitle: Text(AppLocalizations.of(context).subDiagnostics),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => DiagnosticsScreen()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.leaderboard_outlined),
            title: Text(AppLocalizations.of(context).seeMyRanking),
            subtitle: Text(AppLocalizations.of(context).subRanking),
            trailing: Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => RankingScreen()),
            ),
          ),
          _SectionTitle(AppLocalizations.of(context).secAppearance),
              const ThemePickerSection(),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text(AppLocalizations.of(context).lockControlsTitle),
            subtitle: Text(AppLocalizations.of(context).subLockControls),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(AppLocalizations.of(context).autoTheme),
                  selected: settings.themeMode == ThemeMode.system,
                  onSelected: (_) => settings.setThemeMode(ThemeMode.system),
                ),
                ChoiceChip(
                  label: Text(AppLocalizations.of(context).darkMode),
                  selected: settings.themeMode == ThemeMode.dark,
                  onSelected: (_) => settings.setThemeMode(ThemeMode.dark),
                ),
                ChoiceChip(
                  label: Text(AppLocalizations.of(context).lightMode),
                  selected: settings.themeMode == ThemeMode.light,
                  onSelected: (_) => settings.setThemeMode(ThemeMode.light),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------- IA
          _SectionTitle(AppLocalizations.of(context).secAi),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                for (final AiProvider provider in AiProvider.values)
                  _ApiKeyCard(provider: provider, ai: ai),
                SwitchListTile(
                  value: settings.autoDj,
                  onChanged: settings.setAutoDj,
                  title: Text(AppLocalizations.of(context).autoDjMode),
                  subtitle: Text(
                    AppLocalizations.of(context).aiExplains,
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------------- Reproducción
          _SectionTitle(AppLocalizations.of(context).secPlayback),
              SwitchListTile(
                value: settings.reanudarAlConectar,
                onChanged: (bool v) async => settings.setReanudarAlConectar(v),
                title: Text(AppLocalizations.of(context).resumeOnConnect),
                subtitle: Text(AppLocalizations.of(context).resumeOnConnectDesc, style: const TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.bluetooth_audio),
              ),
              SwitchListTile(
                value: settings.pausarAlDesconectar,
                onChanged: (bool v) async => settings.setPausarAlDesconectar(v),
                title: Text(AppLocalizations.of(context).pauseOnDisconnect),
                subtitle: Text(AppLocalizations.of(context).pauseOnDisconnectDesc, style: const TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.headset_off),
              ),
              SwitchListTile(
                value: settings.fundidoCanciones,
                onChanged: (bool v) async => settings.setFundidoCanciones(v),
                title: Text(AppLocalizations.of(context).fadeTitle),
                subtitle: Text(AppLocalizations.of(context).fadeDesc, style: const TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.gradient),
              ),
              SwitchListTile(
                value: settings.normalizarVolumen,
                onChanged: (bool v) async => settings.setNormalizarVolumen(v),
                title: Text(AppLocalizations.of(context).normalizeVolume),
                subtitle: Text(AppLocalizations.of(context).normalizeVolumeDesc, style: const TextStyle(fontSize: 12)),
                secondary: const Icon(Icons.graphic_eq),
              ),
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(AppLocalizations.of(context).sleepTimer),
              subtitle: Text(
                context.watch<PlayerProvider>().sleepRemaining == null
                    ? AppLocalizations.of(context).sleepTimerOff
                    : AppLocalizations.of(context).sleepTimerActive,
              ),
              onTap: () async {
                final PlayerProvider player = context.read<PlayerProvider>();
                final int? minutos = await showDialog<int>(
                  context: context,
                  builder: (BuildContext dc) => SimpleDialog(
                    title: Text(AppLocalizations.of(context).sleepTimer),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(dc).pop(0),
                        child: Text(AppLocalizations.of(context).sleepTimerCancel),
                      ),
                      for (final int m in <int>[15, 30, 60, 90])
                        SimpleDialogOption(
                          onPressed: () => Navigator.of(dc).pop(m),
                          child: Text(AppLocalizations.of(context).sleepTimerMinutes(m)),
                        ),
                    ],
                  ),
                );
                if (minutos == null) return;
                if (minutos == 0) {
                  player.cancelSleepTimer();
                } else {
                  player.startSleepTimer(Duration(minutes: minutos));
                }
              },
            ),

          SwitchListTile(
            value: settings.keepScreenOn,
            onChanged: (bool value) {
              settings.setKeepScreenOn(value);
              context.read<PlayerProvider>().setKeepScreenOn(value);
            },
            title: Text(AppLocalizations.of(context).screenAlwaysOn),
            subtitle: Text(AppLocalizations.of(context).subKeepScreen),
          ),
          SwitchListTile(
            value: settings.showWaveAnimation,
            onChanged: settings.setShowWaveAnimation,
            title: Text(AppLocalizations.of(context).soundWaves),
            subtitle: Text(AppLocalizations.of(context).subSoundWaves),
          ),

          // ---------------------------------------------------- Rendimiento
          
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(AppLocalizations.of(context).statsTitle),
              subtitle: Text(AppLocalizations.of(context).statsTotalPlays),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
              ),
            ),
ListTile(
                leading: const Icon(Icons.history),
                title: Text(AppLocalizations.of(context).historyTitle),
                subtitle: Text(AppLocalizations.of(context).historyEmpty, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(AppLocalizations.of(context).foldersTitle),
                subtitle: Text(AppLocalizations.of(context).foldersEmpty, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FolderScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_outlined),
                title: Text(AppLocalizations.of(context).duplicatesTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DuplicatesScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: Text(AppLocalizations.of(context).importM3u),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final String? contenido = await MediaImporter.pickM3uFile();
                  if (contenido == null || !context.mounted) return;
                  final List<Song> encontradas = M3uService.resolver(contenido, library.songs);
                  if (encontradas.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).m3uNoSongs)),
                    );
                    return;
                  }
                  final Playlist nueva = await library.createPlaylist(
                    name: AppLocalizations.of(context).m3uPlaylistName(DateTime.now().day, DateTime.now().month),
                  );
                  await library.addSongsToPlaylist(
                    nueva.id,
                    encontradas.map((Song s) => s.id).toList(),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).songsFromLibrary(encontradas.length))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(AppLocalizations.of(context).exportM3u),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final String contenido = M3uService.generar(library.songs);
                  final String? ruta = await MediaImporter.exportText('BotMp3_biblioteca.m3u', contenido);
                  if (ruta != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).exportedTo(ruta))),
                    );
                  }
                },
              ),
              _SectionTitle(AppLocalizations.of(context).secPerformance),
              ListTile(
                leading: const Icon(Icons.storage),
                title: Text(AppLocalizations.of(context).sqliteTitle),
                subtitle: Text(library.sqliteEstado, style: const TextStyle(fontSize: 12)),
              ),
          SwitchListTile(
            value: settings.batterySaver,
            onChanged: settings.setBatterySaver,
            title: Text(AppLocalizations.of(context).batterySaver),
            subtitle: Text(AppLocalizations.of(context).subBatterySaver),
          ),
          SwitchListTile(
            value: settings.thermalGuard,
            onChanged: settings.setThermalGuard,
            title: Text(AppLocalizations.of(context).thermalProtection),
            subtitle: Text(AppLocalizations.of(context).subThermal),
          ),

          // ---------------------------------------------------- Voz
          _SectionTitle(AppLocalizations.of(context).secVoice),
          SwitchListTile(
            value: settings.voiceEnabled,
            onChanged: settings.setVoiceEnabled,
            title: Text(AppLocalizations.of(context).voiceDictation),
            subtitle: Text(AppLocalizations.of(context).subVoice),
          ),
          SwitchListTile(
            value: settings.ttsEnabled,
            onChanged: settings.setTtsEnabled,
            title: Text(AppLocalizations.of(context).speakResponses),
            subtitle: Text(AppLocalizations.of(context).aiSpeaks),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: <String>['es-ES', 'es-MX', 'es-BO', 'es-AR'].map((String locale) {
                return ChoiceChip(
                  label: Text(locale),
                  selected: settings.voiceLocale == locale,
                  onSelected: (_) => settings.setVoiceLocale(locale),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () async {
                await VoiceService.instance.speak(
                  'Hola, soy BotMp3. Estoy listo para poner tu música.',
                  locale: settings.voiceLocale,
                );
              },
              icon: Icon(Icons.record_voice_over),
              label: Text('Probar voz'),
            ),
          ),

          // ---------------------------------------------------- Biblioteca
          _SectionTitle(AppLocalizations.of(context).secAppearance),
          SwitchListTile(
            value: settings.glassEnabled,
            onChanged: (bool value) => settings.setGlassEnabled(value),
            secondary: Icon(Icons.blur_on),
            title: Text(AppLocalizations.of(context).glassEffect),
            subtitle: Text(
              AppLocalizations.of(context).glassDesc,
            ),
          ),
          ListTile(
            leading: Icon(Icons.opacity),
            title: Text(AppLocalizations.of(context).glassIntensity),
            subtitle: Slider(
              value: settings.glassIntensity,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              label: '${(settings.glassIntensity * 100).round()}%',
              onChanged: settings.glassEnabled
                  ? (double value) => settings.setGlassIntensity(value)
                  : null,
            ),
            onTap: null,
          ),
          _SectionTitle(AppLocalizations.of(context).secLibrary),
          SwitchListTile(
            value: settings.autoImport,
            onChanged: (bool value) => settings.setAutoImport(value),
            title: Text(AppLocalizations.of(context).autoImport),
            subtitle: Text(AppLocalizations.of(context).subAutoImport),
          ),
          SwitchListTile(
            value: settings.importMediaAudio,
            onChanged: (bool value) async {
              await settings.setImportMediaAudio(value);
              if (!context.mounted) return;
              // Se vuelve a escanear para importar (o dejar de mostrar)
              // estos audios sin reiniciar la app.
              await library.autoScan(force: true);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Se incluirán los audios de apps y notas de voz'
                        : 'Solo se mostrará música',
                  ),
                ),
              );
            },
            title: Text(AppLocalizations.of(context).importAppAudio),
            subtitle: Text(AppLocalizations.of(context).subImportAppAudio),
          ),
          ListTile(
            leading: library.isScanning
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh),
            title: Text(AppLocalizations.of(context).scanNow),
            subtitle: Text(library.scanMessage ?? 'Busca música nueva en el dispositivo'),
            onTap: () async {
              final int added = await library.autoScan(force: true);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    added == 0
                        ? 'No hay canciones nuevas'
                        : '$added canciones añadidas',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_backup_restore),
            title: Text(AppLocalizations.of(context).restoreBackup),
            subtitle: Text(AppLocalizations.of(context).subRestoreBackup),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              final Map<String, dynamic>? copia = await StorageService.instance
                  .readJsonMap(StorageKeys.backupFile);
              if (!context.mounted) return;
              if (copia == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).noBackupSaved)),
                );
                return;
              }
              final bool? confirmar = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogo) => AlertDialog(
                  title: Text(AppLocalizations.of(context).restoreTheBackup),
                  content: Text(
                    AppLocalizations.of(context).restoreWarning,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogo).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogo).pop(true),
                      child: const Text('Restaurar'),
                    ),
                  ],
                ),
              );
              if (confirmar != true || !context.mounted) return;
              final Map<String, dynamic>? biblioteca =
                  (copia['biblioteca'] as Map?)?.cast<String, dynamic>();
              if (biblioteca != null) {
                await StorageService.instance
                    .writeJson(StorageKeys.library, biblioteca);
              }
              final List<dynamic>? historial =
                  (copia['historial'] as List?)?.cast<dynamic>();
              if (historial != null) {
                await StorageService.instance
                    .writeJson(StorageKeys.playLogFile, historial);
              }
              await library.init();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).backupRestored),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.file_download_outlined),
            title: Text(AppLocalizations.of(context).exportBackup),
            subtitle: Text(AppLocalizations.of(context).subExportBackup),
            onTap: () async {
              final Map<String, dynamic>? copia =
                  await StorageService.instance.readJsonMap(StorageKeys.backupFile);
              if (!context.mounted) return;
              if (copia == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).noBackupYet),
                  ),
                );
                return;
              }
              final String sello =
                  DateTime.now().toIso8601String().replaceAll(':', '').substring(0, 15);
              final String? ruta = await MediaImporter.exportText(
                'botmp3-copia-$sello.json',
                const JsonEncoder.withIndent('  ').convert(<String, dynamic>{'schema': 1, 'exportedAt': DateTime.now().toIso8601String(), ...copia}),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ruta == null ? 'Exportación cancelada' : 'Copia exportada ✅',
                  ),
                ),
              );
            },
          ),
          _AjusteApilado(
            icono: Icons.queue_music,
            titulo: AppLocalizations.of(context).djBatch,
            subtitulo: AppLocalizations.of(context).djBatchNow(settings.djCanciones),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                for (final int cantidad in <int>[10, 15, 25])
                  ChoiceChip(
                    label: Text(cantidad.toString()),
                    selected: settings.djCanciones == cantidad,
                    onSelected: (bool _) => settings.setDjCanciones(cantidad),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.graphic_eq),
            title: Text(AppLocalizations.of(context).equalizer),
            subtitle: Text(AppLocalizations.of(context).eqDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Se pasa la sesion real del motor para que el ecualizador nativo
              // actue sobre ella (la sesion global 0 esta restringida).
              final PlayerProvider player = context.read<PlayerProvider>();
              final int sesion =
                  player.service.player.androidAudioSessionId ?? 0;
              const MethodChannel('botmp3/equalizer').invokeMethod<bool>(
                'abrir',
                <String, dynamic>{'session': sesion},
              );
            },
          ),
          _AjusteApilado(
            icono: Icons.volume_up_outlined,
            titulo: AppLocalizations.of(context).volumeCurrent,
            subtitulo: AppLocalizations.of(context).subVolume,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: AppLocalizations.of(context).volumeDown,
                  icon: const Icon(Icons.remove),
                  onPressed: () => context.read<PlayerProvider>().service.ajustarVolumenCancion(-0.1),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: AppLocalizations.of(context).volumeUp,
                  icon: const Icon(Icons.add),
                  onPressed: () => context.read<PlayerProvider>().service.ajustarVolumenCancion(0.1),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: AppLocalizations.of(context).volumeReset,
                  icon: const Icon(Icons.restart_alt),
                  onPressed: () => context.read<PlayerProvider>().service.ajustarVolumenCancion(0, reset: true),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text(AppLocalizations.of(context).tagWithAi),
            subtitle: Text(
              AppLocalizations.of(context).tagAiDesc,
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              final AiAssistantProvider ai = context.read<AiAssistantProvider>();
              final List<Song> pendientes = library.songs
                  .where((Song s) => s.genre.trim().isEmpty)
                  .take(10)
                  .toList();
              if (!context.mounted) return;
              if (pendientes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).noSongsWithoutGenre)),
                );
                return;
              }
              int hechas = 0;
                for (final Song cancion in pendientes) {
                  // Reintento: la IA a veces devuelve texto que no es JSON.
                  Map<String, String>? datos;
                  for (int intento = 0; intento < 2 && datos == null; intento++) {
                    datos = await ai.suggestMetadata(cancion);
                    if (datos == null) {
                      await Future<void>.delayed(const Duration(milliseconds: 500));
                    }
                  }
                  if (datos == null) {
                    continue;
                  }
                final String genero =
                    (datos['genero'] ?? datos['genre'] ?? '').trim();
                if (genero.isEmpty) continue;
                await library.saveSong(cancion.copyWith(genre: genero));
                hechas++;
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hechas == 0
                        ? 'La IA no devolvió géneros (¿tienes clave configurada?)'
                        : '$hechas canciones etiquetadas con IA ✨',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.auto_fix_high_outlined),
            title: Text(AppLocalizations.of(context).fillGenres),
            subtitle: Text(AppLocalizations.of(context).subFillGenres),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final int cambiadas = await library.completarGeneros();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cambiadas == 0
                        ? 'No había géneros que completar'
                        : '$cambiadas canciones etiquetadas 🏷️',
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text(AppLocalizations.of(context).backupTitle),
            subtitle: Text(AppLocalizations.of(context).subBackup),
            trailing: TextButton(
              onPressed: () async {
                final bool hecha = await library.autoBackup(forzar: true);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      hecha
                          ? 'Copia hecha en el teléfono ✅'
                          : 'No se pudo hacer la copia',
                    ),
                  ),
                );
              },
              child: Text('Copiar'),
            ),
          ),
          ListTile(
            leading: Icon(Icons.cleaning_services_outlined),
            title: Text(AppLocalizations.of(context).freeUpSpace),
            subtitle: FutureBuilder<int>(
              future: library.cacheBytes(),
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                final String detail = snapshot.hasData
                    ? '${Formatters.bytes(snapshot.data!)} en caché (temporal, se puede borrar)'
                    : 'Calculando…';
                return Text(detail);
              },
            ),
            trailing: TextButton(
              onPressed: () async {
                final int freed = await library.freeSpace();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      freed > 0
                          ? 'Liberados ${Formatters.bytes(freed)} 🧹'
                          : 'No había nada que liberar',
                    ),
                  ),
                );
              },
              child: Text('Limpiar'),
            ),
          ),
          ListTile(
            leading: Icon(Icons.library_add),
            title: Text(AppLocalizations.of(context).importSongs),
            subtitle: Text('MP3, M4A, OGG, FLAC, WAV… seleccionando archivos o rutas'),
            onTap: () => AppDialogs.importSongs(context),
          ),
          ListTile(
            leading: Icon(Icons.folder_open),
            title: Text(AppLocalizations.of(context).importFolder),
            subtitle: Text(AppLocalizations.of(context).importFolderDesc),
            onTap: () async {
              final String? dir = await MediaImporter.pickFolder();
              if (dir == null) return;
              final List<String> files = MediaImporter.listAudioInFolder(dir);
              if (files.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).noCompatibleAudio)),
                  );
                }
                return;
              }
              final int added = await library.importPaths(files);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).songsImportedFromFolder(added))),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(AppLocalizations.of(context).exportLibraryJson),
            subtitle: Text('${library.songs.length} canciones · ${library.playlists.length} listas'),
            onTap: () async {
              final String json = library.exportLibraryJson();
              final String? path =
                  await MediaImporter.exportText('botmp3_biblioteca.json', json);
              if (context.mounted) {
                await Clipboard.setData(ClipboardData(text: json));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      path == null
                          ? 'JSON copiado al portapapeles'
                          : 'Biblioteca exportada y copiada al portapapeles',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(AppLocalizations.of(context).restoreLibraryJson),
            onTap: () async {
              final String? content = await MediaImporter.pickJsonFile();
              if (content == null) return;
              final int added = await library.importLibraryJson(content);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$added canciones restauradas')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
            title: Text(AppLocalizations.of(context).deleteLocalLibrary, style: TextStyle(color: Colors.redAccent)),
            subtitle: Text(AppLocalizations.of(context).noAudioDeleted),
            onTap: () async {
              final bool confirmed = await AppDialogs.confirm(
                context,
                title: 'Borrar biblioteca',
                message: AppLocalizations.of(context).clearAllWarning,
                confirmLabel: 'Borrar todo',
              );
              if (confirmed) await library.clearLibrary();
            },
          ),

          // ---------------------------------------------------- Acerca de
          _SectionTitle(AppLocalizations.of(context).aboutTitle),
          FutureBuilder<String>(
            future: AppInfoService.etiquetaVersion(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              final String version = snapshot.data ?? AppLocalizations.of(context).loading;
              final int? codigo = AppInfoService.codigoCache;
              final String? novedades =
                  codigo == null ? null : AppChangelog.forCode(codigo);
              return ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(version),
                  subtitle: Text(
                    '${AppLocalizations.of(context).aboutBody}\n'
                    '${AppLocalizations.of(context).aboutOffline}\n\n'
                    '${AppLocalizations.of(context).aboutWhatsNew} $novedades',
                  ),
                  isThreeLine: true,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Formatos: ${AudioFormats.supported.map((String e) => e.toUpperCase()).join(', ')}\n'
              'Las API keys se guardan cifradas con el Android Keystore.',
              style: TextStyle(fontSize: 12, color: AppColors.darkTextDim),
            ),
          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

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
                  tooltip: 'Obtener API key',
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: provider.keysUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enlace copiado: ${provider.keysUrl}')),
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
                  return ChoiceChip(
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
                                ? 'Clave de ${provider.label} eliminada'
                                : AppLocalizations.of(context).keyStoredFor(provider.label),
                          ),
                        ),
                      );
                    },
                    child: const Text('Guardar'),
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
                            if (!mounted) return;
                            setState(() => _testing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${provider.label}: ${ai.status}'
                                      : ai.lastError ?? 'Error de conexión',
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
                        : const Text('Probar'),
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
