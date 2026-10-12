#!/usr/bin/env python3
"""Cuts the pictures of "Mila und Nuss" out of the comic's PDF edition.

    python3 tool/comic/cut_panels.py <Mila_und_Nuss.pdf>

The PDF is the comic as it is printed: nine pages, each one picture of
2100 by 1700 pixels with the words drawn in. It comes in German, English
and Spanish, with the same pictures in all three, so any of them will do.
The app sets its own words -- they follow the text size and the language --
so it carries only the drawings: the cover, and the four panels of each of
the six chapters, each cut from inside its frame. The words are in
`kids_comic_de.dart`, `kids_comic_en.dart` and `kids_comic_es.dart`.

Each page is taken out of the PDF as the JPEG it is stored as, so nothing
is drawn again. The panels keep their size; the cover is scaled to 1400
pixels across. They are written as WebP, which Flutter decodes on every
platform the app runs on, at about half the size of a JPEG.

The frames sit at the same pixels on every chapter page. The script checks
that they still do before it cuts anything, so a PDF laid out differently
stops it rather than cutting the wrong part of a page.

Needs pypdf and Pillow (`python3 -m pip install --user pypdf pillow`).
"""

import io
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageStat
import pypdf

ASSETS = Path(__file__).resolve().parents[2] / "preppsuite_flutter" / "assets" / "comic"

# Pages 2 to 7, in the order the comic tells them. The ids are the
# chapters' ids in the app.
CHAPTERS = ("vorrat", "strom", "sirene", "sturm", "feuer", "krieg")

# The middle of each frame's border, which is three pixels wide: the left
# and right edges of the two columns, the top and bottom edges of the two
# rows. Panel 1 is top left, then across, then down.
COLUMNS = ((41, 1028), (1072, 2059))
ROWS = ((267, 831), (962, 1526))
# Far enough inside the border to leave its softened edge behind, and the
# dark edge the war chapter's pictures have of their own.
INSET = 6

# Two panels of the siren chapter carry a strip of another picture on
# their left, behind a white line, already in the PDF. It is cut off, and
# as much off the top, so the panel keeps its shape.
LEFT_STRIP = {"sirene-2": 60, "sirene-4": 60}

# The panel's number, a yellow disc with a white ring in the bottom left
# corner, as the box it fills in a panel cut at INSET. Cutting the strip
# off takes the disc with it, so it is put back at the same distance from
# the corner as in every other panel.
BADGE = (7, 503, 57, 553)

# The cover's picture runs the full width between the title and the line
# below it.
COVER_ROWS = (371, 1444)
COVER_WIDTH = 1400

QUALITY = 82


def pages(pdf):
    for page in pypdf.PdfReader(pdf).pages:
        (image,) = page["/Resources"]["/XObject"].values()
        yield Image.open(io.BytesIO(image.get_object().get_data())).convert("RGB")


def dark(image, box):
    """The share of pixels in [box] dark enough to be a frame."""
    strip = image.crop(box).convert("L").point(lambda v: 255 if v < 70 else 0)
    return ImageStat.Stat(strip).mean[0] / 255


def check_frames(image, number):
    for left, right in COLUMNS:
        for top, bottom in ROWS:
            edges = (
                (left, top + 20, left + 1, bottom - 20),
                (right, top + 20, right + 1, bottom - 20),
                (left + 20, top, right - 20, top + 1),
                (left + 20, bottom, right - 20, bottom + 1),
            )
            if any(dark(image, edge) < 0.9 for edge in edges):
                sys.exit(f"page {number}: a frame is not where it was; "
                         "the layout of the PDF has changed")


def badge_mask():
    size = BADGE[2] - BADGE[0]
    large = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(large).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    return large.resize((size, size), Image.LANCZOS)


def without_strip(picture, strip):
    left, top, right, bottom = BADGE
    disc = picture.crop(BADGE)
    cut = picture.crop((
        strip, round(strip * picture.height / picture.width),
        picture.width, picture.height,
    ))
    corner_gap = picture.height - bottom
    cut.paste(disc, (left, cut.height - corner_gap - (bottom - top)), badge_mask())
    return cut


def save(image, name):
    image.save(ASSETS / f"{name}.webp", "WEBP", quality=QUALITY, method=6)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    cover, *rest = pages(sys.argv[1])
    chapters = rest[: len(CHAPTERS)]
    if len(chapters) != len(CHAPTERS) or cover.size != (2100, 1700):
        sys.exit("not the comic this script knows: expected nine pages of 2100 by 1700")
    for number, page in enumerate(chapters, 2):
        check_frames(page, number)

    for old in ASSETS.glob("*"):
        old.unlink()
    top, bottom = COVER_ROWS
    picture = cover.crop((0, top + 2, cover.width, bottom - 1))
    height = round(picture.height * COVER_WIDTH / picture.width)
    save(picture.resize((COVER_WIDTH, height), Image.LANCZOS), "titel")
    for chapter, page in zip(CHAPTERS, chapters):
        frames = [(column, row) for row in ROWS for column in COLUMNS]
        for panel, ((left, right), (top, bottom)) in enumerate(frames, 1):
            box = (left + INSET, top + INSET, right - INSET + 1, bottom - INSET + 1)
            picture = page.crop(box)
            strip = LEFT_STRIP.get(f"{chapter}-{panel}")
            if strip:
                picture = without_strip(picture, strip)
            save(picture, f"{chapter}-{panel}")
    for written in sorted(ASSETS.glob("*.webp")):
        with Image.open(written) as image:
            print(f"{written.name:14} {image.width}x{image.height} "
                  f"{written.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
