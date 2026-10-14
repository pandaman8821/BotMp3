import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/trends_service.dart';
import '../widgets/glass.dart';

/// Canciones que están en tendencia en internet, con opción de escucharlas si
/// ya las tienes en la biblioteca y de recibir avisos.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final TrendsService _trends = TrendsService.instance;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar(usarCache: true);
  }

  Future<void> _cargar({bool usarCache = false}) async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    if (usarCache) await _trends.cargarCache();
    final List<TrendSong> lista = await _trends.fetch(country: settings.trendsCountry);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (lista.isEmpty) {
        _error = 'No se pudieron obtener las tendencias. Revisa tu conexión.';
      }
    });
  }

  /// Busca la canción en tendencia dentro de tu biblioteca.
  Song? _enBiblioteca(TrendSong trend, LibraryProvider library) {
    final String clave = trend.clave;
    for (final Song song in library.songs) {
      if ('${song.title.toLowerCase().trim()}|${song.artist.toLowerCase().trim()}' == clave) {
        return song;
      }
    }
    return null;
  }

  Future<void> _abrirEnlace(TrendSong trend) async {
    // Siempre YouTube: es la biblioteca más grande y no obliga a tener
    // instalado otro servicio (el enlace original apuntaba a una tienda).
    final Uri url = Uri.parse(
      'https://www.youtube.com/results?search_query='
      '${Uri.encodeComponent('${trend.title} ${trend.artist}')}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _notificar() async {
    final List<TrendSong> lista = _trends.ultimas;
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero actualiza las tendencias')),
      );
      return;
    }
    final SettingsProvider settings = context.read<SettingsProvider>();
    final String pais = TrendsService.paises[settings.trendsCountry] ?? settings.trendsCountry;
    final bool ok = await NotificationService.instance.show(
      title: '🔥 Tendencias en $pais',
      body: _trends.resumen(cuantas: 3),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notificación enviada con el top de $pais'
              : 'No se pudo mostrar la notificación (revisa el permiso)',
        ),
      ),
    );
  }

  Future<void> _copiar() async {
    final List<TrendSong> lista = _trends.ultimas;
    if (lista.isEmpty) return;
    final StringBuffer buffer = StringBuffer('Tendencias musicales 🔥\n');
    for (int i = 0; i < lista.length; i++) {
      buffer.writeln('${i + 1}. ${lista[i].title} — ${lista[i].artist}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista copiada al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LibraryProvider library = context.watch<LibraryProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final List<TrendSong> lista = _trends.ultimas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tendencias'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notificar el top',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _notificar,
          ),
          IconButton(
            tooltip: 'Copiar la lista',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copiar,
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: <Widget>[
                const Icon(Icons.public, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: settings.trendsCountry,
                    items: TrendsService.paises.entries
                        .map(
                          (MapEntry<String, String> entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text('Éxitos en ${entry.value}'),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) async {
                      if (value == null) return;
                      await settings.setTrendsCountry(value);
                      await _cargar();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_cargando) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: AppColors.warning)),
            ),
          if (_trends.actualizado != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Actualizado: ${_fecha(_trends.actualizado!)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.darkTextDim),
                ),
              ),
            ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.local_fire_department_outlined, size: 46),
                          const SizedBox(height: 12),
                          Text(
                            _cargando
                                ? 'Buscando las canciones más escuchadas…'
                                : 'Pulsa actualizar para ver qué suena ahora mismo en internet.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120, top: 4),
                    itemCount: lista.length,
                    itemBuilder: (BuildContext context, int index) {
                      final TrendSong trend = lista[index];
                      final Song? local = _enBiblioteca(trend, library);
                      return ListTile(
                        leading: SizedBox(
                          width: 60,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: index < 3 ? AppColors.aiViolet : null,
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: trend.artworkUrl.isEmpty
                                    ? const SizedBox(width: 42, height: 42)
                                    : Image.network(
                                        trend.artworkUrl,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(width: 42, height: 42),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(trend.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          local != null
                              ? '${trend.artist} · ya la tienes en tu biblioteca'
                              : trend.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          local != null ? Icons.play_circle_fill : Icons.open_in_new,
                          color: local != null ? AppColors.green : null,
                        ),
                        onTap: () {
                          if (local != null) {
                            context.read<PlayerProvider>().playSong(local, context: <Song>[local]);
                          } else {
                            _abrirEnlace(trend);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fecha(DateTime value) {
    final Duration diferencia = DateTime.now().difference(value);
    if (diferencia.inMinutes < 1) return 'ahora mismo';
    if (diferencia.inHours < 1) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'hace ${diferencia.inHours} h';
    return 'hace ${diferencia.inDays} d';
  }
}
