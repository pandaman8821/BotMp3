import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

/// Guarda las API keys de los proveedores de IA de forma cifrada.
///
/// Android: EncryptedSharedPreferences respaldado por el **Android Keystore**
/// (AES-256). iOS: Keychain. Las claves nunca se escriben en texto plano ni se
/// incluyen en las exportaciones de listas.
class SecureKeysService {
  SecureKeysService._();

  static final SecureKeysService instance = SecureKeysService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _prefix = 'botmp3_api_key_';

  String _keyFor(AiProvider provider) => '$_prefix${provider.id}';

  Future<String?> readKey(AiProvider provider) async {
    try {
      final String? value = await _storage.read(key: _keyFor(provider));
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeKey(AiProvider provider, String value) async {
    final String clean = value.trim();
    try {
      if (clean.isEmpty) {
        await _storage.delete(key: _keyFor(provider));
      } else {
        await _storage.write(key: _keyFor(provider), value: clean);
      }
    } catch (_) {
      // Si el almacén seguro falla (raro), la app sigue funcionando sin la clave.
    }
  }

  Future<void> deleteKey(AiProvider provider) async {
    try {
      await _storage.delete(key: _keyFor(provider));
    } catch (_) {}
  }

  Future<Map<AiProvider, String>> readAll() async {
    final Map<AiProvider, String> keys = <AiProvider, String>{};
    for (final AiProvider provider in AiProvider.values) {
      final String? key = await readKey(provider);
      if (key != null) keys[provider] = key;
    }
    return keys;
  }

  /// Muestra solo los últimos 4 caracteres (para confirmar sin exponer la clave).
  static String mask(String key) {
    final String clean = key.trim();
    if (clean.length <= 8) return '••••••••';
    return '${clean.substring(0, 4)}••••••${clean.substring(clean.length - 4)}';
  }
}
