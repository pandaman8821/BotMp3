part of '../settings_screen.dart';

/// Tendencias, apariencia (tema y cristal) e IA.
mixin _SeccionesGenerales on State<SettingsScreen> {
  GlobalKey _ancla(String nombre);

  List<Widget> _seccionTendencias(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      // ---------------------------------------------------- Apariencia
      _SectionTitle(AppLocalizations.of(context).trendsTitle, key: _ancla('tendencias')),
      ListTile(
        leading: const Icon(Icons.public),
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
        leading: const Icon(Icons.schedule),
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
                    ? AppLocalizations.of(context).trendsAlertAt('${settings.trendsHour}')
                    : 'Avisos de tendencias desactivados',
              ),
            ),
          );
        },
        secondary: const Icon(Icons.notifications_active_outlined),
        title: Text(AppLocalizations.of(context).notifyTrends),
        subtitle: Text(AppLocalizations.of(context).subTrendsNotify),
      ),
      ListTile(
        leading: const Icon(Icons.local_fire_department_outlined),
        title: Text(AppLocalizations.of(context).trendsNow),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TrendsScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.health_and_safety_outlined),
        title: Text(AppLocalizations.of(context).playbackDiagnostics),
        subtitle: Text(AppLocalizations.of(context).subDiagnostics),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DiagnosticsScreen()),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.leaderboard_outlined),
        title: Text(AppLocalizations.of(context).seeMyRanking),
        subtitle: Text(AppLocalizations.of(context).subRanking),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RankingScreen()),
        ),
      ),
    ];
  }

  List<Widget> _seccionApariencia(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      _SectionTitle(AppLocalizations.of(context).secAppearance, key: _ancla('apariencia')),
          const ThemePickerSection(),
      ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(AppLocalizations.of(context).lockControlsTitle),
        subtitle: Text(AppLocalizations.of(context).subLockControls),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      SwitchListTile(
        value: settings.glassEnabled,
        onChanged: (bool value) => settings.setGlassEnabled(value),
        secondary: const Icon(Icons.blur_on),
        title: Text(AppLocalizations.of(context).glassEffect),
        subtitle: Text(
          AppLocalizations.of(context).glassDesc,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.opacity),
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
    ];
  }

  List<Widget> _seccionIa(BuildContext context, SettingsProvider settings, AiAssistantProvider ai, LibraryProvider library) {
    return <Widget>[
      // ---------------------------------------------------- IA
      _SectionTitle(AppLocalizations.of(context).secAi, key: _ancla('ia')),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    ];
  }
}
