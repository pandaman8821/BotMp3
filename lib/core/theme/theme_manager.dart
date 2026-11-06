import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'tokens.dart';

/// Gestor central de temas de BotMp3.
///
/// - Mantiene el estilo elegido, el modo claro/oscuro y la reduccion de
///   movimiento.
/// - Persiste todo en SharedPreferences.
/// - Notifica a la app para que el cambio se aplique EN CALIENTE (sin reiniciar).
/// - Es un singleton: [AppColors] y [BotTokens.materialTheme] lo consultan.
class ThemeManager extends ChangeNotifier {
  ThemeManager._(this._prefs) {
    _cargar();
  }

  static ThemeManager? _instancia;

  /// Instancia global (se crea sin persistencia si no se llamo a [init]).
  static ThemeManager get instance => _instancia ??= ThemeManager._(null);

  final SharedPreferences? _prefs;

  static const String kClaveTema = 'tema_id';
  static const String kClaveReducirMovimiento = 'reducir_movimiento';

  BotTokens _base = themeById(kDefaultThemeId);
  String _id = kDefaultThemeId;
  bool _reducirMovimiento = false;
  ThemeMode _modo = ThemeMode.dark;

  String get temaId => _id;

  /// Tokens ya resueltos segun el modo claro/oscuro y la reduccion de movimiento.
  BotTokens get tokens => _tokens;

  ThemeMode get modo => _modo;
  bool get reducirMovimiento => _reducirMovimiento;

  /// Duracion base de las animaciones del tema (0 = movimiento reducido).
  int get motionMs => _reducirMovimiento ? 0 : tokens.motionMs;

  /// Inicializa el gestor leyendo lo guardado. Llamar una vez en `main()`.
  static Future<ThemeManager> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ThemeManager gestor = ThemeManager._(prefs);
    _instancia = gestor;
    return gestor;
  }

  void _cargar() {
    final SharedPreferences? p = _prefs;
    _id = p?.getString(kClaveTema) ?? kDefaultThemeId;
    _reducirMovimiento = p?.getBool(kClaveReducirMovimiento) ?? false;
    _base = themeById(_id);
    _recalcular();
  }

  BotTokens _resolver(BotTokens base) {
    final BotTokens? alterno = base.light;
    if (alterno == null) return base;
    bool claro;
    switch (_modo) {
      case ThemeMode.light:
        claro = true;
      case ThemeMode.dark:
        claro = false;
      case ThemeMode.system:
        claro = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
    }
    return claro ? alterno : base;
  }

  BotTokens _tokens = themeById(kDefaultThemeId);

  void _recalcular() {
    _tokens = _resolver(_base);
  }

  /// Cambia el tema (aplica al instante y guarda).
  Future<void> setTema(String id) async {
    final BotTokens nuevo = themeById(id);
    if (nuevo.id == _id && _base.id == nuevo.id) return;
    _id = nuevo.id;
    _base = nuevo;
    _recalcular();
    notifyListeners();
    await _prefs?.setString(kClaveTema, _id);
  }

  /// Activa/desactiva las animaciones del tema (accesibilidad).
  Future<void> setReducirMovimiento(bool valor) async {
    if (_reducirMovimiento == valor) return;
    _reducirMovimiento = valor;
    notifyListeners();
    await _prefs?.setBool(kClaveReducirMovimiento, valor);
  }

  /// Modo claro/oscuro del sistema (solo afecta a los temas que tienen variante).
  void setModo(ThemeMode modo) {
    if (_modo == modo) return;
    _modo = modo;
    _recalcular();
  }

  /// Cuanto dura una animacion de tema respetando la accesibilidad.
  Duration duracion([double factor = 1]) =>
      Duration(milliseconds: (motionMs * factor).round());
}