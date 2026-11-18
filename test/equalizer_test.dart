import 'package:botmp3/services/equalizer_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los presets se definen sobre 5 frecuencias, pero cada teléfono tiene sus
/// propias bandas: estas pruebas fijan cómo se adaptan.
void main() {
  final PresetEq rock = Ecualizador.presets.firstWhere((PresetEq p) => p.id == 'rock');

  test('Con las mismas 5 frecuencias, el preset se aplica tal cual', () {
    expect(
      Ecualizador.gananciasDePreset(rock, Ecualizador.frecuenciasPreset, -15, 15),
      rock.ganancias,
    );
  });

  test('Con 5 bandas típicas de Android (60 Hz…14 kHz) queda muy cerca del preset', () {
    final List<double> g = Ecualizador.gananciasDePreset(
      rock,
      <double>[60, 230, 910, 3600, 14000],
      -15,
      15,
    );
    expect(g.length, 5);
    for (int i = 0; i < 5; i++) {
      expect((g[i] - rock.ganancias[i]).abs(), lessThan(1.0));
    }
  });

  test('Con 10 bandas interpola entre puntos vecinos y extiende los extremos', () {
    final List<double> g = Ecualizador.gananciasDePreset(
      rock,
      <double>[31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
      -15,
      15,
    );
    expect(g.length, 10);
    expect(g.first, rock.ganancias.first); // por debajo de 63 Hz: igual que 63 Hz
    expect(g[3], closeTo(3, 0.01)); // 250 Hz exacto
    // 500 Hz queda entre 250 Hz (+3) y 1 kHz (0): a medio camino en escala log.
    expect(g[4], closeTo(1.5, 0.01));
  });

  test('Nunca supera el rango que admite el teléfono', () {
    final PresetEq bajos = Ecualizador.presets.firstWhere((PresetEq p) => p.id == 'bass');
    final List<double> g =
        Ecualizador.gananciasDePreset(bajos, Ecualizador.frecuenciasPreset, -3, 3);
    expect(g.every((double v) => v >= -3 && v <= 3), isTrue);
  });

  test('Hay 13 estilos con id único y 5 valores cada uno', () {
    expect(Ecualizador.presets.length, 13);
    expect(Ecualizador.presets.map((PresetEq p) => p.id).toSet().length, 13);
    expect(Ecualizador.presets.every((PresetEq p) => p.ganancias.length == 5), isTrue);
  });
}
