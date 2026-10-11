import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants.dart';
import 'storage_service.dart';

/// Selección e importación de archivos de audio (con permiso y ruta elegida).
class MediaImporter {
  const MediaImporter._();

  /// Pide el permiso necesario para leer audio (Android 13+ usa READ_MEDIA_AUDIO).
  /// Pide el permiso de notificaciones (Android 13+). Sin él, la notificación
  /// de reproducción no se muestra y el móvil bloqueado no ofrece controles.
  static Future<void> ensureNotificationPermission() async {
    try {
      final PermissionStatus estado = await Permission.notification.status;
      if (!estado.isGranted) {
        await Permission.notification.request();
      }
    } catch (error) {
      debugPrint('No se pudo pedir el permiso de notificaciones: $error');
    }
  }

  static Future<bool> ensureAudioPermission() async {
    try {
      final Permission audio = Permission.audio;
      if (await audio.isGranted) return true;
      final PermissionStatus audioStatus = await audio.request();
      if (audioStatus.isGranted) return true;
      // Android 12 y anteriores usan almacenamiento.
      final PermissionStatus storage = await Permission.storage.request();
      return storage.isGranted;
    } catch (error) {
      debugPrint('Permiso de audio no disponible: $error');
      return true; // el selector SAF no necesita permisos
    }
  }

  /// Abre el selector de archivos y devuelve rutas locales reproducibles.
  /// Si el proveedor devuelve bytes (nube/content://), se copian a la app.
  static Future<List<String>> pickAudioFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: AudioFormats.supported,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return <String>[];

      final List<String> paths = <String>[];
      for (final PlatformFile file in result.files) {
        if (file.path != null && file.path!.isNotEmpty) {
          // El selector deja el audio en SU caché (Android puede borrarla):
          // lo movemos al almacenamiento permanente de la app.
          final String stable = await StorageService.instance
              .moveImportedFile(file.path!, file.name);
          paths.add(stable);
          continue;
        }
        // Copia de respaldo para content:// o proveedores en la nube.
        final Uint8List? bytes = file.bytes ??
            (await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions: AudioFormats.supported,
              withData: true,
            ))
                ?.files
                .first
                .bytes;
        if (bytes != null) {
          final String saved = await StorageService.instance.saveImportedFile(file.name, bytes);
          paths.add(saved);
        }
      }
      return paths;
    } catch (error) {
      debugPrint('Error al seleccionar archivos: $error');
      return <String>[];
    }
  }

  /// Abre el selector para elegir una imagen de carátula (PNG/JPG).
  static Future<String?> pickImage() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return null;
      return result.files.first.path;
    } catch (error) {
      debugPrint('Error al seleccionar imagen: $error');
      return null;
    }
  }

  /// Abre el selector para importar un JSON de lista y devuelve su contenido.
  static Future<String?> pickJsonFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final PlatformFile file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes != null) return String.fromCharCodes(bytes);
      final String? path = file.path;
      if (path != null && path.isNotEmpty) {
        final File local = File(path);
        if (local.existsSync()) return local.readAsString();
      }
      return null;
    } catch (error) {
      debugPrint('Error al importar JSON: $error');
      return null;
    }
  }

  /// Selecciona una carpeta (útil para importar una discoteca completa).
  static Future<String?> pickFolder() async {
    try {
      return await FilePicker.platform.getDirectoryPath();
    } catch (error) {
      debugPrint('Error al seleccionar carpeta: $error');
      return null;
    }
  }

  /// Exporta bytes con el diálogo del sistema: el usuario elige carpeta
  /// (galería, almacenamiento, nube…). Se usa para listas JSON y carátulas.
  static Future<String?> exportBytes(String fileName, Uint8List bytes) async {
    try {
      return await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        dialogTitle: 'Guardar $fileName',
      );
    } catch (error) {
      debugPrint('Error al exportar $fileName: $error');
      return null;
    }
  }

  /// Exporta texto plano (por ejemplo, una lista en JSON).
  static Future<String?> exportText(String fileName, String content) {
    return exportBytes(fileName, Uint8List.fromList(utf8.encode(content)));
  }

  /// Lista los archivos de audio compatibles de una carpeta local.
  static List<String> listAudioInFolder(String directory, {bool recursive = true}) {
    final List<String> result = <String>[];
    try {
      final Directory dir = Directory(directory);
      if (!dir.existsSync()) return result;
      for (final FileSystemEntity entity in dir.listSync(recursive: recursive, followLinks: false)) {
        if (entity is File && AudioFormats.isSupported(entity.path)) {
          result.add(entity.path);
        }
      }
    } catch (error) {
      debugPrint('No se pudo leer la carpeta: $error');
    }
    result.sort();
    return result;
  }
}
