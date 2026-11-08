import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Marcadores (bookmarks) dentro de una cancion.
///
/// Se guardan por id de cancion en SharedPreferences: no toca los metadatos ni
/// los archivos, y si algo falla la reproduccion sigue igual.
class BookmarksService {
  BookmarksService._();

  static BookmarksService? _instancia;

  static BookmarksService get instance => _instancia ??= BookmarksService._();

  static const String _clave = 'marcadores_canciones';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _ajustes async => _prefs ??= await SharedPreferences.getInstance();

  Future<Map<String, List<int>>> _todo() async {
    final SharedPreferences p = await _ajustes;
    final String? crudo = p.getString(_clave);
    if (crudo == null || crudo.isEmpty) return <String, List<int>>{};
    try {
      final Map<String, dynamic> mapa = jsonDecode(crudo) as Map<String, dynamic>;
      return mapa.map((String k, dynamic v) => MapEntry<String, List<int>>(
            k,
            (v as List<dynamic>).map((dynamic e) => (e as num).toInt()).toList(),
          ));
    } catch (_) {
      return <String, List<int>>{};
    }
  }

  Future<void> _guardar(Map<String, List<int>> mapa) async {
    final SharedPreferences p = await _ajustes;
    await p.setString(_clave, jsonEncode(mapa));
  }

  /// Marcadores de una cancion, ordenados.
  Future<List<Duration>> de(String songId) async {
    final Map<String, List<int>> mapa = await _todo();
    final List<int> ms = List<int>.from(mapa[songId] ?? const <int>[]);
    ms.sort();
    return ms.map((int v) => Duration(milliseconds: v)).toList();
  }

  /// Agrega un marcador (ignora duplicados a menos de 1 segundo).
  Future<void> agregar(String songId, Duration posicion) async {
    final Map<String, List<int>> mapa = await _todo();
    final List<int> lista = List<int>.from(mapa[songId] ?? const <int>[]);
    final int ms = posicion.inMilliseconds;
    if (lista.any((int v) => (v - ms).abs() < 1000)) return;
    lista.add(ms);
    lista.sort();
    mapa[songId] = lista;
    await _guardar(mapa);
  }

  Future<void> quitar(String songId, Duration posicion) async {
    final Map<String, List<int>> mapa = await _todo();
    final List<int> lista = List<int>.from(mapa[songId] ?? const <int>[]);
    lista.removeWhere((int v) => (v - posicion.inMilliseconds).abs() < 1000);
    if (lista.isEmpty) {
      mapa.remove(songId);
    } else {
      mapa[songId] = lista;
    }
    await _guardar(mapa);
  }

  Future<void> limpiar(String songId) async {
    final Map<String, List<int>> mapa = await _todo();
    mapa.remove(songId);
    await _guardar(mapa);
  }
}