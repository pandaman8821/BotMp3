import 'package:flutter/services.dart';
import 'package:flutter/animation.dart';

/// Duraciones y curvas unicas de la app: todo se mueve con la misma
/// "personalidad" y se puede apagar con "reducir movimiento".
class Motion {
  const Motion._();

  static const Duration rapido = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration lento = Duration(milliseconds: 320);
  static const Duration kenBurns = Duration(seconds: 20);

  static const Curve curva = Curves.easeOutCubic;
  static const Curve entrada = Curves.easeOutQuint;
  static const Curve salida = Curves.easeInCubic;

  /// Cuando es true, las animaciones decorativas se desactivan.
  static bool reducir = false;

  static Duration ajustar(Duration d) => reducir ? Duration.zero : d;
}

/// Vibraciones cortas y consistentes en toda la app.
class Hapticos {
  const Hapticos._();

  /// Toque ligero: cambiar de pestaña, elegir un chip, abrir un menu.
  static void toque() {
    HapticFeedback.selectionClick();
  }

  /// Accion con efecto: reproducir, pausar, borrar.
  static void accion() {
    HapticFeedback.lightImpact();
  }
}