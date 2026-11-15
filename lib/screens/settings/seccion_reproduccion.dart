part of '../settings_screen.dart';

/// Reproducción, rendimiento y voz.
mixin _SeccionesReproduccion on State<SettingsScreen> {
  GlobalKey _ancla(String nombre);

  List<Widget> _seccionReproduccion(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      // ---------------------------------------------------- Reproducción
      _SectionTitle(AppLocalizations.of(context).secPlayback, key: _ancla('reproduccion')),
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
          _SectionTitle(AppLocalizations.of(context).secPerformance, key: _ancla('rendimiento')),
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
    ];
  }

  List<Widget> _seccionVoz(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      // ---------------------------------------------------- Voz
      _SectionTitle(AppLocalizations.of(context).secVoice, key: _ancla('voz')),
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
              AppLocalizations.of(context).voiceGreeting,
              locale: settings.voiceLocale,
            );
          },
          icon: const Icon(Icons.record_voice_over),
          label: Text(AppLocalizations.of(context).testVoice),
        ),
      ),
    ];
  }
}
