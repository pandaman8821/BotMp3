import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'storage_service.dart';

/// Filtros rápidos aplicables a la carátula.
enum CoverFilter { none, blancoYNegro, vintage, calido, frio, dramatico, desvanecido, vivo }

extension CoverFilterInfo on CoverFilter {
  String get label {
    switch (this) {
      case CoverFilter.none:
        return 'Original';
      case CoverFilter.blancoYNegro:
        return 'Blanco y negro';
      case CoverFilter.vintage:
        return 'Vintage';
      case CoverFilter.calido:
        return 'Cálido';
      case CoverFilter.frio:
        return 'Frío';
      case CoverFilter.dramatico:
        return 'Dramático';
      case CoverFilter.desvanecido:
        return 'Desvanecido';
      case CoverFilter.vivo:
        return 'Vivo';
    }
  }
}

/// Posición del texto/logo sobre la carátula.
enum CoverTextPosition { arriba, centro, abajo }

/// Estado editable de la carátula (lo que el usuario ve en los controles).
class CoverEditState {
  const CoverEditState({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.temperature = 0,
    this.fade = 0,
    this.quarterTurns = 0,
    this.zoom = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.aspect = CoverAspect.cuadrado,
    this.filter = CoverFilter.none,
    this.text = '',
    this.textPosition = CoverTextPosition.abajo,
    this.textSize = 1,
    this.textColor = 0xFFFFFFFF,
  });

  /// -0.5 .. +0.5 (0 = sin cambio)
  final double brightness;

  /// -0.5 .. +0.5
  final double contrast;

  /// -1 .. +1
  final double saturation;

  /// -1 (frío) .. +1 (cálido)
  final double temperature;

  /// 0 .. 0.6 (velo claro)
  final double fade;

  /// 0..3 giros de 90°
  final int quarterTurns;

  /// 1.0 .. 3.0 (zoom dentro del recorte)
  final double zoom;

  /// -1..1 desplazamiento del encuadre
  final double offsetX;
  final double offsetY;

  final CoverAspect aspect;
  final CoverFilter filter;
  final String text;
  final CoverTextPosition textPosition;
  final double textSize;
  final int textColor;

  CoverEditState copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? temperature,
    double? fade,
    int? quarterTurns,
    double? zoom,
    double? offsetX,
    double? offsetY,
    CoverAspect? aspect,
    CoverFilter? filter,
    String? text,
    CoverTextPosition? textPosition,
    double? textSize,
    int? textColor,
  }) {
    return CoverEditState(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
      fade: fade ?? this.fade,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      zoom: zoom ?? this.zoom,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      aspect: aspect ?? this.aspect,
      filter: filter ?? this.filter,
      text: text ?? this.text,
      textPosition: textPosition ?? this.textPosition,
      textSize: textSize ?? this.textSize,
      textColor: textColor ?? this.textColor,
    );
  }

  /// ¿Hay cambios respecto al original?
  bool get isEdited =>
      brightness != 0 ||
      contrast != 0 ||
      saturation != 0 ||
      temperature != 0 ||
      fade != 0 ||
      quarterTurns != 0 ||
      zoom != 1 ||
      offsetX != 0 ||
      offsetY != 0 ||
      filter != CoverFilter.none ||
      text.trim().isNotEmpty;
}

/// Proporciones de recorte predefinidas.
enum CoverAspect {
  original('Original', 0),
  cuadrado('1:1', 1),
  vertical('9:16', 9 / 16),
  horizontal('16:9', 16 / 9);

  const CoverAspect(this.label, this.ratio);

  final String label;

  /// ancho/alto (0 = sin recorte).
  final double ratio;
}

/// Petición de render que se envía al isolate (compute).
class CoverRenderRequest {
  const CoverRenderRequest({required this.source, required this.state, this.maxSize = 1080});

  final Uint8List source;
  final CoverEditState state;
  final int maxSize;
}

/// Editor de carátulas 100 % Dart (sin código nativo):
/// brillo, contraste, saturación, temperatura, filtros, rotación, recorte con
/// zoom/encuadre, texto/logo y exportación a JPG/PNG.
class CoverEditorService {
  CoverEditorService._();

  static final CoverEditorService instance = CoverEditorService._();

  /// Procesa la imagen en un isolate aparte para no bloquear la interfaz a 120 Hz
  /// (importante para el POCO X7 Pro y para no calentar el dispositivo).
  Future<Uint8List> render(Uint8List source, CoverEditState state) {
    return compute<CoverRenderRequest, Uint8List>(
      _renderCover,
      CoverRenderRequest(source: source, state: state),
    );
  }

  /// Guarda la carátula editada en el almacenamiento de la app.
  Future<String> save(Uint8List bytes, String songId, {bool png = false}) {
    return StorageService.instance.saveCoverBytes(songId, bytes, png: png);
  }
}

/// Función de render (top-level para poder ejecutarse con `compute`).
Uint8List _renderCover(CoverRenderRequest request) {
  final CoverEditState state = request.state;
  img.Image? image = img.decodeImage(request.source);
  if (image == null) return request.source;

  // 1) Grading por píxel: filtros + brillo + contraste + saturación + temperatura.
  final (double, double, double) grading = _filterMatrix(state.filter);
  final double bright = 1 + state.brightness;
  final double contrast = 1 + state.contrast;
  final double saturation = 1 + state.saturation;
  final double warm = state.temperature * 42;
  final double fade = state.fade.clamp(0.0, 0.6);

  for (final img.Pixel pixel in image) {
    double r = pixel.r.toDouble() * grading.$1;
    double g = pixel.g.toDouble() * grading.$2;
    double b = pixel.b.toDouble() * grading.$3;

    // Brillo
    r *= bright;
    g *= bright;
    b *= bright;

    // Contraste (pivote en el gris medio)
    r = (r - 128) * contrast + 128;
    g = (g - 128) * contrast + 128;
    b = (b - 128) * contrast + 128;

    // Saturación (luma Rec.709)
    final double luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    r = luma + (r - luma) * saturation;
    g = luma + (g - luma) * saturation;
    b = luma + (b - luma) * saturation;

    // Temperatura (cálido/frío)
    r += warm;
    b -= warm;

    // Velo / desvanecido
    if (fade > 0) {
      r = r * (1 - fade) + 205 * fade;
      g = g * (1 - fade) + 205 * fade;
      b = b * (1 - fade) + 205 * fade;
    }

    pixel.r = r.round().clamp(0, 255).toInt();
    pixel.g = g.round().clamp(0, 255).toInt();
    pixel.b = b.round().clamp(0, 255).toInt();
  }

  // 2) Rotación (múltiplos de 90°).
  if (state.quarterTurns % 4 != 0) {
    image = img.copyRotate(image, angle: (state.quarterTurns % 4) * 90);
  }

  // 3) Recorte con zoom y encuadre.
  image = _crop(image, state);

  // 4) Tamaño final razonable (ahorra memoria y batería).
  if (image.width > request.maxSize || image.height > request.maxSize) {
    image = image.width >= image.height
        ? img.copyResize(image, width: request.maxSize)
        : img.copyResize(image, height: request.maxSize);
  }

  // 5) Texto/logo.
  if (state.text.trim().isNotEmpty) {
    image = _drawText(image, state);
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

/// Multiplicadores por canal según el filtro elegido.
(double, double, double) _filterMatrix(CoverFilter filter) {
  switch (filter) {
    case CoverFilter.none:
      return (1.0, 1.0, 1.0);
    case CoverFilter.blancoYNegro:
      return (0.299, 0.587, 0.114); // escala de grises por luma
    case CoverFilter.vintage:
      return (1.12, 1.02, 0.86);
    case CoverFilter.calido:
      return (1.10, 1.02, 0.92);
    case CoverFilter.frio:
      return (0.92, 1.0, 1.12);
    case CoverFilter.dramatico:
      return (0.94, 0.96, 1.06);
    case CoverFilter.desvanecido:
      return (1.04, 1.02, 1.0);
    case CoverFilter.vivo:
      return (1.08, 1.0, 1.04);
  }
}

/// Recorte cuadrado/vertical/horizontal con zoom y desplazamiento.
img.Image _crop(img.Image image, CoverEditState state) {
  final double ratio = state.aspect.ratio == 0
      ? image.width / image.height
      : state.aspect.ratio;

  double targetWidth = image.width / state.zoom.clamp(1.0, 3.0);
  double targetHeight = targetWidth / ratio;
  if (targetHeight > image.height / state.zoom.clamp(1.0, 3.0)) {
    targetHeight = image.height / state.zoom.clamp(1.0, 3.0);
    targetWidth = targetHeight * ratio;
  }
  targetWidth = targetWidth.clamp(24, image.width.toDouble());
  targetHeight = targetHeight.clamp(24, image.height.toDouble());

  final double freeX = image.width - targetWidth;
  final double freeY = image.height - targetHeight;
  final double x = (freeX / 2) * (1 + state.offsetX.clamp(-1.0, 1.0));
  final double y = (freeY / 2) * (1 + state.offsetY.clamp(-1.0, 1.0));

  return img.copyCrop(
    image,
    x: x.round().clamp(0, freeX.round()),
    y: y.round().clamp(0, freeY.round()),
    width: targetWidth.round(),
    height: targetHeight.round(),
  );
}

/// Dibuja el texto/logo con banda de contraste para que siempre se lea.
img.Image _drawText(img.Image image, CoverEditState state) {
  final String text = state.text.trim();
  final int fontSize = (image.width * 0.075 * state.textSize).round().clamp(12, 160);
  final img.BitmapFont font = fontSize >= 60
      ? img.arial48
      : fontSize >= 30
          ? img.arial24
          : img.arial14;

  // Banda semitransparente detrás del texto (no requiere medir el texto).
  final int bandHeight = (fontSize * 1.6).round();
  final int bandY = switch (state.textPosition) {
    CoverTextPosition.arriba => (image.height * 0.04).round(),
    CoverTextPosition.centro => ((image.height - bandHeight) / 2).round(),
    CoverTextPosition.abajo => (image.height * 0.9 - bandHeight).round(),
  };

  final img.Color bandColor = img.ColorRgba8(0, 0, 0, 130);
  img.fillRect(
    image,
    x1: 0,
    y1: bandY.clamp(0, image.height - 1),
    x2: image.width - 1,
    y2: (bandY + bandHeight).clamp(0, image.height - 1),
    color: bandColor,
  );

  // Centrado aproximado (ancho medio por carácter según el tamaño de fuente).
  final int estimatedWidth = (text.length * fontSize * 0.55).round();
  final int x = ((image.width - estimatedWidth) / 2).round().clamp(6, image.width);
  final int y = bandY + ((bandHeight - fontSize) / 2).round();

  final int argb = state.textColor;
  final img.Color textColor = img.ColorRgba8(
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
    (argb >> 24) & 0xFF,
  );

  img.drawString(
    image,
    text,
    font: font,
    x: x,
    y: y,
    color: textColor,
  );
  return image;
}
