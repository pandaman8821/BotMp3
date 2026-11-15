import 'dart:async';

/// Fila de tareas asíncronas que se ejecutan DE UNA EN UNA y en el orden en
/// que se añadieron, aunque unas tarden más que otras.
///
/// La usa el chat de la IA para que cada respuesta llegue en el orden en que
/// se pidió. Si una tarea falla, el error se entrega a quien la pidió y la
/// fila sigue con la siguiente.
class FilaDeTareas {
  Future<void> _cola = Future<void>.value();
  int _pendientes = 0;

  /// Tareas añadidas que aún no han terminado (incluida la que está en curso).
  int get pendientes => _pendientes;

  /// Añade [tarea] al final de la fila y devuelve su resultado cuando termine.
  Future<T> agregar<T>(Future<T> Function() tarea) {
    final Completer<T> hecho = Completer<T>();
    _pendientes++;
    _cola = _cola.then((_) async {
      try {
        hecho.complete(await tarea());
      } catch (error, pila) {
        hecho.completeError(error, pila);
      } finally {
        _pendientes--;
      }
    });
    return hecho.future;
  }
}
