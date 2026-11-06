import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botmp3/core/theme/catalog.dart';
import 'package:botmp3/core/theme/theme_manager.dart';
import 'package:botmp3/core/theme/tokens.dart';

/// Contraste segun WCAG (ratio entre dos colores).
double _ratio(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double mayor = la > lb ? la : lb;
  final double menor = la > lb ? lb : la;
  return (mayor + 0.05) / (menor + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catalogo de temas', () {
    test('existen los 8 estilos y los ids son unicos', () {
      expect(kThemes.length, 8);
      final Set<String> ids = kThemes.map((BotTokens t) => t.id).toSet();
      expect(ids.length, kThemes.length);
      expect(ids, containsAll(<String>[
        'minimal', 'neon', 'retro', 'glass', 'zen', 'anime', 'gothic', 'cinema',
      ]));
    });

    test('themeById devuelve el tema o el de por defecto', () {
      expect(themeById('neon').id, 'neon');
      expect(themeById('no-existe').id, kDefaultThemeId);
      expect(themeById(null).id, kDefaultThemeId);
    });

    test('contraste de texto suficiente en los 8 temas (WCAG AA)', () {
      for (final BotTokens t in kThemes) {
        final double r = _ratio(t.text, t.background);
        expect(r, greaterThanOrEqualTo(4.5), reason: 'texto/${t.id} = $r');
        final double r2 = _ratio(t.textDim, t.background);
        expect(r2, greaterThanOrEqualTo(3.0), reason: 'textoDim/${t.id} = $r2');
        final double r3 = _ratio(t.onPrimary, t.primary);
        expect(r3, greaterThanOrEqualTo(2.5), reason: 'onPrimary/${t.id} = $r3');
      }
    });

    test('todos los temas generan un ThemeData valido', () {
      for (final BotTokens t in kThemes) {
        final ThemeData tema = t.materialTheme();
        expect(tema.useMaterial3, isTrue);
        expect(tema.colorScheme.primary, t.primary);
      }
    });
  });

  group('ThemeManager', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await ThemeManager.init();
    });

    test('cambia de tema en caliente y persiste la eleccion', () async {
      final ThemeManager g = ThemeManager.instance;
      await g.setTema('neon');
      expect(g.temaId, 'neon');
      expect(g.tokens.primary, const Color(0xFF00E5FF));
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getString(ThemeManager.kClaveTema), 'neon');
    });

    test('el tema guardado se recupera al reiniciar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{ThemeManager.kClaveTema: 'gothic'});
      await ThemeManager.init();
      expect(ThemeManager.instance.temaId, 'gothic');
      expect(ThemeManager.instance.tokens.id, 'gothic');
    });

    test('reducir movimiento pone las animaciones a cero', () async {
      final ThemeManager g = ThemeManager.instance;
      await g.setTema('zen');
      expect(g.motionMs, greaterThan(0));
      await g.setReducirMovimiento(true);
      expect(g.motionMs, 0);
      expect(g.duracion().inMilliseconds, 0);
      final SharedPreferences p = await SharedPreferences.getInstance();
      expect(p.getBool(ThemeManager.kClaveReducirMovimiento), isTrue);
    });

    test('el modo claro usa la variante clara cuando existe', () async {
      final ThemeManager g = ThemeManager.instance;
      await g.setTema('minimal');
      g.setModo(ThemeMode.light);
      expect(g.tokens.id, 'minimal');
      expect(g.tokens.dark, isFalse);
      g.setModo(ThemeMode.dark);
      expect(g.tokens.dark, isTrue);
      await g.setTema('neon');
      g.setModo(ThemeMode.light);
      expect(g.tokens.dark, isTrue, reason: 'neon no tiene variante clara');
    });
  });
}