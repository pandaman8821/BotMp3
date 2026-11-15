import 'package:botmp3/core/fila_tareas.dart';
import 'package:flutter_test/flutter_test.dart';

/// El chat de la IA se mezclaba porque cada respuesta se añadía cuando
/// llegaba. La fila garantiza que se atienden en el orden en que se pidieron.
void main() {
  test('Las tareas terminan en el orden en que se pidieron aunque tarden distinto', () async {
    final FilaDeTareas fila = FilaDeTareas();
    final List<String> terminadas = <String>[];

    // La primera es la más lenta: sin fila, terminaría la última.
    final List<Future<String>> pedidos = <Future<String>>[
      fila.agregar(() async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
        terminadas.add('A');
        return 'A';
      }),
      fila.agregar(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        terminadas.add('B');
        return 'B';
      }),
      fila.agregar(() async {
        terminadas.add('C');
        return 'C';
      }),
    ];
    expect(fila.pendientes, 3);

    expect(await Future.wait(pedidos), <String>['A', 'B', 'C']);
    expect(terminadas, <String>['A', 'B', 'C']);
    expect(fila.pendientes, 0);
  });

  test('Nunca se ejecutan dos tareas a la vez', () async {
    final FilaDeTareas fila = FilaDeTareas();
    int enCurso = 0;
    int maximo = 0;
    Future<void> tarea() async {
      enCurso++;
      if (enCurso > maximo) maximo = enCurso;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      enCurso--;
    }

    await Future.wait(<Future<void>>[for (int i = 0; i < 5; i++) fila.agregar(tarea)]);
    expect(maximo, 1);
  });

  test('Si una tarea falla, su error llega a quien la pidió y la fila sigue', () async {
    final FilaDeTareas fila = FilaDeTareas();
    final List<String> orden = <String>[];

    final Future<void> falla = fila.agregar<void>(() async {
      orden.add('falla');
      throw StateError('sin conexión');
    });
    final Future<String> siguiente = fila.agregar(() async {
      orden.add('siguiente');
      return 'ok';
    });

    await expectLater(falla, throwsA(isA<StateError>()));
    expect(await siguiente, 'ok');
    expect(orden, <String>['falla', 'siguiente']);
  });
}
