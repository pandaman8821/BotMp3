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
}