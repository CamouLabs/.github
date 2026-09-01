#!/usr/bin/env python3
"""Draw Quark's app icon into the asset catalogue.

The mark is a single electron on one tilted orbit around a bright nucleus: the
smallest possible picture of "the thing everything else is made of", which is
also what the app is trying to teach. Drawn at 4x and downsampled, because
supersampling gives cleaner curves than any antialiasing flag.

    python3 .tooling/generate_app_icon.py
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Quark" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"

SIZE = 1024
SCALE = 4
CANVAS = SIZE * SCALE

INDIGO_TOP = (78, 78, 210)
INDIGO_BOTTOM = (46, 42, 120)
SPARK = (255, 186, 84)
NUCLEUS = (255, 255, 255)


def gradient(size: int) -> Image.Image:
    """Diagonal indigo wash, matching QuarkTheme's primary ramp."""
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        for x in range(size):
            # Diagonal position, 0 at top-left and 1 at bottom-right.
            t = (x + y) / (2 * (size - 1))
            pixels[x, y] = tuple(
                round(INDIGO_TOP[channel] + (INDIGO_BOTTOM[channel] - INDIGO_TOP[channel]) * t)
                for channel in range(3)
            )
    return image


def glow(image: Image.Image, box: list[float], fill: tuple[int, int, int, int]) -> None:
    """Composite a blurred disc behind something bright.

    Drawing straight onto an RGBA image writes the alpha channel rather than
    blending with it, so a 16%-opacity halo would end up as a hard white disc
    once the icon is flattened to RGB. Compositing a blurred layer avoids that
    and gives the falloff a flat disc would not have.
    """
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=fill)
    radius = (box[2] - box[0]) * 0.22
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius)))


def draw_mark(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    centre = CANVAS / 2
    orbit_radius_x = CANVAS * 0.315
    orbit_radius_y = CANVAS * 0.128
    tilt = -28

    # Two orbits, drawn as rotated ellipses on their own layers so the tilt
    # applies to the stroke rather than to the whole icon.
    for angle, alpha, width in ((tilt, 240, CANVAS * 0.017), (tilt + 62, 110, CANVAS * 0.011)):
        layer = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        layer_draw = ImageDraw.Draw(layer)
        layer_draw.ellipse(
            [
                centre - orbit_radius_x,
                centre - orbit_radius_y,
                centre + orbit_radius_x,
                centre + orbit_radius_y,
            ],
            outline=(255, 255, 255, alpha),
            width=round(width),
        )
        image.alpha_composite(layer.rotate(angle, resample=Image.BICUBIC))

    # Nucleus, with a soft halo so it reads at 40 pt.
    halo = CANVAS * 0.092
    glow(
        image,
        [centre - halo, centre - halo, centre + halo, centre + halo],
        (255, 255, 255, 70),
    )
    core = CANVAS * 0.052
    draw.ellipse(
        [centre - core, centre - core, centre + core, centre + core],
        fill=NUCLEUS + (255,),
    )

    # One electron, parked on the primary orbit at the top right. The layers
    # above were rotated, so the same rotation is applied to this point by hand.
    theta = math.radians(-34)
    radians = math.radians(tilt)
    ex = orbit_radius_x * math.cos(theta)
    ey = orbit_radius_y * math.sin(theta)
    x = centre + ex * math.cos(radians) + ey * math.sin(radians)
    y = centre - ex * math.sin(radians) + ey * math.cos(radians)
    electron = CANVAS * 0.036
    glow(
        image,
        [x - electron * 1.9, y - electron * 1.9, x + electron * 1.9, y + electron * 1.9],
        SPARK + (90,),
    )
    draw.ellipse(
        [x - electron, y - electron, x + electron, y + electron],
        fill=SPARK + (255,),
    )


def main() -> None:
    image = gradient(CANVAS).convert("RGBA")
    draw_mark(image)
    icon = image.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUTPUT, format="PNG", optimize=True)
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({SIZE}×{SIZE})")


if __name__ == "__main__":
    main()
