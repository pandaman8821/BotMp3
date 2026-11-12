import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../models/song.dart';
import '../services/share_service.dart';
import 'cover_art.dart';
import 'playlist_collage.dart';

/// Tarjeta que se comparte como imagen: portada, nombres y atribucion.
///
/// No incluye audio ni enlaces de descarga: solo informacion de la lista.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.canciones,
    required this.atribucion,
    this.portada,
  });

  final String titulo;
  final String subtitulo;
  final List<String> canciones;
  final String atribucion;
  final List<Song>? portada;

  @override
  Widget build(BuildContext context) {
    final List<Song> lista = portada ?? const <Song>[];
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.darkSurface,
            AppColors.darkSurface.withAlpha(230),
            AppColors.aiViolet.withAlpha(40),
          ],
        ),
        border: Border.all(color: AppColors.green.withAlpha(70)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (lista.isNotEmpty)
                PlaylistCollage(songs: lista, size: 84)
              else
                CoverArt(path: null, size: 84),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 2, width: 46, color: AppColors.green.withAlpha(160)),
          const SizedBox(height: 12),
          for (final String linea in canciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                linea,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          if (canciones.isEmpty)
            Text(
              '…',
              style: TextStyle(fontSize: 12.5, color: AppColors.darkTextDim),
            ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(Icons.graphic_eq, size: 15, color: AppColors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  atribucion,
                  maxLines: 2,
                  style: TextStyle(fontSize: 10.5, color: AppColors.darkTextDim),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialogo que enseña la tarjeta y la comparte al pulsar el boton.
class ShareCardDialog extends StatefulWidget {
  const ShareCardDialog({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.canciones,
    required this.atribucion,
    required this.textoCompartir,
    this.portada,
  });

  final String titulo;
  final String subtitulo;
  final List<String> canciones;
  final String atribucion;
  final String textoCompartir;
  final List<Song>? portada;

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _clave = GlobalKey();
  bool _compartiendo = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RepaintBoundary(
              key: _clave,
              child: ShareCard(
                titulo: widget.titulo,
                subtitulo: widget.subtitulo,
                canciones: widget.canciones,
                atribucion: widget.atribucion,
                portada: widget.portada,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _compartiendo
                      ? null
                      : () async {
                          setState(() => _compartiendo = true);
                          Hapticos.accion();
                          await ShareService.compartirWidget(
                            _clave,
                            texto: widget.textoCompartir,
                          );
                          if (mounted) {
                            setState(() => _compartiendo = false);
                            Navigator.of(context).maybePop();
                          }
                        },
                  icon: _compartiendo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(widget.textoCompartir),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Clave del boundary para que el llamador pueda capturar y compartir.
  GlobalKey get claveImagen => _clave;
}
