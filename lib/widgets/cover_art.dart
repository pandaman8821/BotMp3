import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Carátula de una canción o lista.
///
/// Usa `Image.file` con `cacheWidth` para decodificar a un tamaño adaptado a la
/// pantalla: menos memoria, menos batería y menos calor en reproducción larga.
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    this.path,
    this.size = 56,
    this.borderRadius = 12,
    this.showBotIcon = true,
  });

  final String? path;
  final double size;
  final double borderRadius;
  final bool showBotIcon;

  @override
  Widget build(BuildContext context) {
    final double cacheSize = size * MediaQuery.devicePixelRatioOf(context);
    final String? coverPath = path;

    Widget child;
    if (coverPath != null && coverPath.isNotEmpty && File(coverPath).existsSync()) {
      child = Image.file(
        File(coverPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheSize.round(),
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.coverFallback),
      child: Center(
        child: Icon(
          showBotIcon ? Icons.smart_toy_outlined : Icons.music_note,
          size: size * 0.42,
          color: Colors.white.withAlpha(((0.92) * 255).round()),
        ),
      ),
    );
  }
}
