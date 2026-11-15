part of '../settings_screen.dart';

/// Acerca de, licencias y formatos.
mixin _SeccionAcerca on State<SettingsScreen> {
  GlobalKey _ancla(String nombre);

  List<Widget> _seccionAcerca(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      // ---------------------------------------------------- Acerca de
      _SectionTitle(AppLocalizations.of(context).aboutTitle, key: _ancla('acerca')),
      FutureBuilder<String>(
        future: AppInfoService.etiquetaVersion(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          final String version = snapshot.data ?? AppLocalizations.of(context).loading;
          final int? codigo = AppInfoService.codigoCache;
          final String? novedades =
              codigo == null
                  ? null
                  : (AppChangelog.forCode(codigo) ??
                      AppLocalizations.of(context).changelogLatest);
          return ListTile(
            leading: const Icon(Icons.info_outline),
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
      ListTile(
        leading: const Icon(Icons.article_outlined),
        title: Text(AppLocalizations.of(context).licensesTitle),
        subtitle: Text(AppLocalizations.of(context).gplNotice),
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'BotMp3',
          applicationVersion: AppInfoService.nombreCache ?? '',
          applicationLegalese: 'GPL-3.0 License (c) 2026 BotMp3',
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '${AppLocalizations.of(context).formatsLabel(AudioFormats.supported.map((String e) => e.toUpperCase()).join(', '))}\n'
          '${AppLocalizations.of(context).apiKeysKeystoreNotice}',
          style: TextStyle(fontSize: 12, color: AppColors.darkTextDim),
        ),
      ),
    ];
  }
}
