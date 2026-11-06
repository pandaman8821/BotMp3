import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/catalog.dart';
import '../core/theme/theme_manager.dart';
import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';

/// Selector de temas con vista previa de cada estilo.
///
/// - Aplica el tema en caliente (ThemeManager notifica y toda la app se repinta).
/// - Persiste la eleccion.
/// - Incluye el interruptor de "reducir movimiento" (accesibilidad).
class ThemePickerSection extends StatelessWidget {
  const ThemePickerSection({super.key});

  static const List<String> _claves = <String>[
    'themeMinimal',
    'themeNeon',
    'themeRetro',
    'themeGlass',
    'themeZen',
    'themeAnime',
    'themeGothic',
    'themeCinema',
  ];

  String _nombre(BuildContext context, int indice) {
    final AppLocalizations loc = AppLocalizations.of(context);
    switch (_claves[indice]) {
      case 'themeMinimal':
        return loc.themeMinimal;
      case 'themeNeon':
        return loc.themeNeon;
      case 'themeRetro':
        return loc.themeRetro;
      case 'themeGlass':
        return loc.themeGlass;
      case 'themeZen':
        return loc.themeZen;
      case 'themeAnime':
        return loc.themeAnime;
      case 'themeGothic':
        return loc.themeGothic;
      default:
        return loc.themeCinema;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeManager temas = context.watch<ThemeManager>();
    final AppLocalizations loc = AppLocalizations.of(context);
    final double ancho = (MediaQuery.sizeOf(context).width * 0.42).clamp(140.0, 190.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(loc.themeTitle, style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Text(loc.themeSubtitle, style: TextStyle(fontSize: 12, color: temas.tokens.textDim)),
        ),
        SizedBox(
          height: ancho * 0.66,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kThemes.length,
            itemBuilder: (BuildContext context, int i) {
              final BotTokens tokens = kThemes[i];
              final bool activo = tokens.id == temas.temaId;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: ancho,
                  child: _TarjetaTema(
                    tokens: tokens,
                    nombre: _nombre(context, i),
                    activo: activo,
                    onTap: () => temas.setTema(tokens.id),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          value: temas.reducirMovimiento,
          onChanged: temas.setReducirMovimiento,
          title: Text(loc.reduceMotion),
          subtitle: Text(loc.reduceMotionDesc, style: const TextStyle(fontSize: 12)),
          secondary: Icon(temas.reducirMovimiento ? Icons.motion_photos_off : Icons.motion_photos_on),
        ),
      ],
    );
  }
}

/// Vista previa del estilo: mini reproductor dibujado con sus tokens.
class _TarjetaTema extends StatelessWidget {
  const _TarjetaTema({
    required this.tokens,
    required this.nombre,
    required this.activo,
    required this.onTap,
  });

  final BotTokens tokens;
  final String nombre;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activo,
      label: nombre,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activo ? tokens.primary : tokens.outline,
              width: activo ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[tokens.background, tokens.surface],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(tokens.radius * 0.5),
                          gradient: tokens.coverFallback,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(height: 6, decoration: BoxDecoration(color: tokens.text.withAlpha(220), borderRadius: BorderRadius.circular(3))),
                            const SizedBox(height: 4),
                            Container(width: 44, height: 5, decoration: BoxDecoration(color: tokens.textDim, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(height: 6),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(color: tokens.primary, shape: BoxShape.circle),
                              child: Icon(Icons.play_arrow, size: 18, color: tokens.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: tokens.surfaceHigh,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activo ? tokens.primary : tokens.text,
                        ),
                      ),
                    ),
                    if (activo) Icon(Icons.check_circle, size: 14, color: tokens.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}