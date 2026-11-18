import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preset del ecualizador definido sobre 5 frecuencias de referencia; se
/// adapta a las bandas reales de cada teléfono (que pueden ser 5, 6, 10…).
class PresetEq {
  const PresetEq(this.id, this.ganancias);

  /// Identificador estable (se guarda y se traduce en la interfaz).
  final String id;

  /// Ganancia en dB a 63 Hz, 250 Hz, 1 kHz, 4 kHz y 16 kHz.
  final List<double> ganancias;
}

/// Ecualizador de BotMp3 sobre el motor de audio real.
///
/// Usa el `AndroidEqualizer` de just_audio, enganchado al propio reproductor:
/// actúa sobre la sesión de audio de ExoPlayer. El ecualizador nativo
/// anterior recibía la sesión 0 (just_audio_background no la expone) y en
/// Android 10+ eso no modifica el sonido de la app.
class Ecualizador extends ChangeNotifier {
  Ecualizador._();

  static final Ecualizador instance = Ecualizador._();

  /// Frecuencias de referencia de los presets (Hz).
  static const List<double> frecuenciasPreset = <double>[63, 250, 1000, 4000, 16000];

  static const List<PresetEq> presets = <PresetEq>[
    PresetEq('flat', <double>[0, 0, 0, 0, 0]),
    PresetEq('rock', <double>[5, 3, 0, 2, 4]),
    PresetEq('pop', <double>[-2, 1, 4, 3, -1]),
    PresetEq('jazz', <double>[3, 1, 0, 2, 2]),
    PresetEq('classical', <double>[2, 2, -1, 3, 4]),
    PresetEq('rap', <double>[6, 4, 0, 2, 2]),
    PresetEq('reggaeton', <double>[7, 5, 0, 3, 2]),
    PresetEq('cumbia', <double>[5, 3, 1, 2, 3]),
    PresetEq('electronic', <double>[6, 2, -1, 3, 5]),
    PresetEq('heavy', <double>[7, 4, -2, 4, 5]),
    PresetEq('vocal', <double>[-3, 0, 5, 4, 1]),
    PresetEq('bass', <double>[8, 6, 0, 0, 0]),
    PresetEq('treble', <double>[-1, 0, 1, 4, 6]),
  ];

  static const String _claveActivo = 'eq_activo';
  static const String _claveGanancias = 'eq_ganancias';
  static const String _clavePreset = 'eq_preset';

  /// Efecto que se inserta en el `AudioPipeline` del reproductor. Solo existe
  /// en Android (en otras plataformas es null y la pantalla lo indica).
  final AndroidEqualizer? efecto = !kIsWeb && Platform.isAndroid ? AndroidEqualizer() : null;

  AndroidEqualizerParameters? _parametros;
  bool _activo = false;
  String _preset = 'flat';
  List<double> _ganancias = <double>[];
  bool _iniciado = false;

  bool get disponible => efecto != null;

  /// El motor ya entregó las bandas reales (hace falta haber cargado audio).
  bool get listo => _parametros != null;

  bool get activo => _activo;

  /// Id del preset elegido o 'custom' si el usuario movió las bandas a mano.
  String get preset => _preset;

  double get minDb => _parametros?.minDecibels ?? -15;
  double get maxDb => _parametros?.maxDecibels ?? 15;

  /// Frecuencias centrales reales de las bandas (Hz).
  List<double> get frecuencias =>
      _parametros?.bands
          // Algunos motores informan en milihercios: se pasa a Hz.
          .map((AndroidEqualizerBand b) =>
              b.centerFrequency > 30000 ? b.centerFrequency / 1000 : b.centerFrequency)
          .toList() ??
      frecuenciasPreset;

  List<double> get ganancias => List<double>.unmodifiable(_ganancias);

  /// Carga lo guardado y, cuando el motor esté listo, lo aplica.
  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _activo = prefs.getBool(_claveActivo) ?? false;
    _preset = prefs.getString(_clavePreset) ?? 'flat';
    _ganancias = (prefs.getStringList(_claveGanancias) ?? const <String>[])
        .map((String v) => double.tryParse(v) ?? 0)
        .toList();
    notifyListeners();

    final AndroidEqualizer? eq = efecto;
    if (eq == null) return;
    try {
      // Se completa cuando el reproductor se conecta al motor nativo.
      _parametros = await eq.parameters;
    } catch (error) {
      debugPrint('Ecualizador no disponible: $error');
      return;
    }
    final int bandas = _parametros!.bands.length;
    if (_ganancias.length != bandas) {
      // Primera vez o teléfono con otro número de bandas: se rehace desde el preset.
      _ganancias = gananciasDePreset(
        presets.firstWhere((PresetEq p) => p.id == _preset, orElse: () => presets.first),
        frecuencias,
        minDb,
        maxDb,
      );
    }
    for (int i = 0; i < bandas; i++) {
      await _parametros!.bands[i].setGain(_ganancias[i]);
    }
    await eq.setEnabled(_activo);
    notifyListeners();
  }

  Future<void> setActivo(bool valor) async {
    _activo = valor;
    notifyListeners();
    await efecto?.setEnabled(valor);
    await _guardar();
  }

  /// Mueve una banda a mano (el preset pasa a "personalizado").
  Future<void> setBanda(int indice, double db) async {
    if (indice < 0 || indice >= _ganancias.length) return;
    _ganancias[indice] = db.clamp(minDb, maxDb);
    _preset = 'custom';
    notifyListeners();
    await _parametros?.bands[indice].setGain(_ganancias[indice]);
  }

  /// Guarda tras soltar el deslizador (no en cada movimiento).
  Future<void> confirmarBandas() => _guardar();

  Future<void> aplicarPreset(PresetEq p) async {
    _preset = p.id;
    _ganancias = gananciasDePreset(p, frecuencias, minDb, maxDb);
    if (!_activo) _activo = true; // Elegir un preset implica querer oírlo.
    notifyListeners();
    final AndroidEqualizerParameters? params = _parametros;
    if (params != null) {
      for (int i = 0; i < params.bands.length && i < _ganancias.length; i++) {
        await params.bands[i].setGain(_ganancias[i]);
      }
    }
    await efecto?.setEnabled(_activo);
    await _guardar();
  }

  Future<void> _guardar() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveActivo, _activo);
    await prefs.setString(_clavePreset, _preset);
    await prefs.setStringList(
      _claveGanancias,
      _ganancias.map((double g) => g.toStringAsFixed(2)).toList(),
    );
  }

  /// Adapta un preset de 5 puntos a las [frecuencias] reales del teléfono,
  /// interpolando en escala logarítmica (como se oye) y recortando al rango.
  @visibleForTesting
  static List<double> gananciasDePreset(
    PresetEq p,
    List<double> frecuencias,
    double minDb,
    double maxDb,
  ) {
    double logf(double f) => math.log(math.max(f, 1)) / math.ln10;
    final List<double> xs = frecuenciasPreset.map(logf).toList();
    return frecuencias.map((double f) {
      final double x = logf(f);
      double g;
      if (x <= xs.first) {
        g = p.ganancias.first;
      } else if (x >= xs.last) {
        g = p.ganancias.last;
      } else {
        int i = 0;
        while (x > xs[i + 1]) {
          i++;
        }
        final double t = (x - xs[i]) / (xs[i + 1] - xs[i]);
        g = p.ganancias[i] + (p.ganancias[i + 1] - p.ganancias[i]) * t;
      }
      return g.clamp(minDb, maxDb).toDouble();
    }).toList();
  }
}
