"""Corrections to supplied first aid charts, applied by `infographic.py`.

A chart comes as a finished picture from outside this repository. When
one is right except for a few words, the words are corrected here rather
than the chart kept out, and the correction is written down rather than
made by hand in an image editor: it is tied to the exact picture it was
measured on (by its SHA-256), says what it changes and why, and is
applied again every time that picture is converted. A newly drawn
picture has another hash, gets none of this, and has to be checked from
scratch.

Two ways of changing text, in this order of preference:

* Moving the picture's own letters: a word taken out and the rest of the
  line closed up, or a letter taken from elsewhere on the same chart.
  The letters stay the chart's own, in its font and its ink.
* Setting new text, where no rearrangement says it: in Arial Narrow from
  macOS, which of the faces there is nearest the charts' own condensed
  sans in width and weight (compared against Avenir Next Condensed and
  PT Sans Narrow). This runs on the Mac that builds the releases and
  nowhere else.

Ink is found by how much darker a pixel is than the plane fitted through
the light pixels around it, so a soft shading behind the text survives.
"""

from dataclasses import dataclass
import hashlib

import numpy as np
from PIL import Image, ImageDraw, ImageFont

NARROW = "/System/Library/Fonts/Supplemental/Arial Narrow.ttf"
NARROW_BOLD = "/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf"


def _plane(pixels, mask):
    """A plane per channel through the pixels where [mask] is true."""
    h, w, _ = pixels.shape
    ys, xs = np.nonzero(mask)
    # Coordinates scaled to 0..1, which keeps the fit well conditioned.
    design = np.column_stack([xs / w, ys / h, np.ones(len(xs))])
    yy, xx = np.mgrid[0:h, 0:w]
    out = np.empty_like(pixels, dtype=float)
    for c in range(3):
        a, b, k = np.linalg.lstsq(design, pixels[ys, xs, c].astype(float), rcond=None)[0]
        out[..., c] = a * xx / w + b * yy / h + k
    return out


@dataclass
class Ink:
    """The text in a box: how much ink each pixel holds, and its colour."""

    alpha: np.ndarray
    colour: np.ndarray

    def columns(self, threshold=0.25):
        """Runs of columns that carry ink, as (start, end) pairs."""
        used = (self.alpha > threshold).any(axis=0)
        runs, start = [], None
        for x, on in enumerate(used):
            if on and start is None:
                start = x
            elif not on and start is not None:
                runs.append((start, x))
                start = None
        if start is not None:
            runs.append((start, len(used)))
        return runs


def background(image, box):
    """The pixels of [box], and the plane fitted through its paper."""
    pixels = np.asarray(image.crop(box)).astype(float)
    lum = pixels.mean(axis=2)
    # Text is sparse in a line's box, so most of it is paper.
    paper = lum > np.percentile(lum, 90) - 25
    return pixels, _plane(pixels, paper)


def ink(image, box):
    pixels, fitted = background(image, box)
    lum, base = pixels.mean(axis=2), fitted.mean(axis=2)
    darkest = np.percentile(lum, 1)
    colour = pixels[lum <= darkest + 8].mean(axis=0)
    alpha = np.clip((base - lum) / np.maximum(base - colour.mean(), 1), 0, 1)
    alpha[alpha < 0.08] = 0
    return Ink(alpha, colour)


def erase(image, box, ring=6):
    """Paints the paper over all of [box], text and its soft halo alike.

    The paper is fitted on a ring around the box rather than inside it:
    the charts' letters carry a light halo, and a fit taken from inside
    the box would paint that halo back as a pale smear. Pixels in the
    ring that are far from its median -- other letters, an edge -- are
    left out of the fit. A little noise in the paper's own grain keeps
    the patch from looking flatter than what surrounds it.
    """
    x0, y0, x1, y1 = box
    ox0, oy0 = max(x0 - ring, 0), max(y0 - ring, 0)
    ox1, oy1 = min(x1 + ring, image.width), min(y1 + ring, image.height)
    pixels = np.asarray(image.crop((ox0, oy0, ox1, oy1))).astype(float)
    inner = np.zeros(pixels.shape[:2], bool)
    inner[y0 - oy0:y1 - oy0, x0 - ox0:x1 - ox0] = True
    lum = pixels.mean(axis=2)
    median = np.median(lum[~inner])
    paper = ~inner & (np.abs(lum - median) < 18)
    fitted = _plane(pixels, paper)
    grain = (pixels[paper] - fitted[paper]).std(axis=0)
    noise = np.random.default_rng(0).normal(0, 1, pixels.shape) * grain * 0.8
    pixels[inner] = (fitted + noise)[inner]
    image.paste(
        Image.fromarray(pixels[y0 - oy0:y1 - oy0, x0 - ox0:x1 - ox0]
                        .clip(0, 255).astype(np.uint8)),
        (x0, y0),
    )


def paste_ink(image, at, alpha, colour):
    """Lays [alpha] in [colour] over [image] with its top left at [at]."""
    x, y = at
    h, w = alpha.shape
    region = np.asarray(image.crop((x, y, x + w, y + h))).astype(float)
    a = alpha[..., None]
    out = region * (1 - a) + colour * a
    image.paste(Image.fromarray(out.clip(0, 255).astype(np.uint8)), (x, y))


def set_line(image, left, baseline, text, size, colour, *, bold=False):
    """Sets one line of new text, its baseline at [baseline].

    Drawn at four times the size and scaled down, which smooths the edges
    the way the charts' own text is smoothed.
    """
    scale = 4
    font = ImageFont.truetype(NARROW_BOLD if bold else NARROW, size * scale)
    layer = Image.new("L", (image.width * scale, image.height * scale), 0)
    ImageDraw.Draw(layer).text((left * scale, baseline * scale), text,
                               font=font, fill=255, anchor="ls")
    layer = layer.resize(image.size, Image.LANCZOS)
    paste_ink(image, (0, 0), np.asarray(layer).astype(float) / 255,
              np.asarray(colour, float))


def dot(image, centre, radius, colour):
    layer = Image.new("L", (radius * 8, radius * 8), 0)
    ImageDraw.Draw(layer).ellipse((0, 0, radius * 8 - 1, radius * 8 - 1), fill=255)
    layer = layer.resize((radius * 2, radius * 2), Image.LANCZOS)
    cx, cy = centre
    paste_ink(image, (cx - radius, cy - radius),
              np.asarray(layer).astype(float) / 255, np.asarray(colour, float))


def text_width(text, size, bold=False):
    font = ImageFont.truetype(NARROW_BOLD if bold else NARROW, size)
    return font.getlength(text)


def _closed_up(image, line, cut_from, cut_to):
    """Takes columns [cut_from, cut_to) out of [line] and closes the gap."""
    k = ink(image, line)
    x0 = line[0]
    alpha = np.hstack([k.alpha[:, :cut_from - x0], k.alpha[:, cut_to - x0:]])
    erase(image, line)
    paste_ink(image, line[:2], alpha, k.colour)


# Each correction was measured on the picture named in its key, at its
# pixel coordinates, and is applied to nothing else.


def _anaphylaxis(image):
    # "Beine nicht hochlagern." -> "Beine hochlagern.": "nicht " out.
    _closed_up(image, (528, 1003, 735, 1030), 595, 637)


def _dehydration(image):
    # "Keines Kind" -> "Kleines Kind": an l from "allem" in the line
    # below, set between K (115-125) and e on the same baseline, and the
    # line centred again.
    line = (100, 1255, 225, 1277)
    k = ink(image, line)
    below = ink(image, (100, 1276, 120, 1300))
    letter = below.alpha[:, 106 - 100:111 - 100]

    def baseline(alpha):
        return np.nonzero((alpha > 0.25).any(axis=1))[0].max()

    shift = baseline(k.alpha[:, 115 - 100:126 - 100]) - baseline(letter)
    placed = np.zeros((k.alpha.shape[0], letter.shape[1]))
    for y in range(letter.shape[0]):
        if 0 <= y + shift < placed.shape[0]:
            placed[y + shift] = letter[y]
    split, space = 126 - 100, np.zeros((k.alpha.shape[0], 1))
    alpha = np.hstack([k.alpha[:, :split], space, placed, space,
                       k.alpha[:, split:]])
    grown = alpha.shape[1] - k.alpha.shape[1]
    erase(image, line)
    paste_ink(image, (line[0] - grown // 2, line[1]), alpha, k.colour)


def _fracture(image):
    # The last line of "Notruf 112 nur bei:" reads "Oberschenkelbruch
    # (nicht mehr beweg- oder" and then breaks off into garbled marks.
    # The bracket and the garbled line go; "Oberschenkelbruch" stays,
    # which is what the guide says.
    erase(image, (190, 1225, 364, 1246))
    erase(image, (30, 1246, 364, 1264))


def _burns(image):
    # The box under step 2 cooled children and infants like adults. The
    # guide follows the AWMF S2k guideline on burns in childhood (2024):
    # children only small areas of the limbs, at most 10 minutes,
    # lukewarm; infants, and a child's trunk and head, not at all. The
    # box now says that, and that a burnt child is always a 112 call.
    lines = [
        ("Kinder: nur kleine Stellen an", False, 392),
        ("Armen und Beinen, höchstens", False, 414),
        ("10 Minuten, handwarm.", False, 436),
        ("Säuglinge gar nicht kühlen, bei", False, 471),
        ("Kindern nicht Rumpf und Kopf.", False, 493),
        ("Das Kind warm halten.", False, 515),
        ("Bei Kindern immer Notruf 112.", True, 552),
    ]
    # Clear of the hand above row 432 and of the baby below it.
    for text, bold, baseline in lines:
        room = 237 if baseline < 432 else 245
        assert text_width(text, 19 if bold else 21, bold) <= room + 1, text
    erase(image, (528, 432, 812, 560))
    erase(image, (528, 364, 800, 432))
    for text, bold, baseline in lines:
        set_line(image, 563, baseline, text, 19 if bold else 21, (3, 4, 5),
                 bold=bold)
    for baseline in (392, 471, 552):
        dot(image, (544, round(baseline - 7.5)), 7, (18, 156, 51))


PATCHES = {
    "2f3080016a087fb64c673fdb02ea867d3009b269ee17a935a18ae2c7423a316c": (
        "Beine hochlagern statt nicht hochlagern", _anaphylaxis),
    "0bc9d28c5ed602adfa10759631b7331fa662bed638eeae8ffb2ebf6785635c86": (
        "Kühlen bei Kindern und Säuglingen nach AWMF", _burns),
    "05ebb8a98850a24f88c813ac91f9b012a44901ea488996993f9c4888498dd6a2": (
        "Kleines statt Keines Kind", _dehydration),
    "8d74e0edafb84f361cb3699334ba7de1f558abad1dccd97438884e308b5137a9": (
        "unleserliche Zeile nach Oberschenkelbruch entfernt", _fracture),
}


def apply(source, image):
    """Corrects [image] if [source] is a picture with a correction.

    Returns what was corrected, or None.
    """
    patch = PATCHES.get(sha256(source))
    if patch is None:
        return None
    description, fix = patch
    fix(image)
    return description


def sha256(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()
