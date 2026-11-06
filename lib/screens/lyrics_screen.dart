import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_fetcher.dart';

/// Letra de la cancion. Si el archivo `.lrc` tiene tiempos, se **resalta la
/// linea que suena** y se hace scroll automatico (ESCUCHA).
class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key, required this.song});

  final Song song;

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LineaSincronizada {
  const _LineaSincronizada(this.tiempo, this.texto);

  final Duration tiempo;
  final String texto;
}

class _LyricsScreenState extends State<LyricsScreen> {
  late Future<String?> _futuro;
  final ScrollController _scroll = ScrollController();
  List<_LineaSincronizada> _lineas = const <_LineaSincronizada>[];
  int _indice = -1;

  @override
  void initState() {
    super.initState();
    _futuro = _leerLetra();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<String?> _leerLetraLocal() async {
    final String ruta = widget.song.path;
    if (ruta.isEmpty || ruta.startsWith('content://')) return null;
    final int punto = ruta.lastIndexOf('.');
    final String base = punto > 0 ? ruta.substring(0, punto) : ruta;
    for (final String ext in <String>['.lrc', '.LRC', '.txt', '.letra']) {
      try {
        final File archivo = File('$base$ext');
        if (await archivo.exists()) {
          final String texto = await archivo.readAsString();
          if (texto.trim().isNotEmpty) return texto;
        }
      } catch (_) {
        // Se prueba el siguiente formato.
      }
    }
    return null;
  }

  Future<String?> _leerLetra() async {
    final String? local = await _leerLetraLocal();
    if (local != null) return local;
    return LyricsFetcher.fetch(widget.song.title, widget.song.artist, album: widget.song.album);
  }

  static String _soloTexto(String letra) {
    final RegExp tiempos = RegExp(r'\[\d{1,2}:\d{2}(\.\d{1,3})?\]');
    return letra
        .split('\n')
        .map((String linea) => linea.replaceAll(tiempos, '').trim())
        .where((String linea) => linea.isNotEmpty)
        .join('\n');
  }

  /// Convierte un LRC en lineas con tiempo (vacio si no tiene marcas).
  static List<_LineaSincronizada> _parsearLrc(String letra) {
    final RegExp patron = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)$');
    final List<_LineaSincronizada> salida = <_LineaSincronizada>[];
    for (final String cruda in letra.split('\n')) {
      final RegExpMatch? m = patron.firstMatch(cruda.trim());
      if (m == null) continue;
      final int min = int.parse(m.group(1)!);
      final int seg = int.parse(m.group(2)!);
      final String? frac = m.group(3);
      final int ms = frac == null ? 0 : int.parse(frac.padRight(3, '0').substring(0, 3));
      final String texto = (m.group(4) ?? '').trim();
      if (texto.isEmpty) continue;
      salida.add(_LineaSincronizada(Duration(minutes: min, seconds: seg, milliseconds: ms), texto));
    }
    salida.sort((_LineaSincronizada a, _LineaSincronizada b) => a.tiempo.compareTo(b.tiempo));
    return salida;
  }

  void _actualizarIndice(Duration posicion) {
    int nuevo = -1;
    for (int i = 0; i < _lineas.length; i++) {
      if (_lineas[i].tiempo <= posicion) {
        nuevo = i;
      } else {
        break;
      }
    }
    if (nuevo == _indice) return;
    setState(() => _indice = nuevo);
    if (nuevo >= 0 && _scroll.hasClients) {
      final double destino = (nuevo * 44.0) - 120;
      _scroll.animateTo(
        destino.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlayerProvider reproductor = context.watch<PlayerProvider>();
    final bool esLaActual = reproductor.current?.id == widget.song.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<String?>(
        future: _futuro,
        builder: (BuildContext context, AsyncSnapshot<String?> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final String? letra = snap.data;
          if (letra == null || letra.trim().isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).lyricsNotFound,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context).lyricsHowTo,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            );
          }
          final List<_LineaSincronizada> lineas = _parsearLrc(letra);
          _lineas = lineas;
          if (lineas.isEmpty || !esLaActual) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: SelectableText(
                _soloTexto(letra),
                style: const TextStyle(fontSize: 16, height: 1.7),
              ),
            );
          }
          return StreamBuilder<Duration>(
            stream: reproductor.positionStream,
            builder: (BuildContext context, AsyncSnapshot<Duration> pos) {
              final Duration actual = pos.data ?? Duration.zero;
              WidgetsBinding.instance.addPostFrameCallback((_) => _actualizarIndice(actual));
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 140, 20, 200),
                itemCount: lineas.length,
                itemBuilder: (BuildContext context, int i) {
                  final bool activa = i == _indice;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      lineas[i].texto,
                      style: TextStyle(
                        fontSize: activa ? 19 : 16,
                        height: 1.5,
                        fontWeight: activa ? FontWeight.w700 : FontWeight.w400,
                        color: activa ? AppColors.green : AppColors.darkTextDim,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}