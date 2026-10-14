import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import 'storage_service.dart';

/// Una canción en tendencia según la lista pública de éxitos.
class TrendSong {
  const TrendSong({
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.url,
    this.genre = '',
    this.releaseDate = '',
  });

  final String title;
  final String artist;
  final String artworkUrl;
  final String url;
  final String genre;
  final String releaseDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'artist': artist,
        'artwork': artworkUrl,
        'url': url,
        'genre': genre,
        'releaseDate': releaseDate,
      };

  static TrendSong fromJson(Map<String, dynamic> json) => TrendSong(
        title: (json['title'] ?? '').toString(),
        artist: (json['artist'] ?? '').toString(),
        artworkUrl: (json['artwork'] ?? '').toString(),
        url: (json['url'] ?? '').toString(),
        genre: (json['genre'] ?? '').toString(),
        releaseDate: (json['releaseDate'] ?? '').toString(),
      );

  /// Clave para reconocer la canción en la biblioteca local.
  String get clave => '${title.toLowerCase().trim()}|${artist.toLowerCase().trim()}';
}

/// Tendencias musicales de internet.
///
/// Usa el canal público de listas de éxitos de Apple
/// (`rss.applemarketingtools.com`): es gratuito, **no necesita clave** ni cuenta,
/// y admite el país como parámetro, así que las tendencias son locales.
class TrendsService {
  TrendsService._();

  static final TrendsService instance = TrendsService._();

  static const String _base = 'https://rss.applemarketingtools.com/api/v2';

  /// Países ofrecidos en Ajustes (código de tienda de Apple Music).
  ///
  /// Son las principales tiendas del mundo con lista de éxitos propia; si
  /// alguna no publica la suya, se muestra la global (ver `usandoListaGlobal`).
  static const Map<String, String> paises = <String, String>{
    'es': '🇪🇸 España',
    'mx': '🇲🇽 México',
    'us': '🇺🇸 Estados Unidos',
    'ar': '🇦🇷 Argentina',
    'co': '🇨🇴 Colombia',
    'cl': '🇨🇱 Chile',
    'pe': '🇵🇪 Perú',
    've': '🇻🇪 Venezuela',
    'ec': '🇪🇨 Ecuador',
    'do': '🇩🇴 República Dominicana',
    'uy': '🇺🇾 Uruguay',
    'py': '🇵🇾 Paraguay',
    'bo': '🇧🇴 Bolivia',
    'cr': '🇨🇷 Costa Rica',
    'pa': '🇵🇦 Panamá',
    'gt': '🇬🇹 Guatemala',
    'sv': '🇸🇻 El Salvador',
    'hn': '🇭🇳 Honduras',
    'ni': '🇳🇮 Nicaragua',
    'cu': '🇨🇺 Cuba',
    'pr': '🇵🇷 Puerto Rico',
    'br': '🇧🇷 Brasil',
    'pt': '🇵🇹 Portugal',
    'fr': '🇫🇷 Francia',
    'de': '🇩🇪 Alemania',
    'it': '🇮🇹 Italia',
    'gb': '🇬🇧 Reino Unido',
    'ie': '🇮🇪 Irlanda',
    'nl': '🇳🇱 Países Bajos',
    'be': '🇧🇪 Bélgica',
    'lu': '🇱🇺 Luxemburgo',
    'ch': '🇨🇭 Suiza',
    'at': '🇦🇹 Austria',
    'se': '🇸🇪 Suecia',
    'no': '🇳🇴 Noruega',
    'dk': '🇩🇰 Dinamarca',
    'fi': '🇫🇮 Finlandia',
    'is': '🇮🇸 Islandia',
    'pl': '🇵🇱 Polonia',
    'cz': '🇨🇿 Chequia',
    'sk': '🇸🇰 Eslovaquia',
    'hu': '🇭🇺 Hungría',
    'ro': '🇷🇴 Rumanía',
    'bg': '🇧🇬 Bulgaria',
    'gr': '🇬🇷 Grecia',
    'hr': '🇭🇷 Croacia',
    'si': '🇸🇮 Eslovenia',
    'rs': '🇷🇸 Serbia',
    'ba': '🇧🇦 Bosnia y Herzegovina',
    'mk': '🇲🇰 Macedonia del Norte',
    'al': '🇦🇱 Albania',
    'lt': '🇱🇹 Lituania',
    'lv': '🇱🇻 Letonia',
    'ee': '🇪🇪 Estonia',
    'ua': '🇺🇦 Ucrania',
    'md': '🇲🇩 Moldavia',
    'by': '🇧🇾 Bielorrusia',
    'ru': '🇷🇺 Rusia',
    'tr': '🇹🇷 Turquía',
    'cy': '🇨🇾 Chipre',
    'mt': '🇲🇹 Malta',
    'il': '🇮🇱 Israel',
    'sa': '🇸🇦 Arabia Saudí',
    'ae': '🇦🇪 Emiratos Árabes Unidos',
    'qa': '🇶🇦 Catar',
    'kw': '🇰🇼 Kuwait',
    'bh': '🇧🇭 Baréin',
    'om': '🇴🇲 Omán',
    'jo': '🇯🇴 Jordania',
    'lb': '🇱🇧 Líbano',
    'eg': '🇪🇬 Egipto',
    'ma': '🇲🇦 Marruecos',
    'dz': '🇩🇿 Argelia',
    'tn': '🇹🇳 Túnez',
    'ly': '🇱🇾 Libia',
    'ng': '🇳🇬 Nigeria',
    'gh': '🇬🇭 Ghana',
    'ke': '🇰🇪 Kenia',
    'tz': '🇹🇿 Tanzania',
    'ug': '🇺🇬 Uganda',
    'za': '🇿🇦 Sudáfrica',
    'zm': '🇿🇲 Zambia',
    'zw': '🇿🇼 Zimbabue',
    'mz': '🇲🇿 Mozambique',
    'ao': '🇦🇴 Angola',
    'cm': '🇨🇲 Camerún',
    'ci': '🇨🇮 Costa de Marfil',
    'sn': '🇸🇳 Senegal',
    'in': '🇮🇳 India',
    'pk': '🇵🇰 Pakistán',
    'bd': '🇧🇩 Bangladés',
    'lk': '🇱🇰 Sri Lanka',
    'np': '🇳🇵 Nepal',
    'cn': '🇨🇳 China',
    'hk': '🇭🇰 Hong Kong',
    'tw': '🇹🇼 Taiwán',
    'jp': '🇯🇵 Japón',
    'kr': '🇰🇷 Corea del Sur',
    'th': '🇹🇭 Tailandia',
    'vn': '🇻🇳 Vietnam',
    'my': '🇲🇾 Malasia',
    'sg': '🇸🇬 Singapur',
    'id': '🇮🇩 Indonesia',
    'ph': '🇵🇭 Filipinas',
    'au': '🇦🇺 Australia',
    'nz': '🇳🇿 Nueva Zelanda',
    'kz': '🇰🇿 Kazajistán',
    'uz': '🇺🇿 Uzbekistán',
    'am': '🇦🇲 Armenia',
    'az': '🇦🇿 Azerbaiyán',
    'ge': '🇬🇪 Georgia',
  };

  final List<TrendSong> _ultimas = <TrendSong>[];
  DateTime? _actualizado;
  bool _usandoGlobal = false;

  /// Verdadero cuando el país elegido no publica lista propia y se está
  /// mostrando la global (Estados Unidos).
  bool get usandoListaGlobal => _usandoGlobal;

  List<TrendSong> get ultimas => List<TrendSong>.unmodifiable(_ultimas);
  DateTime? get actualizado => _actualizado;
  bool get hayCache => _ultimas.isNotEmpty;

  /// Descarga la lista de éxitos del país indicado.
  /// Nunca lanza: si falla, devuelve lo último que hubiera en la caché.
  Future<List<TrendSong>> fetch({String country = 'es', int limit = 25}) async {
    try {
      final Uri url = Uri.parse('$_base/$country/music/most-played/$limit/songs.json');
      final http.Response response = await http
          .get(url, headers: <String, String>{'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('Tendencias: HTTP ${response.statusCode}');
        return _ultimas;
      }
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      List<TrendSong> lista = _parse(decoded);
      _usandoGlobal = false;
      // Algunas tiendas no publican lista de éxitos: se usa la global para no
      // dejar la pantalla vacía, avisando con `usandoListaGlobal`.
      if (lista.isEmpty && country != 'us') {
        final List<TrendSong> global = await _fetchPais('us', limit);
        if (global.isNotEmpty) {
          lista = global;
          _usandoGlobal = true;
        }
      }
      if (lista.isNotEmpty) {
        _ultimas
          ..clear()
          ..addAll(lista);
        _actualizado = DateTime.now();
        await _guardarCache(country);
      }
      return lista;
    } catch (error) {
      debugPrint('No se pudieron obtener las tendencias: $error');
      return _ultimas;
    }
  }

  /// Petición simple de un país concreto (sin caché ni respaldos).
  Future<List<TrendSong>> _fetchPais(String country, int limit) async {
    try {
      final Uri url = Uri.parse('$_base/$country/music/most-played/$limit/songs.json');
      final http.Response response = await http
          .get(url, headers: <String, String>{'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return <TrendSong>[];
      return _parse(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      return <TrendSong>[];
    }
  }

  List<TrendSong> _parse(dynamic decoded) {
    final List<TrendSong> lista = <TrendSong>[];
    if (decoded is! Map) return lista;
    final dynamic feed = decoded['feed'];
    if (feed is! Map) return lista;
    final dynamic results = feed['results'];
    if (results is! List) return lista;
    for (final dynamic item in results) {
      if (item is! Map) continue;
      final String title = (item['name'] ?? '').toString();
      final String artist = (item['artistName'] ?? '').toString();
      if (title.isEmpty || artist.isEmpty) continue;
      String genero = '';
      final dynamic genres = item['genres'];
      if (genres is List && genres.isNotEmpty && genres.first is Map) {
        genero = ((genres.first as Map)['name'] ?? '').toString();
      }
      lista.add(
        TrendSong(
          title: title,
          artist: artist,
          // La carátula de 100 px se puede pedir más grande cambiando el tamaño.
          artworkUrl: (item['artworkUrl100'] ?? '')
              .toString()
              .replaceAll('100x100bb', '300x300bb'),
          url: (item['url'] ?? '').toString(),
          genre: genero,
          releaseDate: (item['releaseDate'] ?? '').toString(),
        ),
      );
    }
    return lista;
  }

  /// Guarda en disco la última lista (también la lee el recordatorio de Android
  /// para poder avisar sin conexión).
  Future<void> _guardarCache(String country) async {
    try {
      await StorageService.instance.writeJson(StorageKeys.trendsFile, <String, dynamic>{
        'country': country,
        'updatedAt': _actualizado?.toIso8601String(),
        'items': _ultimas.map((TrendSong song) => song.toJson()).toList(),
      });
    } catch (error) {
      debugPrint('No se pudo guardar la caché de tendencias: $error');
    }
  }

  /// Carga la última lista guardada.
  Future<List<TrendSong>> cargarCache() async {
    try {
      final Map<String, dynamic>? json =
          await StorageService.instance.readJsonMap(StorageKeys.trendsFile);
      if (json == null) return _ultimas;
      final dynamic items = json['items'];
      if (items is! List) return _ultimas;
      _ultimas
        ..clear()
        ..addAll(
          items.whereType<Map<String, dynamic>>().map(TrendSong.fromJson),
        );
      final dynamic updated = json['updatedAt'];
      if (updated is String) _actualizado = DateTime.tryParse(updated);
    } catch (error) {
      debugPrint('No se pudo leer la caché de tendencias: $error');
    }
    return _ultimas;
  }

  /// Texto corto con el «top» para notificaciones y para compartir.
  String resumen({int cuantas = 3}) {
    if (_ultimas.isEmpty) return 'Sin datos de tendencias';
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < _ultimas.length && i < cuantas; i++) {
      if (i > 0) buffer.write(' · ');
      buffer.write('${i + 1}. ${_ultimas[i].title} — ${_ultimas[i].artist}');
    }
    return buffer.toString();
  }
}
