import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/motion.dart';
import 'core/theme.dart';
import 'core/theme/theme_backdrop.dart';
import 'core/theme/theme_manager.dart';
import 'providers/ai_provider.dart';
import 'providers/library_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/splash_gate.dart';
import 'services/settings_service.dart';

/// Raiz de la aplicacion: inyecta los providers y aplica el tema.
///
/// El tema es dinamico: [ThemeManager] notifica y este `Consumer` reconstruye
/// `MaterialApp`, por lo que el cambio de estilo se ve al instante (en caliente)
/// sin reiniciar la app ni tocar la reproduccion de audio.
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
        ChangeNotifierProvider<ThemeManager>.value(value: ThemeManager.instance),
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
          // Se mantiene la misma instancia para no cortar la reproduccion
          // cuando cambia la biblioteca.
          update: (_, __, PlayerProvider? previous) =>
              previous ??
              PlayerProvider(
                library: context.read<LibraryProvider>(),
                settings: settings,
              ),
        ),
      ],
      child: Consumer2<SettingsProvider, ThemeManager>(
        builder: (BuildContext context, SettingsProvider settingsProvider, ThemeManager temas, _) {
          // Sincroniza el modo claro/oscuro con el gestor de temas (no-op si ya
          // coincide) para que los temas con variante clara la respeten.
          temas.setModo(settingsProvider.themeMode);
          return MaterialApp(
            title: 'BotMp3',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            supportedLocales: AppLocalizations.supportedLocales,
            // Si el idioma del telefono no esta traducido, la app usa INGLES
            // (idioma universal) en lugar de caer al primero de la lista.
            localeResolutionCallback: (Locale? dispositivo, Iterable<Locale> soportados) {
              if (dispositivo == null) return const Locale('en');
              for (final Locale locale in soportados) {
                if (locale.languageCode == dispositivo.languageCode) return locale;
              }
              return const Locale('en');
            },
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Los formatos (fechas, numeros) siguen el idioma que se este usando.
            builder: (BuildContext context, Widget? child) {
              Intl.defaultLocale = Localizations.localeOf(context).toString();
              Motion.reducir = temas.reducirMovimiento;
              return ThemeBackdrop(child: child ?? const SizedBox.shrink());
            },
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}