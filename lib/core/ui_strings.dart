import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Acceso a los textos traducidos desde sitios SIN BuildContext
/// (servicios, modelos y utilidades).
///
/// Usa el idioma activo que la app guarda en `Intl.defaultLocale`.
class UiStrings {
  const UiStrings._();

  static AppLocalizations get loc {
    final String? codigo = Intl.defaultLocale;
    if (codigo == null || codigo.isEmpty) return lookupAppLocalizations(const Locale('en'));
    final List<String> partes = codigo.replaceAll('_', '-').split('-');
    try {
      if (partes.length > 1) return lookupAppLocalizations(Locale(partes[0], partes[1]));
      return lookupAppLocalizations(Locale(partes[0]));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Nombre del idioma activo EN INGLES (lo usan las instrucciones de la IA).
  static String get languageName {
    const Map<String, String> nombres = <String, String>{
      'en': 'English',
      'es': 'Spanish',
      'pt': 'Portuguese',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'de': 'German',
      'fr': 'French',
      'it': 'Italian',
      'hi': 'Hindi',
    };
    final String code = (Intl.defaultLocale ?? 'en').replaceAll('_', '-').toLowerCase();
    final String base = code.split('-').first;
    return nombres[base] ?? 'English';
  }
}
