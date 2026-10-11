import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';

/// Puente entre los proveedores (capa de estado) y el motor de acciones de IA
/// (capa de servicios), sin acoplar constructores ni crear dependencias
/// circulares en tiempo de compilación.
///
/// Cada proveedor se registra solo al construirse; el motor de acciones usa
/// [library], [player] y [settings] para ejecutar las órdenes.
class AiBridge {
  const AiBridge._();

  static LibraryProvider? library;
  static PlayerProvider? player;
  static SettingsProvider? settings;

  static bool get ready => library != null && player != null && settings != null;
}
