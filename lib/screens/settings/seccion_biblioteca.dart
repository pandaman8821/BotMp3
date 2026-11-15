part of '../settings_screen.dart';

/// Biblioteca: copias, importar/exportar, escaneo y limpieza.
mixin _SeccionBiblioteca on State<SettingsScreen> {
  GlobalKey _ancla(String nombre);

  List<Widget> _seccionBiblioteca(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      _SectionTitle(AppLocalizations.of(context).secLibrary, key: _ancla('biblioteca')),
      ListTile(
        leading: const Icon(Icons.save_alt),
        title: Text(AppLocalizations.of(context).backupToFolder),
        subtitle: Text(AppLocalizations.of(context).backupToFolderDesc),
        onTap: () async {
          final String json = library.exportLibraryJson();
          final DateTime hoy = DateTime.now();
          final String nombre =
              'botmp3_backup_${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}.json';
          final String? ruta = await MediaImporter.exportText(nombre, json);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ruta == null
                    ? AppLocalizations.of(context).exportCancelled
                    : AppLocalizations.of(context).backupSavedTo(ruta),
              ),
            ),
          );
        },
      ),
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
                    ? AppLocalizations.of(context).importMediaYes
                    : AppLocalizations.of(context).importMediaNo,
              ),
            ),
          );
        },
        title: Text(AppLocalizations.of(context).importAppAudio),
        subtitle: Text(AppLocalizations.of(context).subImportAppAudio),
      ),
      ListTile(
        leading: library.isScanning
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        title: Text(AppLocalizations.of(context).scanNow),
        subtitle: Text(library.scanMessage ?? AppLocalizations.of(context).scanNowDesc),
        onTap: () async {
          final int added = await library.autoScan(force: true);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                added == 0
                    ? 'No hay canciones nuevas'
                    : AppLocalizations.of(context).songsAddedCount('$added'),
              ),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings_backup_restore),
        title: Text(AppLocalizations.of(context).restoreBackup),
        subtitle: Text(AppLocalizations.of(context).subRestoreBackup),
        trailing: const Icon(Icons.chevron_right),
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
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogo).pop(true),
                  child: Text(AppLocalizations.of(context).restoreBtn),
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
        leading: const Icon(Icons.file_download_outlined),
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
                ruta == null ? AppLocalizations.of(context).exportCancelled : 'Copia exportada ✅',
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
        leading: const Icon(Icons.graphic_eq),
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
        leading: const Icon(Icons.auto_awesome),
        title: Text(AppLocalizations.of(context).tagWithAi),
        subtitle: Text(
          AppLocalizations.of(context).tagAiDesc,
        ),
        trailing: const Icon(Icons.chevron_right),
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
                    ? AppLocalizations.of(context).aiNoGenresReturned
                    : '$hechas canciones etiquetadas con IA ✨',
              ),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.auto_fix_high_outlined),
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
                    ? AppLocalizations.of(context).noGenresToFill
                    : '$cambiadas canciones etiquetadas 🏷️',
              ),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.backup_outlined),
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
                      ? AppLocalizations.of(context).backupSuccess
                      : AppLocalizations.of(context).backupError,
                ),
              ),
            );
          },
          child: Text(AppLocalizations.of(context).copyBtn),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.cleaning_services_outlined),
        title: Text(AppLocalizations.of(context).freeUpSpace),
        subtitle: FutureBuilder<int>(
          future: library.cacheBytes(),
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            final String detail = snapshot.hasData
                ? AppLocalizations.of(context).cacheDetail(Formatters.bytes(snapshot.data!))
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
                      ? AppLocalizations.of(context).freedSpaceSuccess(Formatters.bytes(freed))
                      : AppLocalizations.of(context).scanNothingToFree,
                ),
              ),
            );
          },
          child: Text(AppLocalizations.of(context).cleanBtn),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.library_add),
        title: Text(AppLocalizations.of(context).importSongs),
        subtitle: Text(AppLocalizations.of(context).importFormatsDesc),
        onTap: () => AppDialogs.importSongs(context),
      ),
      ListTile(
        leading: const Icon(Icons.folder_open),
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
        subtitle: Text(AppLocalizations.of(context).exportSummary(library.songs.length, library.playlists.length)),
        onTap: () async {
          final String json = library.exportLibraryJson();
          final String? path =
              await MediaImporter.exportText('botmp3_biblioteca.json', json);
          await Clipboard.setData(ClipboardData(text: json));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  path == null ? AppLocalizations.of(context).jsonCopiedClipboard : AppLocalizations.of(context).exportSuccessClipboard,
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
              SnackBar(content: Text(AppLocalizations.of(context).songsRestored(added))),
            );
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
        title: Text(AppLocalizations.of(context).deleteLocalLibrary, style: const TextStyle(color: Colors.redAccent)),
        subtitle: Text(AppLocalizations.of(context).noAudioDeleted),
        onTap: () async {
          final bool confirmed = await AppDialogs.confirm(
            context,
            title: AppLocalizations.of(context).deleteLibraryTitle,
            message: AppLocalizations.of(context).clearAllWarning,
            confirmLabel: AppLocalizations.of(context).deleteAllBtn,
          );
          if (confirmed) await library.clearLibrary();
        },
      ),
    ];
  }
}
