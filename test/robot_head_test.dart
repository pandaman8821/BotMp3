import 'package:botmp3/widgets/modern_app_bar.dart';
import 'package:botmp3/widgets/robot_head.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget hijo) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: hijo)),
    );

void main() {
  testWidgets('La cabeza de robot se dibuja y anima, con y sin música', (WidgetTester tester) async {
    for (final bool sonando in <bool>[false, true]) {
      await tester.pumpWidget(_envolver(CabezaRobot(tamano: 32, sonando: sonando)));
      // Varios momentos del ciclo, incluido el parpadeo (~90 % del ciclo).
      for (int ms = 0; ms <= 4000; ms += 400) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byType(CabezaRobot), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Los botones animados responden al toque y no fallan al animarse',
      (WidgetTester tester) async {
    int toques = 0;
    await tester.pumpWidget(
      _envolver(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final AnimacionIcono a in AnimacionIcono.values)
              BotonAccion(
                icono: Icons.star_rounded,
                tooltip: a.name,
                animacion: a,
                orden: a.index,
                onPressed: () => toques++,
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle(); // entrada en cascada
    for (final AnimacionIcono a in AnimacionIcono.values) {
      await tester.tap(find.byTooltip(a.name));
      await tester.pump(const Duration(milliseconds: 200)); // a mitad de animación
    }
    await tester.pumpAndSettle();
    expect(toques, AnimacionIcono.values.length);
    expect(tester.takeException(), isNull);
  });
}
