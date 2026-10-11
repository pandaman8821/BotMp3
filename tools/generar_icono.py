"""Genera el icono de BotMp3 (v1.2.1) a partir de la nueva imagen.

Produce:
  * mipmap-*/ic_launcher.png           icono clásico (esquinas redondeadas)
  * mipmap-*/ic_launcher_round.png     icono clásico circular
  * drawable-*/ic_launcher_foreground.png   capa frontal adaptativa (se desvanece
                                             hacia el color de fondo: sin costuras)
  * drawable-*/ic_launcher_monochrome.png   silueta para iconos tematizados
  * assets/icon/botmp3_icon.png / _mono.png  versiones para la interfaz

También ajusta el color de fondo adaptativo y el XML del icono.
"""

from __future__ import annotations

import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.join(ROOT, "BotMp3")
RES = os.path.join(PROJ, "android", "app", "src", "main", "res")
ASSETS = os.path.join(PROJ, "assets", "icon")
SOURCE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icono_fuente.jpg")

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
LEGACY_DP = 48       # tamaño base del icono clásico
ADAPTIVE_DP = 108    # lienzo adaptativo
FOREGROUND_DP = 96   # tamaño del arte dentro del lienzo adaptativo
FADE_FROM = 0.78     # el arte se desvanece a partir de este radio relativo

written: list[str] = []
notas: list[str] = []


def save(image: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path, "PNG", optimize=True)
    written.append(os.path.relpath(path, PROJ))


# ------------------------------------------------------------------ imagen base
src = Image.open(SOURCE).convert("RGB")
np_src = np.asarray(src)

# Color de fondo: mediana del borde (el morado del cómic).
border = np.concatenate([
    np_src[0:10].reshape(-1, 3),
    np_src[-10:].reshape(-1, 3),
    np_src[:, 0:10].reshape(-1, 3),
    np_src[:, -10:].reshape(-1, 3),
])
fondo_rgb = tuple(int(round(v)) for v in np.median(border, axis=0))
fondo_hex = "#{:02X}{:02X}{:02X}".format(*fondo_rgb)
notas.append(f"color de fondo adaptativo: {fondo_hex}")


def con_desvanecido(image: Image.Image, fade_from: float = FADE_FROM) -> Image.Image:
    """Aplica un alfa radial para que el arte se funda con el fondo sin costuras."""
    size = image.width
    rgba = np.asarray(image.convert("RGBA")).astype(np.float32)
    yy, xx = np.mgrid[0:size, 0:size]
    cx = cy = (size - 1) / 2.0
    radio = np.sqrt(((xx - cx) / (size / 2.0)) ** 2 + ((yy - cy) / (size / 2.0)) ** 2)
    alfa = np.clip((1.0 - radio) / (1.0 - fade_from), 0.0, 1.0)
    rgba[..., 3] *= alfa
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def silueta(size: int) -> Image.Image:
    """Silueta blanca y sólida del logotipo (iconos tematizados de Android 13+).

    Se considera «fondo» todo lo morado del cómic: la silueta es el logotipo
    completo (trazos negros incluidos), no solo las zonas blancas.
    """
    hsv = np.asarray(src.convert("HSV")).astype(np.int16)
    sat, val = hsv[..., 1], hsv[..., 2]
    fondo = (sat > 95) & (val > 70)
    mascara = np.where(fondo, 0, 255).astype(np.uint8)
    # Cierra los huecos que dejan los puntos de semitono.
    imagen = Image.fromarray(mascara, "L").filter(ImageFilter.MaxFilter(3))
    imagen = imagen.filter(ImageFilter.GaussianBlur(1)).resize((size, size), Image.LANCZOS)
    rgba = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    rgba.putalpha(imagen)
    return con_desvanecido(rgba)


def redondear(image: Image.Image, radius_ratio: float) -> Image.Image:
    size = image.width
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1),
        radius=int(size * radius_ratio),
        fill=255,
    )
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def circular(image: Image.Image) -> Image.Image:
    size = image.width
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


# ------------------------------------------------------------- iconos por densidad
for nombre, escala in DENSITIES.items():
    legacy_px = int(round(LEGACY_DP * escala))
    adaptive_px = int(round(ADAPTIVE_DP * escala))
    fg_px = int(round(FOREGROUND_DP * escala))

    # 1) Icono clásico (con esquinas redondeadas y circular).
    base = src.resize((legacy_px, legacy_px), Image.LANCZOS).convert("RGBA")
    save(redondear(base, 0.20), os.path.join(RES, f"mipmap-{nombre}", "ic_launcher.png"))
    save(circular(base), os.path.join(RES, f"mipmap-{nombre}", "ic_launcher_round.png"))

    # 2) Capa frontal adaptativa: arte centrado en el lienzo de 108dp.
    arte = con_desvanecido(src.resize((fg_px, fg_px), Image.LANCZOS))
    lienzo = Image.new("RGBA", (adaptive_px, adaptive_px), (0, 0, 0, 0))
    offset = (adaptive_px - fg_px) // 2
    lienzo.paste(arte, (offset, offset), arte)
    save(lienzo, os.path.join(RES, f"drawable-{nombre}", "ic_launcher_foreground.png"))

    # 3) Silueta monocroma (tematizada).
    mono = silueta(fg_px)
    lienzo_mono = Image.new("RGBA", (adaptive_px, adaptive_px), (0, 0, 0, 0))
    lienzo_mono.paste(mono, (offset, offset), mono)
    save(lienzo_mono, os.path.join(RES, f"drawable-{nombre}", "ic_launcher_monochrome.png"))

# ------------------------------------------------------------------ assets app
save(redondear(src.resize((512, 512), Image.LANCZOS).convert("RGBA"), 0.20),
     os.path.join(ASSETS, "botmp3_icon.png"))
save(silueta(512), os.path.join(ASSETS, "botmp3_icon_mono.png"))

# --------------------------------------------------- color y XML del icono adaptive
xml_path = os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml")
with open(xml_path, "r", encoding="utf-8") as handle:
    xml = handle.read()
xml = xml.replace(
    '<monochrome android:drawable="@drawable/ic_launcher_foreground" />',
    '<monochrome android:drawable="@drawable/ic_launcher_monochrome" />',
)
with open(xml_path, "w", encoding="utf-8", newline="\n") as handle:
    handle.write(xml)
written.append(os.path.relpath(xml_path, PROJ))

# ¿Dónde está definido ic_launcher_background?
definido_en = None
for root_dir, _dirs, files in os.walk(os.path.join(RES, "values")):
    for archivo in files:
        ruta = os.path.join(root_dir, archivo)
        with open(ruta, "r", encoding="utf-8") as handle:
            texto = handle.read()
        if "ic_launcher_background" in texto:
            definido_en = (ruta, texto)
            break
    if definido_en:
        break

if definido_en:
    ruta, texto = definido_en
    nuevo = re.sub(
        r'(name="ic_launcher_background">)([^<]+)(</color>)',
        lambda m: f"{m.group(1)}{fondo_hex}{m.group(3)}",
        texto,
    )
    if nuevo != texto:
        with open(ruta, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(nuevo)
        written.append(os.path.relpath(ruta, PROJ))
        notas.append(f"color actualizado en {os.path.relpath(ruta, PROJ)}")
    else:
        notas.append(f"AVISO: no se pudo actualizar el color en {ruta}")
else:
    colors = os.path.join(RES, "values", "colors.xml")
    os.makedirs(os.path.dirname(colors), exist_ok=True)
    with open(colors, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<resources>\n"
            f'    <color name="ic_launcher_background">{fondo_hex}</color>\n'
            "</resources>\n"
        )
    written.append(os.path.relpath(colors, PROJ))
    notas.append("creado values/colors.xml con el color de fondo")

print("ARCHIVOS ESCRITOS:")
for item in written:
    print("  +", item)
print("NOTAS:")
for item in notas:
    print("  ·", item)

# Comprobación visual: silueta sobre fondo oscuro y arte adaptativo sobre el color
# de fondo real, para revisar que no hay costuras.
preview = Image.new("RGB", (432 * 2 + 24, 432), (24, 24, 28))
preview.paste(silueta(432), (0, 0), silueta(432))
arte_fondo = Image.new("RGB", (432, 432), fondo_rgb)
arte = con_desvanecido(src.resize((384, 384), Image.LANCZOS))
arte_fondo.paste(arte, ((432 - 384) // 2, (432 - 384) // 2), arte)
preview.paste(arte_fondo, (432 + 24, 0))
preview.save(os.path.join(ROOT, "_tools", "icono_preview.png"), "PNG")
print("  · vista previa: _tools/icono_preview.png")
sys.exit(0)
