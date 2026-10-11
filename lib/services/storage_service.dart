import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

/// Acceso al sistema de archivos de la app: JSON de biblioteca/ajustes,
/// canciones importadas y carátulas editadas.
///
/// Todo es local (modo offline total): nothing sale del dispositivo salvo las
/// peticiones explícitas a las APIs de IA.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Directory? _documentsCache;

  Future<Directory> documents() async {
    final Directory? cached = _documentsCache;
    if (cached != null) return cached;
    final Directory dir = await getApplicationDocumentsDirectory();
    _documentsCache = dir;
    return dir;
  }

  Future<File> _file(String name) async {
    final Directory dir = await documents();
    return File('${dir.path}/$name');
  }

  Future<Map<String, dynamic>?> readJsonMap(String name) async {
    try {
      final File file = await _file(name);
      if (!file.existsSync()) return null;
      final String raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>?> readJsonList(String name) async {
    try {
      final File file = await _file(name);
      if (!file.existsSync()) return null;
      final String raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      return decoded is List<dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String name, Object data) async {
    final File file = await _file(name);
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Guarda un archivo importado cuando el selector devuelve bytes en vez de ruta
  /// (habitual con proveedores en la nube o content:// en Android 13+).
  Future<String> saveImportedFile(String fileName, Uint8List bytes) async {
    final Directory docs = await documents();
    final Directory target = Directory('${docs.path}/${StorageKeys.importedDir}');
    if (!target.existsSync()) await target.create(recursive: true);
    final File file = File('${target.path}/${_sanitize(fileName)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Carpeta de carátulas (se guardan como JPG/PNG editados).
  Future<Directory> coversDirectory() async {
    final Directory docs = await documents();
    final Directory covers = Directory('${docs.path}/${StorageKeys.coversDir}');
    if (!covers.existsSync()) await covers.create(recursive: true);
    return covers;
  }

  Future<String> saveCoverBytes(String songId, Uint8List bytes, {bool png = false}) async {
    // Cada edición reemplaza la carátula anterior (evita acumular archivos).
    await deleteCoversOf(songId);
    final Directory covers = await coversDirectory();
    final String name = 'cover_${_sanitize(songId)}_${DateTime.now().millisecondsSinceEpoch}.${png ? 'png' : 'jpg'}';
    final File file = File('${covers.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Carpeta permanente donde se guardan las copias de audio importadas.
  /// No es caché: Android no puede borrarla por su cuenta.
  Future<Directory> importedDirectory() async {
    final Directory docs = await documents();
    final Directory target = Directory('${docs.path}/${StorageKeys.importedDir}');
    if (!target.existsSync()) await target.create(recursive: true);
    return target;
  }

  /// Mueve un archivo de la caché del selector a la carpeta permanente de la app.
  /// Si el renombrado no es posible (otro volumen), copia y borra el original.
  Future<String> moveImportedFile(String sourcePath, String fileName) async {
    final Directory target = await importedDirectory();
    final File source = File(sourcePath);
    final File destination = File('${target.path}/${_sanitize(fileName)}');
    if (source.path == destination.path) return source.path;
    try {
      if (destination.existsSync()) await destination.delete();
      await source.rename(destination.path);
      return destination.path;
    } catch (_) {
      try {
        final File moved = await source.copy(destination.path);
        try {
          await source.delete();
        } catch (_) {}
        return moved.path;
      } catch (error) {
        debugPrint('No se pudo mover $sourcePath: $error');
        return sourcePath;
      }
    }
  }

  /// Tamaño total en bytes de un directorio (recursivo).
  Future<int> directorySize(Directory directory) async {
    if (!directory.existsSync()) return 0;
    int total = 0;
    await for (final FileSystemEntity entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  /// Carpeta raíz de la caché de la app.
  Future<Directory> cacheRoot() async => getTemporaryDirectory();

  /// Bytes que ocupa la caché de la app (carátulas temporales, restos del selector…).
  Future<int> cacheSize() async {
    try {
      return await directorySize(await getTemporaryDirectory());
    } catch (_) {
      return 0;
    }
  }

  /// Borra de la caché todo lo que se puede regenerar o volver a importar.
  /// [protectedPaths] contiene las rutas de canciones EN USO: nunca se tocan.
  /// Devuelve los bytes liberados.
  Future<int> clearRegenerableCache({
    Set<String> protectedPaths = const <String>{},
  }) async {
    int freed = 0;
    try {
      final Directory cache = await getTemporaryDirectory();
      if (!cache.existsSync()) return 0;
      final List<FileSystemEntity> entities =
          cache.listSync(recursive: true, followLinks: false);
      for (final FileSystemEntity entity in entities) {
        if (entity is! File) continue;
        if (protectedPaths.contains(entity.path)) continue;
        try {
          final int size = await entity.length();
          await entity.delete();
          freed += size;
        } catch (_) {}
      }
      for (final FileSystemEntity entity in entities.reversed) {
        if (entity is Directory && entity.existsSync()) {
          try {
            if (entity.listSync().isEmpty) await entity.delete();
          } catch (_) {}
        }
      }
    } catch (error) {
      debugPrint('No se pudo limpiar la caché: $error');
    }
    return freed;
  }

  /// Borra las carátulas anteriores de una canción.
  Future<void> deleteCoversOf(String songId) async {
    try {
      final Directory covers = await coversDirectory();
      final String safeId = _sanitize(songId);
      for (final FileSystemEntity entity in covers.listSync()) {
        if (entity is File &&
            entity.path
                .split(RegExp(r'[\\/]'))
                .last
                .startsWith('cover_${safeId}_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Exporta un texto (por ejemplo una lista en JSON) a un archivo temporal
  /// listo para compartir.
  Future<File> writeSharedText(String fileName, String content) async {
    final Directory temp = await getTemporaryDirectory();
    final File file = File('${temp.path}/${_sanitize(fileName)}');
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<int> fileSize(String path) async {
    try {
      final File file = File(path);
      if (!file.existsSync()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), '_');
}
