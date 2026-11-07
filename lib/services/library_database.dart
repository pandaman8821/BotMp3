import 'package:sqflite/sqflite.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../core/formatters.dart';

/// Indice SQLite de la biblioteca (SOLO lectura rapida).
///
/// La fuente de verdad sigue siendo el JSON de la app: SQLite es una **copia
/// indexada** que acelera la busqueda con miles de canciones. Si algo falla,
/// se desactiva solo y la app sigue funcionando igual que antes.
class LibraryDatabase {
  const LibraryDatabase._();

  static Database? _db;
  static bool _disponible = false;
  static int _canciones = 0;
  static int _listas = 0;
  static String? _error;

  static bool get disponible => _disponible;
  static String? get error => _error;

  /// Texto para la pantalla de diagnostico.
  static String get estado {
    if (!_disponible) return _error == null ? 'SQLite: desactivado' : 'SQLite: no disponible ($_error)';
    return 'SQLite: activo · $_canciones canciones · $_listas listas';
  }

  /// Abre la base de datos y prepara el esquema.
  static Future<bool> iniciar() async {
    try {
      final String ruta = '${await getDatabasesPath()}/botmp3_indice.db';
      _db = await openDatabase(
        ruta,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE canciones(
              id TEXT PRIMARY KEY,
              titulo TEXT NOT NULL,
              artista TEXT NOT NULL,
              album TEXT NOT NULL,
              genero TEXT NOT NULL,
              anio INTEGER NOT NULL,
              duracion INTEGER NOT NULL,
              ruta TEXT NOT NULL,
              etiquetas TEXT NOT NULL,
              favorita INTEGER NOT NULL,
              reproducciones INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_titulo ON canciones(titulo)');
          await db.execute('CREATE INDEX idx_artista ON canciones(artista)');
          await db.execute('CREATE INDEX idx_album ON canciones(album)');
          await db.execute('CREATE TABLE listas(id TEXT PRIMARY KEY, nombre TEXT NOT NULL, total INTEGER NOT NULL)');
        },
      );
      _disponible = true;
      _error = null;
      return true;
    } catch (e) {
      _disponible = false;
      _error = '$e';
      return false;
    }
  }

  /// Reconstruye el indice completo (llamado cuando cambia la biblioteca).
  static Future<void> sincronizar(List<Song> canciones, List<Playlist> listas) async {
    final Database? db = _db;
    if (db == null) return;
    try {
      await db.transaction((Transaction txn) async {
        await txn.delete('canciones');
        final Batch batch = txn.batch();
        for (final Song s in canciones) {
          batch.insert('canciones', <String, Object?>{
            'id': s.id,
            'titulo': Formatters.normalize(s.title),
            'artista': Formatters.normalize(s.artist),
            'album': Formatters.normalize(s.album),
            'genero': Formatters.normalize(s.genre),
            'anio': s.year,
            'duracion': s.durationMs,
            'ruta': s.path,
            'etiquetas': Formatters.normalize(s.tags.join(' ')),
            'favorita': s.isFavorite ? 1 : 0,
            'reproducciones': s.playCount,
          });
        }
        await batch.commit(noResult: true);
        await txn.delete('listas');
        final Batch batchListas = txn.batch();
        for (final Playlist p in listas) {
          batchListas.insert('listas', <String, Object?>{
            'id': p.id,
            'nombre': Formatters.normalize(p.name),
            'total': p.songIds.length,
          });
        }
        await batchListas.commit(noResult: true);
      });
      _canciones = canciones.length;
      _listas = listas.length;
      _disponible = true;
      _error = null;
    } catch (e) {
      _disponible = false;
      _error = '$e';
    }
  }

  /// Candidatos para una busqueda (ids) usando el indice; null si no hay indice.
  static Future<List<String>?> buscarIds(String consulta, {int limite = 80}) async {
    final Database? db = _db;
    if (db == null || !_disponible) return null;
    final String q = Formatters.normalize(consulta).trim();
    if (q.isEmpty) return null;
    try {
      final String patron = '%$q%';
      final List<Map<String, Object?>> filas = await db.query(
        'canciones',
        columns: <String>['id'],
        where: 'titulo LIKE ? OR artista LIKE ? OR album LIKE ? OR genero LIKE ? OR etiquetas LIKE ?',
        whereArgs: <Object?>[patron, patron, patron, patron, patron],
        limit: limite,
      );
      return filas.map((Map<String, Object?> f) => f['id']! as String).toList();
    } catch (e) {
      _error = '$e';
      return null;
    }
  }
}