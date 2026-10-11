import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botmp3/widgets/glass.dart';

/// Comprueba en tiempo de ejecución que el sistema de cristal se construye y se
/// comporta correctamente (esto detecta errores de layout que el análisis
/// estático no ve, como restricciones sin límite o `BackdropFilter` sin padre).
void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              Container(color: const Color(0xFF7C4DFF)),
              Center(child: child),
            ],
          ),
        ),
      );

  const List<GlassNavDestination> destinations = <GlassNavDestination>[
    GlassNavDestination(
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: 'Canciones',
    ),
    GlassNavDestination(
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      label: 'Listas',
    ),
    GlassNavDestination(icon: Icons.search, selectedIcon: Icons.saved_search, label: 'Buscar'),
    GlassNavDestination(
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      label: 'IA',
    ),
    GlassNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Ajustes',
    ),
  ];

  testWidgets('GlassSurface se renderiza en todas las calidades', (WidgetTester tester) async {
    for (final GlassQuality quality in GlassQuality.values) {
      await tester.pumpWidget(
        wrap(
          GlassSurface(
            quality: quality,
            child: const Text('hola'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('hola'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('GlassChip responde al toque', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      wrap(GlassChip(label: 'pon cumbia', icon: Icons.play_arrow, onTap: () => taps++)),
    );
    await tester.tap(find.text('pon cumbia'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(taps, 1);
  });

  /// Prueba clave del fallo reportado: el indicador debe ANIMARSE al entrar en
  /// cualquiera de las pestañas, no saltar de golpe.
  testWidgets('El indicador anima en TODAS las pestañas (no salta)',
      (WidgetTester tester) async {
    int index = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          bottomNavigationBar: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => GlassNavBar(
              index: index,
              quality: GlassQuality.standard,
              onChanged: (int value) => setState(() => index = value),
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    double indicatorX() => tester
        .getTopLeft(find.byKey(const ValueKey<String>('glass-nav-indicator')))
        .dx;

    final String startLabel = destinations[index].label;
    for (int target = 0; target < destinations.length; target++) {
      if (target != index) {
        final double before = indicatorX();
        await tester.tap(find.text(destinations[target].label));
        await tester.pump(); // arranca la animación
        await tester.pump(const Duration(milliseconds: 90));
        final double mid = indicatorX();
        await tester.pumpAndSettle();
        final double end = indicatorX();

        expect((mid - before).abs(), greaterThan(1.0),
            reason: 'Al ir a "${destinations[target].label}" el indicador no arrancó');
        expect((mid - end).abs(), greaterThan(0.5),
            reason: 'Al ir a "${destinations[target].label}" el indicador saltó sin '
                'animación (ya estaba en el destino a los 90 ms)');
        expect(index, target);
      }
    }

    // Vuelve a la primera pestaña y comprueba que también anima al volver.
    final double beforeReturn = indicatorX();
    await tester.tap(find.text(startLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final double midReturn = indicatorX();
    await tester.pumpAndSettle();
    expect((midReturn - beforeReturn).abs(), greaterThan(1.0),
        reason: 'Al volver a "$startLabel" el indicador no arrancó');
    expect(index, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calidades coherentes con la intensidad', (WidgetTester tester) async {
    expect(glassQualityFor(enabled: false, intensity: 1), GlassQuality.off);
    expect(glassQualityFor(enabled: true, intensity: 1, batterySaver: true), GlassQuality.off);
    expect(glassQualityFor(enabled: true, intensity: 0.3), GlassQuality.light);
    expect(glassQualityFor(enabled: true, intensity: 0.7), GlassQuality.standard);
    expect(glassQualityFor(enabled: true, intensity: 1), GlassQuality.high);
  });
}
