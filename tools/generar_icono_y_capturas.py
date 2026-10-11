"""
BotMp3 - generador del icono de la APK y de las capturas de la interfaz.

Uso:
    python tools/generar_icono_y_capturas.py

Genera:
  * assets/icon/botmp3_icon.png              (1024x1024, icono maestro)
  * assets/icon/botmp3_icon_mono.png         (versión monocroma para temas)
  * android/app/src/main/res/mipmap-*/ic_launcher.png          (48..192 px)
  * android/app/src/main/res/drawable-*/ic_launcher_foreground.png (108..432 px)
  * capturas/*.png                           (mockups de la interfaz)

Icono: ondas sonoras verdes + cabeza de bot IA con antena y ojos brillantes
sobre fondo oscuro con degradado (estilo AMOLED).
"""

from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# --------------------------------------------------------------------------- #
# Paleta
# --------------------------------------------------------------------------- #
BG_DARK = (10, 10, 15)
SURFACE = (20, 20, 28)
SURFACE_HIGH = (29, 29, 40)
TEXT = (242, 243, 247)
TEXT_DIM = (154, 160, 180)
GREEN = (29, 185, 84)
GREEN_DIM = (20, 131, 59)
VIOLET = (124, 77, 255)
CYAN = (0, 224, 198)
AMBER = (245, 158, 11)
RED = (239, 68, 68)

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\segoeui.ttf",
    r"C:\Windows\Fonts\arial.ttf",
    r"C:\Windows\Fonts\calibri.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
]
FONT_BOLD_CANDIDATES = [
    r"C:\Windows\Fonts\segoeuib.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
    r"C:\Windows\Fonts\calibrib.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    for path in (FONT_BOLD_CANDIDATES if bold else FONT_CANDIDATES):
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int],
                      bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", (1, height))
    pixels = image.load()
    for y in range(height):
        ratio = y / max(1, height - 1)
        pixels[0, y] = tuple(round(top[i] + (bottom[i] - top[i]) * ratio) for i in range(3))
    return image.resize((width, height))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return mask


# --------------------------------------------------------------------------- #
# Icono
# --------------------------------------------------------------------------- #
def draw_bot_head(canvas: Image.Image, box: tuple[int, int, int, int],
                  body_color: tuple[int, int, int], eye_color: tuple[int, int, int],
                  outline: bool = False) -> None:
    """Dibuja una cabeza de bot con antena y ojos brillantes."""
    x0, y0, x1, y1 = box
    width = x1 - x0
    height = y1 - y0

    head = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(head)
    radius = int(height * 0.34)
    draw.rounded_rectangle([0, 0, width - 1, height - 1], radius=radius,
                           fill=body_color + (255,), outline=(255, 255, 255, 60) if outline else None,
                           width=max(2, width // 90))

    # Antena
    antenna_x = width // 2
    draw.line([(antenna_x, 0), (antenna_x, -int(height * 0.30))], fill=body_color + (255,),
              width=max(3, width // 40))
    r = max(4, width // 14)
    draw.ellipse([antenna_x - r, -int(height * 0.30) - r, antenna_x + r, -int(height * 0.30) + r],
                 fill=eye_color + (255,))

    # Ojos
    eye_w = int(width * 0.20)
    eye_h = int(height * 0.20)
    eye_y = int(height * 0.34)
    for cx in (int(width * 0.31), int(width * 0.69)):
        draw.rounded_rectangle([cx - eye_w // 2, eye_y, cx + eye_w // 2, eye_y + eye_h],
                               radius=eye_h // 2, fill=eye_color + (255,))

    # Boca / rejilla
    mouth_y = int(height * 0.66)
    bar_w = int(width * 0.09)
    gap = int(width * 0.05)
    total = 4 * bar_w + 3 * gap
    start = (width - total) // 2
    for i in range(4):
        bx = start + i * (bar_w + gap)
        draw.rounded_rectangle([bx, mouth_y, bx + bar_w, mouth_y + int(height * 0.14)],
                               radius=bar_w // 2, fill=(255, 255, 255, 120))

    # Glow alrededor de la cabeza
    glow = head.filter(ImageFilter.GaussianBlur(width * 0.06))
    canvas.alpha_composite(glow, (x0, max(0, y0 - int(height * 0.30))))
    canvas.alpha_composite(head, (x0, max(0, y0 - int(height * 0.30))))


def build_icon(size: int = 1024, monochrome: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Fondo con degradado y esquinas redondeadas
    gradient = vertical_gradient((size, size), (14, 14, 24), (6, 6, 10)).convert("RGBA")
    background = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    background.paste(gradient, (0, 0), rounded_mask((size, size), int(size * 0.22)))
    canvas.alpha_composite(background)

    # Aro decorativo con degradado (verde -> violeta)
    ring = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring)
    margin = int(size * 0.07)
    ring_draw.ellipse([margin, margin, size - margin, size - margin],
                      outline=(255, 255, 255, 26), width=max(3, size // 160))
    canvas.alpha_composite(ring)

    if monochrome:
        green = (255, 255, 255)
        violet = (255, 255, 255)
        cyan = (255, 255, 255)
        bar_color = (255, 255, 255)
    else:
        green, violet, cyan, bar_color = GREEN, VIOLET, CYAN, GREEN

    # Ondas sonoras (5 barras) en la parte baja
    bar_count = 5
    bar_w = int(size * 0.062)
    gap = int(size * 0.030)
    total_w = bar_count * bar_w + (bar_count - 1) * gap
    start_x = (size - total_w) // 2
    base_y = int(size * 0.80)
    heights = [0.13, 0.22, 0.31, 0.20, 0.12]

    waves = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    waves_draw = ImageDraw.Draw(waves)
    for index, factor in enumerate(heights):
        bar_h = int(size * factor)
        x = start_x + index * (bar_w + gap)
        waves_draw.rounded_rectangle(
            [x, base_y - bar_h, x + bar_w, base_y],
            radius=bar_w // 2,
            fill=bar_color + (255,),
        )
    glow = waves.filter(ImageFilter.GaussianBlur(size * 0.018))
    canvas.alpha_composite(glow)
    canvas.alpha_composite(waves)

    # Cabeza de bot (encima de las ondas)
    head_size = int(size * 0.42)
    head_box = ((size - head_size) // 2, int(size * 0.30), (size + head_size) // 2,
                int(size * 0.30) + head_size)
    if monochrome:
        draw_bot_head(canvas, head_box, (255, 255, 255), (20, 20, 30))
    else:
        # Degradado violeta -> cyan dentro de la cabeza
        head_layer = Image.new("RGBA", (head_size, head_size), (0, 0, 0, 0))
        for y in range(head_size):
            ratio = y / max(1, head_size - 1)
            color = tuple(round(violet[i] + (cyan[i] - violet[i]) * ratio) for i in range(3))
            ImageDraw.Draw(head_layer).line([(0, y), (head_size, y)], fill=color + (255,))
        head_layer.putalpha(rounded_mask((head_size, head_size), int(head_size * 0.34)))
        canvas.alpha_composite(head_layer, (head_box[0], head_box[1] - int(head_size * 0.30)))

        # Ojos, antena y boca encima
        draw_detail = ImageDraw.Draw(canvas)
        antenna_x = size // 2
        antenna_top = head_box[1] - int(head_size * 0.30)
        draw_detail.line([(antenna_x, head_box[1]), (antenna_x, antenna_top)],
                         fill=(255, 255, 255, 230), width=max(4, size // 140))
        r = max(6, size // 90)
        draw_detail.ellipse([antenna_x - r, antenna_top - r, antenna_x + r, antenna_top + r],
                            fill=CYAN + (255,))

        eye_w = int(head_size * 0.19)
        eye_h = int(head_size * 0.19)
        eye_y = head_box[1] + int(head_size * 0.30)
        for cx in (head_box[0] + int(head_size * 0.32), head_box[0] + int(head_size * 0.68)):
            draw_detail.rounded_rectangle(
                [cx - eye_w // 2, eye_y, cx + eye_w // 2, eye_y + eye_h],
                radius=eye_h // 2,
                fill=(255, 255, 255, 240),
            )

        mouth_y = head_box[1] + int(head_size * 0.62)
        bar_w2 = int(head_size * 0.085)
        gap2 = int(head_size * 0.05)
        total2 = 4 * bar_w2 + 3 * gap2
        start2 = (size - total2) // 2
        for i in range(4):
            bx = start2 + i * (bar_w2 + gap2)
            draw_detail.rounded_rectangle(
                [bx, mouth_y, bx + bar_w2, mouth_y + int(head_size * 0.12)],
                radius=bar_w2 // 2,
                fill=(255, 255, 255, 150),
            )

    return canvas


def save_icon_set() -> None:
    master = build_icon(1024)
    assets = os.path.join(ROOT, "assets", "icon")
    os.makedirs(assets, exist_ok=True)
    master.save(os.path.join(assets, "botmp3_icon.png"))
    build_icon(1024, monochrome=True).save(os.path.join(assets, "botmp3_icon_mono.png"))

    # Iconos legacy por densidad
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for folder, px in densities.items():
        target = os.path.join(ROOT, "android", "app", "src", "main", "res", f"mipmap-{folder}")
        os.makedirs(target, exist_ok=True)
        master.resize((px, px), Image.LANCZOS).save(os.path.join(target, "ic_launcher.png"))

    # Primer plano del icono adaptativo (108dp base, área segura central)
    foreground_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432,
    }
    foreground_master = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    inner = build_icon(1024)
    # Se recorta el fondo para dejar solo el símbolo (área segura del 66 %)
    safe = int(1024 * 0.66)
    offset = (1024 - safe) // 2
    cropped = inner.crop((offset, offset, offset + safe, offset + safe))
    foreground_master.alpha_composite(cropped.resize((int(1024 * 0.86), int(1024 * 0.86)), Image.LANCZOS),
                                      (int(1024 * 0.07), int(1024 * 0.07)))

    for folder, px in foreground_sizes.items():
        target = os.path.join(ROOT, "android", "app", "src", "main", "res", f"drawable-{folder}")
        os.makedirs(target, exist_ok=True)
        foreground_master.resize((px, px), Image.LANCZOS).save(
            os.path.join(target, "ic_launcher_foreground.png")
        )


# --------------------------------------------------------------------------- #
# Capturas de la interfaz (mockups)
# --------------------------------------------------------------------------- #
SCALE = 0.5
DEVICE_W, DEVICE_H = int(1220 * SCALE), int(2712 * SCALE)


def phone_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (DEVICE_W, DEVICE_H), BG_DARK)
    return image, ImageDraw.Draw(image)


def status_bar(draw: ImageDraw.ImageDraw, title: str = "") -> None:
    draw.text((24, 18), "9:41", font=font(15, True), fill=TEXT)
    draw.text((DEVICE_W - 120, 18), "5G", font=font(13, True), fill=TEXT)
    draw.rounded_rectangle([DEVICE_W - 70, 20, DEVICE_W - 30, 32], radius=6,
                           outline=TEXT_DIM, width=2)
    draw.rounded_rectangle([DEVICE_W - 66, 23, DEVICE_W - 44, 29], radius=3, fill=GREEN)
    draw.rectangle([0, 58, DEVICE_W, 60], fill=SURFACE_HIGH)


def app_bar(draw: ImageDraw.ImageDraw, title: str, subtitle: str | None = None,
            actions: int = 3) -> None:
    draw.text((24, 78), title, font=font(28, True), fill=TEXT)
    if subtitle:
        draw.text((24, 116), subtitle, font=font(14), fill=TEXT_DIM)
    for i in range(actions):
        cx = DEVICE_W - 40 - i * 46
        draw.ellipse([cx - 16, 82, cx + 16, 114], outline=SURFACE_HIGH, width=2)
        draw.ellipse([cx - 5, 93, cx + 5, 103], fill=GREEN if i == 0 else TEXT_DIM)


def cover_square(draw: ImageDraw.ImageDraw, x: int, y: int, size: int,
                 seed: int = 0, radius: int = 14) -> None:
    palette = [
        ((29, 185, 84), (0, 224, 198)),
        ((124, 77, 255), (0, 224, 198)),
        ((245, 158, 11), (239, 68, 68)),
        ((56, 189, 248), (124, 77, 255)),
        ((236, 72, 153), (124, 77, 255)),
    ]
    top, bottom = palette[seed % len(palette)]
    tile = Image.new("RGB", (size, size))
    for row in range(size):
        ratio = row / max(1, size - 1)
        color = tuple(round(top[i] + (bottom[i] - top[i]) * ratio) for i in range(3))
        ImageDraw.Draw(tile).line([(0, row), (size, row)], fill=color)
    mask = rounded_mask((size, size), radius)
    # Nota musical minimalista
    note = ImageDraw.Draw(tile)
    note.ellipse([size * 0.30, size * 0.58, size * 0.46, size * 0.74], fill=(0, 0, 0, 90))
    note.rectangle([size * 0.44, size * 0.28, size * 0.48, size * 0.66], fill=(0, 0, 0, 90))
    note.polygon(
        [
            (size * 0.48, size * 0.28),
            (size * 0.70, size * 0.36),
            (size * 0.70, size * 0.44),
            (size * 0.48, size * 0.36),
        ],
        fill=(0, 0, 0, 90),
    )
    return_image = tile.convert("RGBA")
    return_image.putalpha(mask)
    draw._image.paste(return_image, (x, y), return_image)


def song_row(draw: ImageDraw.ImageDraw, y: int, title: str, artist: str, duration: str,
             seed: int, favorite: bool = False) -> None:
    draw.rounded_rectangle([20, y, DEVICE_W - 20, y + 92], radius=18, fill=SURFACE)
    cover_square(draw, 32, y + 10, 72, seed)
    draw.text((120, y + 20), title, font=font(17, True), fill=TEXT)
    draw.text((120, y + 46), artist, font=font(14), fill=TEXT_DIM)
    draw.text((120, y + 66), duration, font=font(12), fill=TEXT_DIM)
    heart_color = RED if favorite else TEXT_DIM
    hx, hy = DEVICE_W - 52, y + 34
    draw.polygon(
        [
            (hx, hy + 14), (hx - 14, hy + 2), (hx - 14, hy - 8), (hx - 7, hy - 13),
            (hx, hy - 6), (hx + 7, hy - 13), (hx + 14, hy - 8), (hx + 14, hy + 2),
        ],
        fill=heart_color,
    )


def bottom_nav(draw: ImageDraw.ImageDraw, active: int = 0) -> None:
    top = DEVICE_H - 150
    draw.rectangle([0, top, DEVICE_W, DEVICE_H], fill=SURFACE)
    labels = ["Canciones", "Listas", "Buscar", "IA", "Ajustes"]
    icons = ["note", "list", "search", "bot", "gear"]
    step = DEVICE_W / 5
    for index in range(5):
        cx = int(step * index + step / 2)
        color = GREEN if index == active else TEXT_DIM
        cy = top + 46
        if icons[index] == "note":
            draw.ellipse([cx - 12, cy + 2, cx - 2, cy + 12], fill=color)
            draw.rectangle([cx - 4, cy - 14, cx - 2, cy + 8], fill=color)
        elif icons[index] == "list":
            for i in range(3):
                draw.line([(cx - 12, cy - 8 + i * 9), (cx + 12, cy - 8 + i * 9)], fill=color, width=3)
        elif icons[index] == "search":
            draw.ellipse([cx - 12, cy - 12, cx + 6, cy + 6], outline=color, width=3)
            draw.line([(cx + 4, cy + 4), (cx + 14, cy + 14)], fill=color, width=3)
        elif icons[index] == "bot":
            draw.rounded_rectangle([cx - 14, cy - 10, cx + 14, cy + 12], radius=8, fill=color)
            draw.ellipse([cx - 7, cy - 4, cx - 2, cy + 2], fill=SURFACE)
            draw.ellipse([cx + 2, cy - 4, cx + 7, cy + 2], fill=SURFACE)
        else:
            draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=color, width=3)
        draw.text((cx - 34, top + 78), labels[index], font=font(12, True), fill=color)


def mini_player(draw: ImageDraw.ImageDraw, title: str, artist: str, bar: float,
                seed: int = 2) -> None:
    top = DEVICE_H - 214
    draw.rectangle([0, top, DEVICE_W, top + 64], fill=SURFACE_HIGH)
    draw.rectangle([0, top, int(DEVICE_W * bar), top + 3], fill=GREEN)
    cover_square(draw, 16, top + 10, 44, seed, radius=10)
    draw.text((72, top + 16), title, font=font(14, True), fill=TEXT)
    draw.text((72, top + 36), artist, font=font(12), fill=TEXT_DIM)
    # Ondas
    x = DEVICE_W - 168
    for i, factor in enumerate([0.4, 0.9, 0.6, 1.0, 0.5]):
        h = int(22 * factor)
        draw.rounded_rectangle([x + i * 8, top + 36 - h, x + i * 8 + 4, top + 36],
                               radius=2, fill=GREEN)
    # Play
    cx, cy = DEVICE_W - 62, top + 32
    draw.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=GREEN)
    draw.polygon([(cx - 7, cy - 11), (cx - 7, cy + 11), (cx + 11, cy)], fill=(10, 10, 15))


def capture_library() -> Image.Image:
    image, draw = phone_canvas()
    status_bar(draw)
    app_bar(draw, "BotMp3", "Biblioteca local · modo offline", actions=3)
    rows = [
        ("Cumbia del Altiplano", "Los Kjarkas", "4:12", True),
        ("Midnight Drive", "Neon Pulse", "3:48", False),
        ("Lluvia de Verano", "Mar Azul", "5:01", True),
        ("Rock Latino 2024", "Varios artistas", "3:22", False),
        ("K-pop Sunset", "Hanabi", "3:05", False),
    ]
    y = 150
    for index, (title, artist, duration, fav) in enumerate(rows):
        song_row(draw, y, title, artist, f"{duration} · MP3 · FLAC ready", index, fav)
        y += 104
    draw.rounded_rectangle([20, y, DEVICE_W - 20, y + 92], radius=18, fill=SURFACE)
    draw.text((40, y + 20), "Importar", font=font(17, True), fill=GREEN)
    draw.text((40, y + 48), "+ Añade MP3, M4A, OGG, FLAC o WAV", font=font(13), fill=TEXT_DIM)
    mini_player(draw, "Cumbia del Altiplano", "Los Kjarkas", 0.42)
    bottom_nav(draw, 0)
    return image


def capture_player() -> Image.Image:
    image, draw = phone_canvas()
    draw.rectangle([0, 0, DEVICE_W, DEVICE_H], fill=(10, 10, 15))
    status_bar(draw)
    size = DEVICE_W - 96
    cover_square(draw, 48, 100, size, 1, radius=22)
    draw.text((48, 100 + size + 26), "Midnight Drive", font=font(26, True), fill=TEXT)
    draw.text((48, 100 + size + 62), "Neon Pulse", font=font(16), fill=TEXT_DIM)
    # Chips
    chip_y = 100 + size + 96
    labels = ["Synthwave", "2024", "#noche"]
    x = 48
    for label in labels:
        width = draw.textlength(label, font=font(13)) + 24
        draw.rounded_rectangle([x, chip_y, x + width, chip_y + 30], radius=15, fill=SURFACE_HIGH)
        draw.text((x + 12, chip_y + 7), label, font=font(13), fill=TEXT)
        x += width + 10
    # Progreso
    bar_y = chip_y + 60
    draw.rounded_rectangle([48, bar_y, DEVICE_W - 48, bar_y + 8], radius=4, fill=SURFACE_HIGH)
    draw.rounded_rectangle([48, bar_y, 48 + int((DEVICE_W - 96) * 0.42), bar_y + 8], radius=4, fill=GREEN)
    draw.ellipse([48 + int((DEVICE_W - 96) * 0.42) - 9, bar_y - 5,
                  48 + int((DEVICE_W - 96) * 0.42) + 9, bar_y + 13], fill=GREEN)
    draw.text((48, bar_y + 18), "1:37", font=font(13), fill=TEXT_DIM)
    time_text = "3:48"
    draw.text((DEVICE_W - 48 - draw.textlength(time_text, font=font(13)), bar_y + 18),
              time_text, font=font(13), fill=TEXT_DIM)
    # Controles
    cy = bar_y + 110
    draw.ellipse([60, cy - 18, 96, cy + 18], outline=TEXT_DIM, width=3)  # shuffle
    draw.polygon([(150, cy - 20), (150, cy + 20), (176, cy)], fill=TEXT)  # prev
    draw.polygon([(150, cy - 20), (150, cy + 20), (176, cy)], fill=TEXT)
    big = 52
    bx = DEVICE_W // 2 - big
    draw.ellipse([bx, cy - big, bx + big * 2, cy + big], fill=GREEN)
    draw.polygon([(bx + 40, cy - 26), (bx + 40, cy + 26), (bx + 78, cy)], fill=(10, 10, 15))
    draw.polygon([(DEVICE_W - 176, cy - 20), (DEVICE_W - 176, cy + 20), (DEVICE_W - 150, cy)], fill=TEXT)
    draw.polygon([(DEVICE_W - 150, cy - 20), (DEVICE_W - 150, cy + 20), (DEVICE_W - 124, cy)], fill=TEXT)
    draw.ellipse([DEVICE_W - 96, cy - 18, DEVICE_W - 60, cy + 18], outline=TEXT_DIM, width=3)
    # Acciones secundarias
    actions = [("1.00x", "velocidad"), ("Volumen", "audio"), ("DJ IA", "bot"), ("Metadatos", "info")]
    ax = 40
    for label, kind in actions:
        width = 120
        draw.rounded_rectangle([ax, cy + 84, ax + width, cy + 140], radius=16, fill=SURFACE)
        color = VIOLET if kind == "bot" else TEXT
        draw.text((ax + 16, cy + 96), label, font=font(14, True), fill=color)
        draw.text((ax + 16, cy + 118), kind, font=font(11), fill=TEXT_DIM)
        ax += width + 12
    # Onda sonora
    x = DEVICE_W // 2 - 60
    for i, factor in enumerate([0.5, 1.0, 0.7, 0.35, 0.9, 0.6]):
        h = int(30 * factor)
        draw.rounded_rectangle([x + i * 22, DEVICE_H - 210 - h, x + i * 22 + 8, DEVICE_H - 210],
                               radius=4, fill=GREEN)
    mini_player(draw, "Midnight Drive", "Neon Pulse", 0.42, 1)
    bottom_nav(draw, 0)
    return image


def capture_cover_editor() -> Image.Image:
    image, draw = phone_canvas()
    status_bar(draw)
    app_bar(draw, "Editor de carátula", "Brillo · contraste · filtros · texto", actions=2)
    # Vista previa
    preview = Image.new("RGB", (DEVICE_W - 96, 420))
    for row in range(420):
        ratio = row / 419
        color = tuple(round(VIOLET[i] + (CYAN[i] - VIOLET[i]) * ratio) for i in range(3))
        ImageDraw.Draw(preview).line([(0, row), (DEVICE_W - 96, row)], fill=color)
    note = ImageDraw.Draw(preview)
    note.ellipse([160, 240, 260, 340], fill=(0, 0, 0, 70))
    note.rectangle([250, 90, 262, 290], fill=(0, 0, 0, 70))
    note.rounded_rectangle([60, 340, DEVICE_W - 156, 396], radius=12, fill=(0, 0, 0, 110))
    note.text((80, 356), "BOTMP3 · EDITION", font=font(20, True), fill=(255, 255, 255))
    mask = rounded_mask((DEVICE_W - 96, 420), 22)
    preview = preview.convert("RGBA")
    preview.putalpha(mask)
    image.paste(preview, (48, 150), preview)
    # Sección de ajustes
    y = 610
    draw.text((48, y), "Ajustes de imagen", font=font(17, True), fill=TEXT)
    y += 34
    for label, value, accent in [
        ("Brillo", 0.18, GREEN),
        ("Contraste", 0.32, GREEN),
        ("Saturación", 0.24, GREEN),
        ("Temperatura", -0.10, CYAN),
        ("Velo", 0.05, CYAN),
    ]:
        draw.text((48, y), label, font=font(14), fill=TEXT)
        draw.text((DEVICE_W - 120, y), f"{value:+.2f}", font=font(13), fill=TEXT_DIM)
        draw.rounded_rectangle([48, y + 24, DEVICE_W - 48, y + 32], radius=4, fill=SURFACE_HIGH)
        width = int((DEVICE_W - 96) * (0.5 + value / 2))
        draw.rounded_rectangle([48, y + 24, 48 + width, y + 32], radius=4, fill=accent)
        draw.ellipse([48 + width - 10, y + 18, 48 + width + 10, y + 38], fill=accent)
        y += 66
    # Filtros
    draw.text((48, y + 6), "Filtros", font=font(17, True), fill=TEXT)
    y += 40
    x = 48
    for label, active in [("Original", False), ("Vintage", True), ("ByN", False), ("Cálido", False)]:
        width = draw.textlength(label, font=font(14)) + 32
        fill = GREEN if active else SURFACE_HIGH
        draw.rounded_rectangle([x, y, x + width, y + 40], radius=20, fill=fill)
        draw.text((x + 16, y + 11), label, font=font(14, True),
                  fill=(10, 10, 15) if active else TEXT)
        x += width + 10
    y += 62
    draw.text((48, y), "Texto o logo", font=font(17, True), fill=TEXT)
    draw.rounded_rectangle([48, y + 30, DEVICE_W - 48, y + 88], radius=14, fill=SURFACE)
    draw.text((66, y + 48), "BOTMP3 · EDITION", font=font(15), fill=TEXT)
    y += 108
    draw.rounded_rectangle([48, y, DEVICE_W - 48, y + 56], radius=16, fill=GREEN)
    draw.text((DEVICE_W / 2 - 130, y + 16), "Aplicar a la canción", font=font(16, True),
              fill=(10, 10, 15))
    bottom_nav(draw, 0)
    return image


def capture_ai() -> Image.Image:
    image, draw = phone_canvas()
    status_bar(draw)
    app_bar(draw, "IA musical", "OpenAI · DeepSeek · Gemini · Claude", actions=2)
    # Selector de proveedor
    x = 24
    for label, active in [("OpenAI", False), ("DeepSeek", True), ("Gemini", False), ("Claude", False)]:
        width = draw.textlength(label, font=font(14)) + 36
        fill = VIOLET if active else SURFACE_HIGH
        draw.rounded_rectangle([x, 132, x + width, 176], radius=22, fill=fill)
        draw.text((x + 18, 144), label, font=font(14, True), fill=TEXT)
        x += width + 10
    draw.text((24, 190), "12 canciones · 6 géneros · 3 listas", font=font(13), fill=TEXT_DIM)
    # Conversación
    def bubble(y: int, text: str, user: bool, lines: int = 2) -> int:
        width = int(DEVICE_W * (0.72 if user else 0.80))
        bx = DEVICE_W - 24 - width if user else 24
        height = 34 + lines * 22
        draw.rounded_rectangle([bx, y, bx + width, y + height], radius=18,
                               fill=(29, 60, 43) if user else (38, 32, 62))
        if not user:
            draw.text((bx + 16, y + 10), "IA", font=font(11, True), fill=CYAN)
        draw.multiline_text((bx + 16, y + 26), text, font=font(14), fill=TEXT, spacing=4)
        return y + height + 14

    y = 226
    y = bubble(y, "Hazme una playlist de 30 canciones de rock\nlatino 2020-2025 con artistas latinos", True, 2)
    y = bubble(y, "Listo. Mezclo rock alternativo latino reciente con\nclásicos del 2000 para dar contraste:", False, 2)
    # Tarjeta de recomendaciones
    card_h = 300
    draw.rounded_rectangle([24, y, DEVICE_W - 24, y + card_h], radius=20, fill=SURFACE)
    draw.text((44, y + 18), "Playlist: Rock Latino 2020-2025", font=font(16, True), fill=TEXT)
    items = [
        ("La Última Vez", "Los Mesoneros", "rock alternativo, energía media"),
        ("Amanecer", "Bomba Estéreo", "cumbia-rock, ritmo alto"),
        ("Fuego Nuevo", "Zoé", "psicodelia, 2023"),
    ]
    iy = y + 52
    for title, artist, reason in items:
        draw.ellipse([44, iy, 76, iy + 32], fill=GREEN_DIM)
        draw.polygon([(56, iy + 8), (56, iy + 24), (68, iy + 16)], fill=(10, 10, 15))
        draw.text((90, iy), title, font=font(15, True), fill=TEXT)
        draw.text((90, iy + 20), f"{artist} · {reason}", font=font(12), fill=TEXT_DIM)
        iy += 54
    draw.rounded_rectangle([44, y + card_h - 62, DEVICE_W / 2 - 10, y + card_h - 18],
                           radius=16, fill=GREEN)
    draw.text((64, y + card_h - 50), "Reproducir 12", font=font(14, True), fill=(10, 10, 15))
    draw.rounded_rectangle([DEVICE_W / 2 + 10, y + card_h - 62, DEVICE_W - 44, y + card_h - 18],
                           radius=16, outline=GREEN, width=2)
    draw.text((DEVICE_W / 2 + 30, y + card_h - 50), "Crear lista", font=font(14, True), fill=GREEN)
    # Acciones rápidas + entrada
    y += card_h + 20
    x = 24
    for label in ["Recomiéndame", "Playlist de 30", "Modo DJ", "Crear canción"]:
        width = draw.textlength(label, font=font(13)) + 30
        draw.rounded_rectangle([x, y, x + width, y + 40], radius=20, fill=SURFACE_HIGH)
        draw.text((x + 15, y + 11), label, font=font(13, True), fill=TEXT)
        x += width + 8
    y += 62
    draw.rounded_rectangle([24, y, DEVICE_W - 110, y + 58], radius=18, fill=SURFACE)
    draw.text((44, y + 18), "Pídele música, listas o ideas…", font=font(14), fill=TEXT_DIM)
    draw.ellipse([DEVICE_W - 94, y, DEVICE_W - 34, y + 58], fill=GREEN)
    draw.polygon([(DEVICE_W - 74, y + 20), (DEVICE_W - 74, y + 38), (DEVICE_W - 56, y + 29)],
                 fill=(10, 10, 15))
    bottom_nav(draw, 3)
    return image


def capture_search() -> Image.Image:
    image, draw = phone_canvas()
    status_bar(draw)
    app_bar(draw, "Buscar", "Título · artista · álbum · año · #tags", actions=1)
    draw.rounded_rectangle([24, 138, DEVICE_W - 24, 200], radius=18, fill=SURFACE)
    draw.text((48, 158), "bolivia cumbia 2020", font=font(15), fill=TEXT)
    draw.ellipse([DEVICE_W - 80, 154, DEVICE_W - 56, 178], outline=TEXT_DIM, width=3)
    x = 24
    for label, active in [("Rock", False), ("Pop", False), ("Reggaetón", False),
                          ("Cumbia", True), ("Latin", True)]:
        width = draw.textlength(label, font=font(13)) + 30
        draw.rounded_rectangle([x, 214, x + width, 256], radius=21,
                               fill=GREEN_DIM if active else SURFACE_HIGH)
        draw.text((x + 15, 226), label, font=font(13, True), fill=TEXT)
        x += width + 8
    draw.rounded_rectangle([24, 272, DEVICE_W - 24, 330], radius=18, fill=(38, 32, 62))
    draw.text((48, 288), "Búsqueda inteligente: entiendo mood y época", font=font(14, True),
              fill=CYAN)
    rows = [
        ("Cumbia del Altiplano", "Los Kjarkas", "1998 · Cumbia", True),
        ("Verano Boliviano", "Grupo Frontera", "2023 · Cumbia", False),
        ("Fiesta en La Paz", "Los Kjarkas", "2021 · Folk", False),
        ("Cumbia del Altiplano (Live)", "Los Kjarkas", "2019 · En vivo", False),
    ]
    y = 350
    for title, artist, meta, fav in rows:
        song_row(draw, y, title, artist, meta, y, fav)
        y += 104
    mini_player(draw, "Verano Boliviano", "Grupo Frontera", 0.66, 3)
    bottom_nav(draw, 2)
    return image


def save_captures() -> None:
    target = os.path.join(ROOT, "capturas")
    os.makedirs(target, exist_ok=True)
    captures = {
        "01_biblioteca.png": capture_library(),
        "02_reproductor.png": capture_player(),
        "03_editor_caratula.png": capture_cover_editor(),
        "04_ia_multimodelo.png": capture_ai(),
        "05_busqueda_avanzada.png": capture_search(),
    }
    for name, image in captures.items():
        image.save(os.path.join(target, name))


if __name__ == "__main__":
    save_icon_set()
    save_captures()
    print("Icono y capturas generados en:", ROOT)
