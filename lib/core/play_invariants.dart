import '../models/song.dart';

/// Reglas puras que protegen la reproducción.
///
/// Viven aquí, separadas del motor de audio, para poder comprobarlas con tests
/// automáticos: los fallos que aparecieron (parpadeo de la primera canción,
/// doble recuento en el ranking, índices descuadrados) fueron justo por no
/// tener estas reglas aisladas y verificadas.
class PlayInvariants {
  const PlayInvariants._();

  /// Canciones reproducibles de verdad (con ruta). La cola SIEMPRE se monta con
  /// esto: si se filtra más tarde, los índices de la cola y los de las fuentes
  /// del reproductor dejan de coincidir y se marca/controla la canción errónea.
  static List<Song> conFuenteUtilizable(List<Song> songs) =>
      songs.where((Song s) => s.path.trim().isNotEmpty).toList();

  /// Índice válido para una posición pedida dentro de [total] canciones.
  static int indiceValido(int pedido, int total) {
    if (total <= 0) return -1;
    if (pedido < 0) return 0;
    if (pedido >= total) return total - 1;
    return pedido;
  }

  /// Un índice que llega del motor solo se aplica si es el que se pidió mientras
  /// haya uno esperando. Cualquier otro es ruido de la carga (el 0 inicial) y
  /// pintarlo era lo que hacía parpadear en verde la primera canción.
  static bool aceptarIndice({required int? esperado, required int recibido}) {
    if (esperado == null) return true;
    return esperado == recibido;
  }

  /// Recuento del ranking: una vez, a los 20 s reales, solo si sigue sonando la
  /// misma canción y esa canción no estaba ya registrada.
  static bool debeContar({
    required bool suena,
    required int indiceActual,
    required int indiceContado,
    required String? ultimaRegistrada,
    required String id,
  }) {
    if (!suena) return false;
    if (indiceActual != indiceContado) return false;
    if (ultimaRegistrada == id) return false;
    return true;
  }
}