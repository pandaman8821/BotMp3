import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/ai_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_shell.dart';
import 'services/settings_service.dart';

/// Raíz de la aplicación: inyecta los providers y aplica el tema.
class BotMp3App extends StatelessWidget {
  const BotMp3App({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(settings),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider()..init(),
        ),
        ChangeNotifierProvider<AiAssistantProvider>(
          create: (BuildContext context) => AiAssistantProvider(
            library: context.read<LibraryProvider>(),
          )..init(settings),
        ),
        ChangeNotifierProxyProvider<LibraryProvider, PlayerProvider>(
          create: (BuildContext context) => PlayerProvider(
            library: context.read<LibraryProvider>(),
            settings: settings,
          ),
          // Se mantiene la misma instancia para no cortar la reproducción
          // cuando cambia la biblioteca.
          update: (_, __, PlayerProvider? previous) =>
              previous ??
              PlayerProvider(
                library: context.read<LibraryProvider>(),
                settings: settings,
              ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (BuildContext context, SettingsProvider settingsProvider, _) {
          return MaterialApp(
            title: 'BotMp3',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: const Locale('es'),
            supportedLocales: const <Locale>[
              Locale('es'),
              Locale('en'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
