#!/usr/bin/env python3
"""Draws the PreppSuite app icon and writes every platform's copies.

The mark is a house whose base tapers into a shield: household and
protection in one silhouette rather than two stacked symbols. The door is
the only detail, and it is dropped below 40 pixels -- what remains still
reads as a house, which is the graceful way for this to fail.

Run from anywhere:

    python3 tool/app_icon.py

Everything is drawn at 8x and downsampled, because PIL fills polygons
without anti-aliasing.
"""

import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "preppsuite_flutter")

# A pair either side of the app's own seed colour (`_seedColor` in
# lib/app.dart), so the icon belongs to the same family as the UI.
GREEN_TOP = (56, 142, 60)
GREEN_BOTTOM = (23, 78, 30)
MARK = (244, 250, 243)

SS = 8

# Below this the door is noise rather than detail.
DOOR_MIN_PX = 40


def _bezier(p0, p1, p2, steps=96):
    out = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        out.append(
            (
                u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
            )
        )
    return out


def _mark_mask(size, inset, door):
    """The mark as a coverage mask, so it can be filled and punched
    without touching whatever it is sitting on."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)

    box = size - 2 * inset

    def x(f):
        return inset + f * box

    def y(f):
        return inset + f * box

    wall, overhang = 0.185, 0.045
    eave, shoulder = y(0.385), y(0.685)
    tip = (x(0.5), y(0.975))

    outline = [
        (x(0.5), y(0.03)),
        (x(1 - overhang), eave),
        (x(1 - wall), eave),
        (x(1 - wall), shoulder),
    ]
    outline += _bezier((x(1 - wall), shoulder), (x(0.79), y(0.895)), tip)
    outline += _bezier(tip, (x(0.21), y(0.895)), (x(wall), shoulder))
    outline += [(x(wall), eave), (x(overhang), eave)]
    draw.polygon(outline, fill=255)

    if door:
        draw.rounded_rectangle(
            (x(0.412), y(0.515), x(0.588), y(0.805)),
            radius=int(box * 0.088),
            corners=(True, True, False, False),
            fill=0,
        )

    return mask


def _gradient(size):
    img = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(img)
    for row in range(size):
        t = row / (size - 1)
        draw.line(
            [(0, row), (size, row)],
            fill=tuple(
                round(a + (b - a) * t) for a, b in zip(GREEN_TOP, GREEN_BOTTOM)
            )
            + (255,),
        )
    return img


def render(size, inset=0.12, radius=None, background=True, door=None):
    if door is None:
        door = size >= DOOR_MIN_PX

    w = size * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))

    if background:
        if radius is None:
            img.paste(_gradient(w), (0, 0))
        else:
            rounded = Image.new("L", (w, w), 0)
            ImageDraw.Draw(rounded).rounded_rectangle(
                (0, 0, w - 1, w - 1), radius=int(w * radius), fill=255
            )
            img.paste(_gradient(w), (0, 0), rounded)

    img.paste(
        Image.new("RGBA", (w, w), MARK + (255,)),
        (0, 0),
        _mark_mask(w, int(w * inset), door),
    )
    return img.resize((size, size), Image.LANCZOS)


def flatten(img):
    """iOS rejects an app icon that has an alpha channel at all."""
    out = Image.new("RGB", img.size, GREEN_TOP)
    out.paste(img, (0, 0), img)
    return out


def write(path, img):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("   " + os.path.relpath(path, ROOT))


def main():
    print("iOS")
    ios = os.path.join(APP, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
    with open(os.path.join(ios, "Contents.json")) as fh:
        for entry in json.load(fh)["images"]:
            name = entry.get("filename")
            if not name:
                continue
            px = round(float(entry["size"].split("x")[0]) * int(entry["scale"][0]))
            # iOS applies its own mask, so the artwork fills the square.
            write(os.path.join(ios, name), flatten(render(px)))

    print("macOS")
    mac = os.path.join(APP, "macos/Runner/Assets.xcassets/AppIcon.appiconset")
    for px in (16, 32, 64, 128, 256, 512, 1024):
        # Nothing rounds a macOS icon for you, and the platform expects
        # air around the shape.
        write(
            os.path.join(mac, f"app_icon_{px}.png"),
            render(px, inset=0.185, radius=0.225),
        )

    print("Android")
    res = os.path.join(APP, "android/app/src/main/res")
    for folder, px in (
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ):
        write(
            os.path.join(res, folder, "ic_launcher.png"),
            flatten(render(px, radius=0.22)),
        )
        # An adaptive foreground is 108dp for a 72dp visible circle, so
        # the mark has to sit well inside it or the launcher crops it.
        write(
            os.path.join(res, folder, "ic_launcher_foreground.png"),
            render(round(px * 108 / 48), inset=0.30, background=False, door=px >= 48),
        )

    print("Windows")
    ico = os.path.join(APP, "windows/runner/resources/app_icon.ico")
    flatten(render(256)).save(
        ico, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)]
    )
    print("   " + os.path.relpath(ico, ROOT))

    print("Linux")
    write(
        os.path.join(APP, "linux/runner/resources/app_icon.png"),
        render(512, inset=0.145, radius=0.22),
    )

    print("Web")
    web = os.path.join(APP, "web")
    write(os.path.join(web, "favicon.png"), flatten(render(64, radius=0.22)))
    for px in (192, 512):
        write(os.path.join(web, "icons", f"Icon-{px}.png"), flatten(render(px)))
        # A maskable icon gets cropped by the launcher, so it bleeds to
        # the edge and keeps the mark inside the safe circle.
        write(
            os.path.join(web, "icons", f"Icon-maskable-{px}.png"),
            flatten(render(px, inset=0.27)),
        )


if __name__ == "__main__":
    main()
