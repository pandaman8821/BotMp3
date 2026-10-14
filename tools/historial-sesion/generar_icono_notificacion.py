"""Genera el icono MONOCROMO de la notificación de BotMp3.

Android exige un icono blanco con transparencia para la barra de estado. Si se
usa el icono adaptativo (`mipmap/ic_launcher`, un XML `<adaptive-icon>`), la
notificación no se crea y, con ella, desaparecen los controles de reproducción
de la pantalla de bloqueo.

Salida: android/app/src/main/res/drawable-*/ic_stat_botmp3.png
(tamaños oficiales: 24, 36, 48, 72 y 96 px)
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
RES = os.path.join(PROJ, "android", "app", "src", "main", "res")
FUENTE = os.path.join(PROJ, "tools", "icono_fuente.jpg")

DENSIDADES = {
    "mdpi": 24,
    "hdpi": 36,
    "xhdpi": 48,
    "xxhdpi": 72,
    "xxxhdpi": 96,
}


def silueta_notificacion(size: int) -> Image.Image:
    """Silueta blanca y nítida del logotipo, encajada en un lienzo cuadrado."""
    fuente = Image.open(FUENTE).convert("RGB")
    hsv = np.asarray(fuente.convert("HSV")).astype(np.int16)
    saturacion, valor = hsv[..., 1], hsv[..., 2]
    # El logotipo es lo BLANCO/GRIS (saturado bajo y luminoso). El fondo morado
    # y los trazos negros de los rayos quedan fuera: así el icono de la barra de
    # estado es una silueta limpia, no un amasijo de líneas.
    logotipo = (saturacion < 90) & (valor > 130)
    mascara = np.where(logotipo, 255, 0).astype(np.uint8)
    imagen = Image.fromarray(mascara, "L").filter(ImageFilter.MaxFilter(3))

    # Recorte al contenido para que el glifo ocupe el lienzo de forma uniforme.
    caja = imagen.getbbox()
    if caja:
        imagen = imagen.crop(caja)

    # El glifo ocupa el 84 % del icono (margen de seguridad del sistema).
    interior = int(size * 0.84)
    proporcion = imagen.width / imagen.height
    if proporcion >= 1:
        ancho, alto = interior, max(1, int(interior / proporcion))
    else:
        alto, ancho = interior, max(1, int(interior * proporcion))
    imagen = imagen.resize((ancho, alto), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.4))

    lienzo = Image.new("L", (size, size), 0)
    lienzo.paste(imagen, ((size - ancho) // 2, (size - alto) // 2))

    rgba = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    rgba.putalpha(lienzo)
    return rgba


def main() -> int:
    if not os.path.exists(FUENTE):
        print(f"FALLO: no se encontró la imagen fuente {FUENTE}")
        return 1

    escritos = []
    for carpeta, tamano in DENSIDADES.items():
        destino = os.path.join(RES, f"drawable-{carpeta}", "ic_stat_botmp3.png")
        os.makedirs(os.path.dirname(destino), exist_ok=True)
        silueta_notificacion(tamano).save(destino, "PNG", optimize=True)
        escritos.append(os.path.relpath(destino, PROJ))

    # Muestra ampliada para revisarla a ojo.
    vista = os.path.join(ROOT, "_tools", "notificacion_preview.png")
    fondo = Image.new("RGB", (96 * 3 + 40, 96 + 40), (32, 32, 38))
    for indice, tamano in enumerate((48, 72, 96)):
        icono = silueta_notificacion(tamano)
        fondo.paste(icono, (20 + indice * (96 + 20), 20 + (96 - tamano) // 2), icono)
    fondo.save(vista)

    print("ICONOS DE NOTIFICACIÓN ESCRITOS:")
    for item in escritos:
        print("  +", item)
    print("  · vista previa:", os.path.relpath(vista, ROOT))
    return 0


sys.exit(main())
