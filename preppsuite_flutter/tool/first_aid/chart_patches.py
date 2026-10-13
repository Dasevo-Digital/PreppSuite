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

Where a picture says something wrong, it is not redrawn in its own
style here. It is crossed out with the charts' own prohibition sign, or
covered by a plain shape in the charts' colours -- a box, a curve -- that
says the right thing.

Ink is found by how much darker a pixel is than the plane fitted through
the light pixels around it, so a soft shading behind the text survives.
"""

from dataclasses import dataclass
import hashlib
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# (file, face): the macOS faces nearest each chart's own, picked by
# setting the chart's line beside the original.
NARROW = ("/System/Library/Fonts/Supplemental/Arial Narrow.ttf", 0)
NARROW_BOLD = ("/System/Library/Fonts/Supplemental/Arial Narrow Bold.ttf", 0)
CONDENSED_MEDIUM = ("/System/Library/Fonts/Avenir Next Condensed.ttc", 5)
CONDENSED_DEMI = ("/System/Library/Fonts/Avenir Next Condensed.ttc", 2)
CONDENSED_BOLD = ("/System/Library/Fonts/Avenir Next Condensed.ttc", 0)
HELVETICA = ("/System/Library/Fonts/HelveticaNeue.ttc", 0)


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


def _crop(image, box, light):
    """The pixels of [box], turned over for light letters on a dark ground
    so that ink is always what is darker than the paper."""
    pixels = np.asarray(image.crop(box)).astype(float)
    return 255 - pixels if light else pixels


def background(image, box, light=False):
    """The pixels of [box], and the plane fitted through its paper."""
    pixels = _crop(image, box, light)
    lum = pixels.mean(axis=2)
    # Text is sparse in a line's box, so most of it is paper.
    paper = lum > np.percentile(lum, 90) - 25
    return pixels, _plane(pixels, paper)


def ink(image, box, light=False):
    """The letters in [box]; [light] for light letters on a dark ground."""
    pixels, fitted = background(image, box, light)
    lum, base = pixels.mean(axis=2), fitted.mean(axis=2)
    darkest = np.percentile(lum, 1)
    colour = pixels[lum <= darkest + 8].mean(axis=0)
    alpha = np.clip((base - lum) / np.maximum(base - colour.mean(), 1), 0, 1)
    alpha[alpha < 0.08] = 0
    return Ink(alpha, 255 - colour if light else colour)


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


def _font(face, size):
    path, index = face
    return ImageFont.truetype(path, size, index=index)


def set_line(image, left, baseline, text, size, colour, *, face=NARROW,
             stretch=1.0):
    """Sets one line of new text, its baseline at [baseline].

    Drawn at four times the size and scaled down, which smooths the edges
    the way the charts' own text is smoothed. [stretch] narrows it, for a
    chart whose own face is more condensed than any face on the Mac.
    """
    scale = 4
    font = _font(face, size * scale)
    l, t, r, b = font.getbbox(text, anchor="ls")
    layer = Image.new("L", (r - l + 8 * scale, b - t + 8 * scale), 0)
    ImageDraw.Draw(layer).text((4 * scale - l, 4 * scale - t), text,
                               font=font, fill=255, anchor="ls")
    width = round(layer.width / scale * stretch)
    alpha = np.asarray(layer.resize((width, layer.height // scale),
                                    Image.LANCZOS)).astype(float) / 255
    x = left + round((l / scale - 4) * stretch)
    y = baseline + round(t / scale) - 4
    paste_ink(image, (x, y), alpha, np.asarray(colour, float))


def dot(image, centre, radius, colour):
    layer = Image.new("L", (radius * 8, radius * 8), 0)
    ImageDraw.Draw(layer).ellipse((0, 0, radius * 8 - 1, radius * 8 - 1), fill=255)
    layer = layer.resize((radius * 2, radius * 2), Image.LANCZOS)
    cx, cy = centre
    paste_ink(image, (cx - radius, cy - radius),
              np.asarray(layer).astype(float) / 255, np.asarray(colour, float))


def text_width(text, size, face=NARROW, stretch=1.0):
    return _font(face, size * 4).getlength(text) / 4 * stretch


def _closed_up(image, line, cut_from, cut_to, light=False):
    """Takes columns [cut_from, cut_to) out of [line] and closes the gap."""
    k = ink(image, line, light)
    x0 = line[0]
    alpha = np.hstack([k.alpha[:, :cut_from - x0], k.alpha[:, cut_to - x0:]])
    erase(image, line)
    paste_ink(image, line[:2], alpha, k.colour)


def _rebuilt(image, line, pieces, light=False):
    """Sets [line] anew from its own letters, left aligned where it was.

    [pieces] are column ranges (start, end) of the line's ink, in the
    order they are to stand, or a number of empty columns.
    """
    k = ink(image, line, light)
    x0 = line[0]
    parts = [
        np.zeros((k.alpha.shape[0], piece)) if isinstance(piece, int)
        else k.alpha[:, piece[0] - x0:piece[1] - x0]
        for piece in pieces
    ]
    erase(image, line)
    paste_ink(image, line[:2], np.hstack(parts), k.colour)


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
        face = NARROW_BOLD if bold else NARROW
        assert text_width(text, 19 if bold else 21, face) <= room + 1, text
    erase(image, (528, 432, 812, 560))
    erase(image, (528, 364, 800, 432))
    for text, bold, baseline in lines:
        set_line(image, 563, baseline, text, 19 if bold else 21, (3, 4, 5),
                 face=NARROW_BOLD if bold else NARROW)
    for baseline in (392, 471, 552):
        dot(image, (544, round(baseline - 7.5)), 7, (18, 156, 51))


def _poisoning(image):
    # The only chart that says "Sie" to its reader; the others say "du".
    # "Rufen Sie das" -> "Ruf das": the e (from 387) to the end of "Sie".
    # The line ends at the hyphen (603); the drawn hair begins after it.
    _closed_up(image, (352, 268, 604, 290), 387, 433)
    # "lassen Sie sich" -> "lass dich": the d from "und", "ich" from
    # "sich".
    _rebuilt(image, (352, 292, 596, 313),
             [(352, 512), 3, (468, 477), 1, (569, 591)])
    # "Nennen Sie dem" -> "Nenne dem".
    _closed_up(image, (700, 271, 960, 294), 761, 800)
    # The number is Berlin's, one of eight centres, not one for the
    # country: "(Deutschland)" -> "(Berlin)". There is no B on the chart
    # to borrow, so the word is set anew.
    erase(image, (398, 469, 505, 491))
    set_line(image, 403, 484, "(Berlin)", 17.1, (3, 3, 2), face=NARROW_BOLD)


def _heat(image):
    # "heiße, trockene Haut (oder starkes Schwitzen)" stood among the
    # signs of heat exhaustion; hot dry skin is heat stroke, which the
    # box beside it names. Heat exhaustion is pale, damp skin (DRK). The
    # second line is drawn over the illustration and stays as it is.
    erase(image, (45, 327, 206, 348))
    set_line(image, 49, 343, "blasse, feuchte Haut", 19.9, (4, 4, 3))


def _jellyfish(image):
    # "krazten" -> "kratzen": t and z change places.
    _rebuilt(image, (556, 326, 790, 350),
             [(556, 742), (751, 758), (742, 751), 1, (758, 790)])
    # The first point picked tentacles off with tweezers. The guide
    # follows the DLRG: bind the stinging threads with shaving foam or
    # wet sand, let it dry, scrape it off with a card. The point after it,
    # rinsing with seawater, stays.
    lines = [
        ("Nesselfäden mit Rasierschaum oder", 238),
        ("feuchtem Sand binden, antrocknen", 262),
        ("lassen, mit einer Karte abschaben.", 286),
    ]
    for text, _ in lines:
        assert text_width(text, 21.5, CONDENSED_MEDIUM) <= 912 - 561, text
    erase(image, (553, 220, 912, 297))
    for text, baseline in lines:
        set_line(image, 561, baseline, text, 21.5, (2, 3, 3),
                 face=CONDENSED_MEDIUM)


def _faint(image):
    # "Bewussstein." -> "Bewusstsein.": the third s and the t change
    # places. White on the red banner.
    _rebuilt(image, (598, 149, 758, 177),
             [(598, 691), (702, 711), (691, 702), (711, 758)], light=True)
    # "Ruchsask" -> "Rucksack": the h gives way to the word's own k, the
    # second s to its c. Both pairs are the same width, so ")." stays.
    _rebuilt(image, (375, 563, 492, 589),
             [(375, 421), (462, 472), (431, 452), (411, 421), (462, 492)])


def _childbirth(image):
    # "wer dabeisein" -> "wer dabei sein", as written since 1996.
    _rebuilt(image, (36, 447, 200, 472), [(36, 144), 6, (144, 194)],
             light=True)


def _psychological_first_aid(image):
    # "unterstützzen" -> "unterstützen": one z out, and the banner's line
    # centred again.
    _rebuilt(image, (140, 86, 772, 118), [7, (140, 717), (732, 772)],
             light=True)


def _disc(image, source, centre, radius):
    """Copies the round area at [centre] from [source] onto [image]."""
    size = radius * 2
    x, y = centre[0] - radius, centre[1] - radius
    large = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(large).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    mask = large.resize((size, size), Image.LANCZOS)
    image.paste(source.crop((x, y, x + size, y + size)), (x, y), mask)


def _unresponsive(image):
    # The chart checked the breathing (panel 2) before the call
    # (panel 3, "Wenn keine normale Atmung: Notruf 112"). Since the 2025
    # guidelines the call comes first, as soon as there is no response,
    # and the guide says so. The two panels change places, each fitted to
    # the other's width (298 and 305 pixels), and the numbers stay where
    # they were.
    source = image.copy()
    top, bottom = 157, 648
    breathing = source.crop((403, top, 701, bottom))
    call = source.crop((707, top, 1012, bottom))
    image.paste(call.resize((298, bottom - top), Image.LANCZOS), (403, top))
    image.paste(breathing.resize((305, bottom - top), Image.LANCZOS), (707, top))
    _disc(image, source, (442, 192), 38)
    _disc(image, source, (751, 191), 38)
    # The call's heading loses "Wenn keine normale Atmung:" and keeps
    # "Notruf 112.", on one line where "Atmung prüfen." stood: panel 1
    # ends on "Reagiert die Person nicht?", and this is the answer.
    scale = 298 / 305
    left = 403 + round((894 - 707) * scale)
    right = 403 + round((1001 - 707) * scale) + 1
    k = ink(image, (left - 1, 197, right + 1, 231))
    # A two-line heading is set narrower and darker than a heading of one
    # line: back to the 22 pixels of "Atmung prüfen." with the top of the
    # capitals at 174, a fifth wider, and in its navy.
    rows = np.nonzero((k.alpha > 0.4).any(axis=1))[0]
    grow = 22 / (rows.max() - rows.min() + 1)
    height, width = k.alpha.shape
    alpha = np.asarray(
        Image.fromarray((k.alpha * 255).astype(np.uint8)).resize(
            (round(width * grow * 1.2), round(height * grow)), Image.LANCZOS),
    ).astype(float) / 255
    erase(image, (485, 162, 700, 232))
    paste_ink(image, (491, 174 - round(rows.min() * grow)), alpha,
              np.array([1.0, 17.0, 82.0]))
    # "regelmläßig" -> "regelmäßig".
    _closed_up(image, (130, 798, 430, 828), 271, 275)


def _paint_over(image, box, keep, ring=4):
    """Paints [box] with a plane fitted to the ring pixels [keep] accepts.

    For a mark on a coloured ground, where the ring around it also holds
    other colours: [keep] picks the ground's own pixels by colour.
    """
    x0, y0, x1, y1 = box
    ox0, oy0, ox1, oy1 = x0 - ring, y0 - ring, x1 + ring, y1 + ring
    pixels = np.asarray(image.crop((ox0, oy0, ox1, oy1))).astype(float)
    inner = np.zeros(pixels.shape[:2], bool)
    inner[ring:-ring, ring:-ring] = True
    fitted = _plane(pixels, ~inner & keep(pixels))
    pixels[inner] = fitted[inner]
    image.paste(Image.fromarray(pixels[ring:-ring, ring:-ring]
                                .clip(0, 255).astype(np.uint8)), (x0, y0))


def _respaced(image, region, cells, separator, keep=()):
    """Spreads [cells] of [region] evenly across it, separators between.

    [cells] are (left, right) column ranges of the region; [separator] is
    the column of one of its faint dividing lines, copied to the new
    places. Everything is on one ground, fitted as a plane, and each cell's
    contents are carried over as they are. [keep] are boxes that belong to
    something else reaching into the region; they stay where they are.
    """
    x0, y0, x1, y1 = region
    pixels = np.asarray(image.crop(region)).astype(float)
    kept = np.zeros(pixels.shape[:2], bool)
    for kx0, ky0, kx1, ky1 in keep:
        kept[ky0 - y0:ky1 - y0, kx0 - x0:kx1 - x0] = True
    lum = pixels.mean(axis=2)
    ground = _plane(pixels, (np.abs(lum - np.median(lum)) < 6) & ~kept)
    difference = np.abs(pixels - ground).max(axis=2)
    difference[kept] = 0
    out = ground.copy()
    line = pixels[:, separator - x0] - ground[:, separator - x0]
    slot = (x1 - x0) / len(cells)
    for i, (left, right) in enumerate(cells):
        block = slice(left - x0, right - x0)
        used = np.nonzero((difference[:, block] > 30).any(axis=0))[0]
        start, end = used.min(), used.max() + 1
        width = end - start
        target = round(i * slot + (slot - width) / 2)
        a = np.clip(difference[:, block][:, start:end] / 30, 0, 1)[..., None]
        src = pixels[:, block][:, start:end]
        dst = out[:, target:target + width]
        out[:, target:target + width] = dst * (1 - a) + src * a
        if i:
            column = round(i * slot)
            out[:, column] = ground[:, column] + line
    out[kept] = pixels[kept]
    image.paste(Image.fromarray(out.clip(0, 255).astype(np.uint8)), (x0, y0))


def _emergency_call(image):
    # The last "Nicht tun" was "Den Notruf nicht von Kindern ohne Aufsicht
    # absetzen lassen". A child alone with someone who has collapsed has
    # to call 112, and is taught to. The cell goes, and the other three
    # share the row.
    # The "Nicht tun!" banner reaches into the first cell: its lower edge
    # down to 1128, its round badge down to 1135.
    _respaced(image, (20, 1128, 1008, 1350),
              [(20, 272), (275, 500), (503, 743)], 273,
              keep=[(20, 1128, 350, 1129), (20, 1128, 120, 1137)])
    # "①1122" on the ambulance's bonnet, where the chart is about 112.
    _paint_over(image, (898, 944, 972, 961),
                lambda p: (p[..., 0] > 180) & (p[..., 1] < 110))


def _composed(image, line, baseline, parts, colour=None):
    """Sets [line] anew from letters taken anywhere on the chart.

    [parts] are (box, baseline) pairs -- the letters inside [box], whose
    own baseline is [baseline] -- or a number of empty columns. Each is
    moved so that its baseline sits on the line's [baseline], and the
    line is set from its left edge. The letters keep their ink; the line
    takes the colour of its own old letters unless [colour] is given.
    """
    x0, y0, x1, y1 = line
    above, below = baseline - y0, y1 - baseline
    if colour is None:
        colour = ink(image, line).colour
    pieces = []
    for part in parts:
        if isinstance(part, int):
            pieces.append(np.zeros((above + below, part)))
            continue
        (bx0, by0, bx1, by1), base = part
        k = ink(image, (bx0, base - above, bx1, base + below))
        pieces.append(k.alpha)
    alpha = np.hstack(pieces)
    erase(image, line)
    paste_ink(image, (x0, y0), alpha[:, :x1 - x0 + 40], colour)


def _drowning(image):
    # Three typos, from the chart's own letters: "möglichet" takes the s
    # of "Gewässer" from the line below, "übernimnt" its own m, and
    # "fortestzen" swaps e and s.
    _composed(image, (690, 229, 905, 254), 243, [
        ((690, 0, 820, 0), 243), ((856, 0, 865, 0), 268),
        ((830, 0, 905, 0), 243)])
    _rebuilt(image, (100, 907, 565, 935),
             [(100, 537), (522, 537), 1, (547, 565)])
    _rebuilt(image, (680, 959, 976, 990),
             [(680, 913), (921, 930), (913, 921), (930, 976)])
    # In the "Nicht tun" row two cells came out garbled: "nicht auf der"
    # (cell 3) and "aus den" / "Lungen verlieren." (cell 5). Cell 3 now
    # reads "Nasse Kleidung nicht anlassen.", cell 5 "Keine Zeit mit
    # Ausschütteln von Wasser aus den Lungen verlieren." as before. The
    # new lines are set in the face that measured nearest; cell 5's own
    # lines are squeezed to about four fifths, and so are the new ones,
    # to 0.74 so that "verlieren." stays clear of the panel's edge.
    erase(image, (556, 1299, 637, 1346))
    set_line(image, 557, 1316, "nicht", 19.5, (26, 40, 76),
             face=CONDENSED_MEDIUM)
    set_line(image, 557, 1340, "anlassen.", 19.5, (26, 40, 76),
             face=CONDENSED_MEDIUM)
    erase(image, (908, 1298, 1010, 1346))
    for text, baseline in (("Wasser aus den", 1314),
                           ("Lungen verlieren.", 1336)):
        assert text_width(text, 19.5, CONDENSED_DEMI, 0.74) <= 1010 - 913, text
        set_line(image, 913, baseline, text, 19.5, (30, 44, 84),
                 face=CONDENSED_DEMI, stretch=0.74)


def _aed(image):
    # "Pads genau nach Abbildung auf das Gerät kleben." The pads go on
    # the chest: "auf die Brust kleben.", with "die" from "seitlich
    # unter die linke Achsel." below and "Brust" from step 3.
    _composed(image, (640, 578, 830, 600), 596, [
        ((640, 0, 673, 0), 596), 4, ((752, 0, 778, 0), 671), 5,
        ((136, 0, 182, 0), 620), 5, ((756, 0, 813, 0), 596)])
    # "AED nicht bei Nässe verwenden (trocknen)." reads as: in the rain,
    # leave the defibrillator. It works wet; the chest is dried first, as
    # the guide says. Avenir Next Condensed Medium, at the cell's cap
    # height of 14 pixels: it covers as much of a line as the cells beside
    # it do.
    erase(image, (418, 1258, 560, 1327))
    for text, baseline in (("Pads nicht auf", 1275),
                           ("nasse Haut kleben", 1297),
                           ("(vorher trocknen).", 1319)):
        # Clear of the next cell's sign, which begins at 575.
        assert text_width(text, 19.7, CONDENSED_MEDIUM) <= 568 - 426, text
        set_line(image, 426, baseline, text, 19.7, (24, 37, 76),
                 face=CONDENSED_MEDIUM)


def _insect_bite(image):
    # A strip of another chart, and the line between the two, run down
    # the left edge above the "Merke" box. The page's own white goes over
    # it.
    _paint_over(image, (0, 0, 46, 1366),
                lambda p: p.min(axis=2) > 246, ring=2)


def _flash_eye(image):
    # "Hellenes Licht" -> "Helles Licht": n and e out.
    _closed_up(image, (112, 250, 392, 283), 192, 214)
    # "Noch am gleichen Tag Augenarzt aufsuchen." The guide sends to the
    # doctor when it is not better after 24 hours, or worse. The first
    # line of the heading says so; the second stays.
    erase(image, (620, 672, 1008, 711))
    set_line(image, 627, 700, "Nach 24 h nicht besser?", 33.5, (1, 17, 82),
             face=CONDENSED_DEMI)
    # "Merke" said: see an eye doctor soon after UV damage. Now: what the
    # steps say, and the same 24 hours.
    erase(image, (215, 1400, 1000, 1478))
    set_line(image, 226, 1427, "Augen schonen, nicht reiben, nicht selbst betäuben.",
             29.8, (31, 41, 61), face=HELVETICA)
    set_line(image, 226, 1463, "Nach 24 Stunden nicht besser: zum Augenarzt.",
             29.8, (31, 41, 61), face=HELVETICA)


def _suicidal_ideation(image):
    # 116 123 is the TelefonSeelsorge's, and so the box calls it; it said
    # "Krisendienst". And "www.116123.de" is no help service at all: the
    # domain was for sale in October 2026. The TelefonSeelsorge is at
    # telefonseelsorge.de.
    erase(image, (725, 653, 995, 688))
    set_line(image, 729, 680, "TelefonSeelsorge", 27.9, (10, 28, 70),
             face=CONDENSED_BOLD)
    erase(image, (725, 836, 1000, 870))
    set_line(image, 729, 858, "www.telefonseelsorge.de", 23.5, (10, 28, 70),
             face=NARROW)


def _fever(image):
    # "oder weitere schwere Krankzeichen" -> "Anzeichen": the A of
    # "Atemprobleme" three lines up, the n and "zeichen" its own.
    # The line starts after its red bullet, which keeps its colour.
    _composed(image, (716, 1060, 1010, 1086), 1077, [
        ((716, 0, 892, 0), 1077), ((774, 0, 786, 0), 1013), 1,
        ((918, 0, 927, 0), 1077), 1, ((937, 0, 1010, 0), 1077)])


def _drawn(image, box, paint, scale=4):
    """Lays shapes over [box] of [image], drawn at [scale] times the size
    and scaled down so that their edges are as soft as the chart's own.

    [paint](draw, scale, at) draws them; [at] turns chart coordinates
    into the drawing's.
    """
    x0, y0, x1, y1 = box
    layer = Image.new("RGBA", ((x1 - x0) * scale, (y1 - y0) * scale), (0, 0, 0, 0))

    def at(*xy):
        return [(v - (x0 if i % 2 == 0 else y0)) * scale for i, v in enumerate(xy)]

    paint(ImageDraw.Draw(layer), scale, at)
    layer = layer.resize((x1 - x0, y1 - y0), Image.LANCZOS)
    image.paste(layer, (x0, y0), layer)


def _centred(image, centre, baseline, text, size, colour, face):
    set_line(image, round(centre - text_width(text, size, face) / 2), baseline,
             text, size, colour, face=face)


def _forbidden(image, centre, radius, width, colour=(226, 24, 30)):
    """The charts' prohibition sign, a red ring and bar, laid over a
    picture to say "not like this". Edged in white, so that it stands
    out on a painted picture as it does on the plain ground of a "Nicht
    tun" cell."""
    edge = 3
    box = (centre[0] - radius - edge - 4, centre[1] - radius - edge - 4,
           centre[0] + radius + edge + 4, centre[1] + radius + edge + 4)
    a = radius * math.cos(math.radians(45))
    bar = (centre[0] - a, centre[1] - a, centre[0] + a, centre[1] + a)

    def paint(d, s, at):
        cx, cy = at(*centre)
        for r, w, fill in ((radius + edge, width + 2 * edge, (255, 255, 255, 230)),
                           (radius, width, colour + (255,))):
            d.ellipse((cx - r * s, cy - r * s, cx + r * s, cy + r * s),
                      outline=fill, width=w * s)
            d.line(at(*bar), fill=fill, width=w * s)

    _drawn(image, box, paint)


def _fill_smooth(pixels, unknown, known, steps=3000):
    """Fills the [unknown] pixels from the [known] ones around them, each
    one the mean of its neighbours, so that the fill runs into its
    surroundings without a seam. Pixels that are neither -- a figure in
    front of the wall being filled -- take no part. Starts from the
    pixels as given, which should already be close."""
    out = pixels.astype(float).copy()
    take = unknown | known
    h, w = unknown.shape
    for _ in range(steps):
        total = np.zeros_like(out)
        count = np.zeros((h, w, 1))
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            src = (slice(max(dy, 0), h + min(dy, 0)), slice(max(dx, 0), w + min(dx, 0)))
            dst = (slice(max(-dy, 0), h + min(-dy, 0)), slice(max(-dx, 0), w + min(-dx, 0)))
            total[dst] += out[src] * take[src][..., None]
            count[dst] += take[src][..., None]
        out[unknown] = (total / np.maximum(count, 1))[unknown]
    return out


def _dental_avulsion(image):
    # Step 2 was "Wenn verschmutzt: kurz und sanft abspülen", its picture
    # a tooth under the tap. The guide: never rinse it, never clean it,
    # tap water harms the cells on the root. The heading and the points
    # now say that, and the picture carries the charts' own "Nicht tun"
    # sign. Avenir Next Condensed, Bold for the heading and Medium for the
    # points, measured on the chart's own lines.
    text, heading, green = (2, 5, 28), (0, 6, 61), (3, 82, 50)
    # Step 1 ended "Nicht reinigen, wenn er sauber ist" -- and if not?
    erase(image, (44, 346, 328, 377))
    erase(image, (40, 377, 92, 399))
    set_line(image, 49, 365, "Nicht spülen, nicht reinigen.", 25.9, text,
             face=CONDENSED_MEDIUM)
    erase(image, (616, 166, 944, 233))
    erase(image, (616, 233, 920, 245))  # the p's tail, short of the tap
    set_line(image, 621, 196, "Nicht abspülen,", 32.6, heading, face=CONDENSED_BOLD)
    set_line(image, 621, 232, "nie trocken lagern.", 32.6, heading,
             face=CONDENSED_BOLD)
    # "Nicht schrubben, nicht / mit Bürste reinigen." stays, a line higher
    # and on the others' left edge; its bullet is set anew with theirs.
    k = ink(image, (556, 380, 800, 442))
    erase(image, (526, 258, 836, 378))
    erase(image, (526, 380, 800, 442))
    erase(image, (526, 444, 836, 504))
    erase(image, (836, 472, 854, 503))
    paste_ink(image, (552, 351), k.alpha, k.colour)
    for baseline, line in ((281, "Auch einen schmutzigen"),
                           (309, "Zahn nicht abspülen, auch"),
                           (337, "nicht kurz, nicht säubern."),
                           (437, "Leitungswasser schadet"),
                           (465, "den Zellen an der Wurzel."),
                           (501, "Nie trocken liegen lassen.")):
        # Clear of the sign, whose white edge begins at 823.
        assert 562 + text_width(line, 25.9, CONDENSED_MEDIUM) <= 815, line
        set_line(image, 562, baseline, line, 25.9, text, face=CONDENSED_MEDIUM)
    for baseline in (281, 373, 437, 501):
        dot(image, (536, baseline - 8), 5, green)
    _forbidden(image, (918, 418), 92, 15)
    # "die besten Chancen den Zahn zu retten" wants its comma.
    _rebuilt(image, (24, 98, 895, 142), [(24, 639), 7, (639, 895)], light=True)
    set_line(image, 640, 129, ",", 36.7, (254, 253, 252), face=CONDENSED_DEMI)


def _anxiety_panic(image):
    # Two steps taught what the guide leaves out on purpose. Step 2
    # breathed 4-2-6; the guide breathes along, in on one, out on three.
    # Step 4 was the 5-4-3-2-1 method, for which the 2025 guidelines give
    # no recommendation; the guide says instead that the attack is a
    # reaction to strain, passes by itself and peaks after ten to fifteen
    # minutes. That is drawn as a curve where the five senses were.
    text, heading = (7, 19, 63), (0, 10, 78)
    blue, cream, cream_edge = (31, 90, 133), (253, 239, 224), (238, 214, 190)
    red = (214, 34, 40)

    # Step 2: the first bullet's dot stays and is copied for the third.
    bullet = ink(image, (576, 240, 594, 262))
    erase(image, (596, 236, 836, 263))
    erase(image, (596, 263, 818, 402))  # short of the breath arrows
    for baseline, line in ((257, "Voratmen, mitatmen lassen."),
                           (284, "Auf eins durch die Nase"),
                           (312, "ein, auf drei durch den"),
                           (340, "Mund aus."),
                           (368, "In den Bauch atmen"),
                           (395, "lassen.")):
        set_line(image, 602, baseline, line, 22.9, text, face=CONDENSED_MEDIUM)
    paste_ink(image, (576, 351), bullet.alpha, bullet.colour)
    # The "4 - 2 - 6" box, drawn again over itself: the blue label, two
    # cells instead of three.
    erase(image, (816, 437, 1000, 447), ring=3)

    def breathing(d, s, at):
        d.rounded_rectangle(at(778, 443, 1015, 518), radius=11 * s,
                            fill=cream + (255,), outline=cream_edge + (255,), width=s)
        d.line(at(896.5, 462, 896.5, 510), fill=(225, 200, 178, 255), width=s)
        d.rounded_rectangle(at(820, 391, 995, 442), radius=10 * s, fill=(255, 255, 255, 255))
        d.rounded_rectangle(at(822, 393, 993, 440), radius=9 * s, fill=blue + (255,))
        for x in (837, 956):
            d.line(at(x, 442, x, 456), fill=text + (255,), width=round(1.6 * s))
            d.polygon(at(x - 4, 452, x + 4, 452, x, 458), fill=text + (255,))

    _drawn(image, (770, 385, 1020, 522), breathing)
    _centred(image, 907.5, 428, "Mitatmen", 30, (255, 255, 255), CONDENSED_DEMI)
    for centre, count, verb in ((837, "1", "einatmen"), (956, "3", "ausatmen")):
        auf = text_width("auf ", 19, CONDENSED_MEDIUM)
        left = round(centre - (auf + text_width(count, 27, CONDENSED_BOLD)) / 2)
        set_line(image, left, 484, "auf", 19, text, face=CONDENSED_MEDIUM)
        set_line(image, round(left + auf), 484, count, 27, text, face=CONDENSED_BOLD)
        _centred(image, centre, 507, verb, 20.5, text, CONDENSED_MEDIUM)

    # Step 4.
    erase(image, (584, 534, 1006, 633))
    set_line(image, 590, 569, "Sagen, dass es vorbeigeht.", 35.4, heading,
             face=CONDENSED_DEMI)
    set_line(image, 591, 597, "Eine Reaktion auf Anspannung,", 25.9, text,
             face=CONDENSED_MEDIUM)
    set_line(image, 591, 624, "sie lässt von selbst nach.", 25.9, text,
             face=CONDENSED_MEDIUM)
    erase(image, (566, 633, 1009, 866))
    left, right, axis, top = 604, 978, 826, 678

    def x_of(minutes):
        return left + (right - left - 14) * minutes / 32

    def strength(minutes):
        # Rises, peaks at 12.5 minutes, ebbs; the shape, not a measurement.
        u = minutes / 12.5
        return 0.10 + 0.90 * u ** 3 * math.exp(3 * (1 - u))

    curve = [(x_of(m / 4), axis - strength(m / 4) * (axis - top)) for m in range(129)]
    peak = (x_of(12.5), axis - (axis - top))

    def graph(d, s, at):
        d.rounded_rectangle(at(572, 638, 1005, 862), radius=12 * s,
                            fill=(255, 255, 255, 255), outline=(206, 226, 236, 255), width=s)
        d.rectangle(at(x_of(10), top - 6, x_of(15), axis), fill=(253, 228, 226, 255))
        line = [v for p in curve for v in at(*p)]
        d.polygon(line + at(x_of(32), axis, x_of(0), axis), fill=(246, 196, 192, 150))
        d.line(line, fill=red + (255,), width=round(4.5 * s), joint="curve")
        d.line(at(left, axis, right, axis), fill=text + (255,), width=2 * s)
        d.polygon(at(right + 9, axis, right - 1, axis - 6, right - 1, axis + 6),
                  fill=text + (255,))
        cx, cy = at(*peak)
        d.ellipse((cx - 6 * s, cy - 6 * s, cx + 6 * s, cy + 6 * s),
                  fill=(255, 255, 255, 255), outline=red + (255,), width=3 * s)
        for minutes in (10, 15):
            d.line(at(x_of(minutes), axis, x_of(minutes), axis + 6),
                   fill=text + (255,), width=2 * s)

    _drawn(image, (566, 633, 1010, 868), graph)
    _centred(image, peak[0], top - 14, "Höhepunkt", 21, red, CONDENSED_DEMI)
    _centred(image, peak[0], axis + 26, "10 bis 15 Min.", 19, text, CONDENSED_MEDIUM)
    set_line(image, left - 2, axis + 26, "0", 19, text, face=CONDENSED_MEDIUM)
    set_line(image, right - 50, axis + 26, "Zeit", 19, text, face=CONDENSED_MEDIUM)
    set_line(image, 588, 668, "Angst", 19, text, face=CONDENSED_MEDIUM)
    set_line(image, 860, 712, "lässt von", 20, text, face=CONDENSED_DEMI)
    set_line(image, 860, 734, "selbst nach", 20, text, face=CONDENSED_DEMI)


def _plaster(image, centre, length, width, angle):
    """A sticking plaster as on the chart's header: white rim, a white pad
    across the middle, a cross of dots on each end."""
    u = (math.cos(math.radians(angle)), -math.sin(math.radians(angle)))
    n = (-u[1], u[0])
    half, r = (length - width) / 2, width / 2
    cx, cy = centre
    ends = [(cx - half * u[0], cy - half * u[1]), (cx + half * u[0], cy + half * u[1])]
    box = (round(cx - length / 2 - 8), round(cy - length / 2 - 8),
           round(cx + length / 2 + 8), round(cy + length / 2 + 8))
    white = (255, 255, 255, 255)

    def paint(d, s, at):
        for radius, fill in ((r, white), (r - 4.2, (215, 15, 22, 255))):
            d.line(at(*ends[0], *ends[1]), fill=fill, width=round(2 * radius * s))
            for end in ends:
                x, y = at(*end)
                d.ellipse((x - radius * s, y - radius * s, x + radius * s, y + radius * s),
                          fill=fill)
        pad = length * 0.17
        corners = [(cx + a * pad * u[0] + b * r * n[0], cy + a * pad * u[1] + b * r * n[1])
                   for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        d.polygon([v for p in corners for v in at(*p)], fill=white)
        step, spot = width * 0.2, width * 0.065 * s
        for sign in (-1, 1):
            along = sign * (pad + (half + r * 0.45 - pad) / 2 + 2)
            for dx, dy in ((0, 0), (step, 0), (-step, 0), (0, step), (0, -step)):
                x, y = at(cx + along * u[0] + dx, cy + along * u[1] + dy)
                d.ellipse((x - spot, y - spot, x + spot, y + spot), fill=white)

    _drawn(image, box, paint)


def _right_margin(image, sections):
    """Puts back a right margin the picture was cropped without: each of
    [sections] (top, bottom, right edge, corner radius) ends in rounded
    corners, and beyond them is the page, taken row by row from the left
    margin."""
    a = np.asarray(image).astype(float)
    page = np.median(a[:, 2:10], axis=1)
    s = 4
    for top, bottom, right, radius in sections:
        x0, y0, x1, y1 = 940, max(top - 3, 0), image.width, bottom + 3
        mask = Image.new("L", ((x1 - x0) * s, (y1 - y0) * s), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            ((900 - x0) * s, (top - y0) * s, (right - x0) * s, (bottom - y0) * s),
            radius=radius * s, fill=255)
        inside = np.asarray(mask.resize((x1 - x0, y1 - y0), Image.LANCZOS))
        inside = inside.astype(float)[..., None] / 255
        a[y0:y1, x0:x1] = a[y0:y1, x0:x1] * inside + page[y0:y1, None, :] * (1 - inside)
    image.paste(Image.fromarray(a.clip(0, 255).astype(np.uint8)))


def _cuts_and_grazes(image):
    # The picture was cropped on the right: no margin, the plaster in the
    # header cut through, and step 4, the card beside step 5 and the last
    # "Nicht tun" cell ending mid-word. Each part is mended where it
    # stands, then the margin goes back on.
    def deep_red(p):
        return (p[..., 0] > 180) & (p[..., 1] < 40) & (p[..., 2] < 45)

    # Header: the plaster painted out (round the title's last N), drawn
    # whole and a little smaller.
    _paint_over(image, (934, 15, 1024, 87), deep_red)
    _paint_over(image, (918, 87, 1024, 147), deep_red)
    _plaster(image, (958, 100), 90, 44, 55)

    # Step 4, set anew in Arial Narrow, to the guide's "Haut ringsum
    # trocknen und die Wunde abdecken".
    erase(image, (785, 558, 1010, 733))
    for baseline, line in ((579, "Haut um die Wunde"), (606, "trocknen."),
                           (637, "Sterile, nicht haftende"),
                           (663, "Kompresse auflegen."),
                           (694, "Mit Pflaster oder"), (720, "Verband fixieren.")):
        assert 787 + text_width(line, 25.9) <= 995, line
        set_line(image, 787, baseline, line, 25.9, (3, 10, 39))

    # Step 5 said "in der Regel alle 10 Jahre auffrischen". The guide:
    # every five years after a dirty wound, otherwise every ten.
    erase(image, (155, 1016, 540, 1068))  # "Bei tiefen" begins at 1069
    set_line(image, 157, 1037, "Tetanusschutz prüfen (alle 10 Jahre,", 26, (9, 24, 56))
    set_line(image, 157, 1062, "nach schmutziger Wunde alle 5).", 26, (9, 24, 56))
    # The card beside the picture ("Tetanussc… prüfen (i. d. R. a… 10
    # Jahr…") goes; it said the same as the line now does. Behind it is
    # the wall, filled from what shows of it above the boy and below the
    # card. Only the card is painted over: everything right of the boy,
    # and its pale ground beside him.
    a = np.asarray(image).astype(float)
    x0, x1, y0, y1 = 890, 1006, 860, 1124
    pixels = a[y0:y1, x0:x1]
    lum = pixels.mean(axis=2)
    sat = pixels.max(axis=2) - pixels.min(axis=2)
    ys, xs = np.mgrid[y0:y1, x0:x1]
    card = (xs >= 942) & (ys < 1074)
    r, b = pixels[..., 0], pixels[..., 2]
    # The boy: hair and skin warmer and darker than the wall, his shirt
    # saturated, its outline dark (the card's dark letters lie higher).
    boy = ((r - b > 45) & (lum < 200)) | (sat > 90) | ((lum < 160) & (ys > 990))
    pale = (lum > 222) & (b >= r - 4)
    paint = card & ((xs >= 957) | ~boy | pale)
    wall = ~card & (lum > 200) & (sat < 45)
    start = pixels.copy()
    start[paint] = _plane(pixels, wall)[paint]
    filled = _fill_smooth(start, paint, wall)
    filled[paint] += np.random.default_rng(1).normal(0, 1.0, (paint.sum(), 3))
    a[y0:y1, x0:x1] = filled
    image.paste(Image.fromarray(a.clip(0, 255).astype(np.uint8)))

    # The last "Nicht tun" cell moves left, clear of the new edge, and its
    # middle line -- "aggressive Desinfektionsmit…" -- reads "aggressive
    # Mittel", in the face nearest the cell's own.
    image.paste(image.crop((800, 1176, 1024, 1372)), (788, 1176))
    erase(image, (775, 1316, 1012, 1337))
    erase(image, (775, 1336, 809, 1346))
    _centred(image, 898, 1333, "aggressive Mittel", 23.1, (7, 12, 32), CONDENSED_MEDIUM)

    # The margin, as wide as on the left, with the left's rounded corners.
    _right_margin(image, [(2, 148, 1007, 13), (156, 501, 1005, 12),
                          (507, 853, 1005, 12), (859, 1126, 1005, 12),
                          (1129, 1369, 1006, 12)])



def _cpr_adult(image):
    # The redrawn chart (its pictures corrected, the hands now across the
    # lower half of the breastbone) came with a new slip of its own:
    # "umschileßen" -> "umschließen", i and l change places.
    _rebuilt(image, (38, 940, 160, 968), [(38, 98), (102, 106), (98, 102), (106, 160)])

PATCHES = {
    "2f3080016a087fb64c673fdb02ea867d3009b269ee17a935a18ae2c7423a316c": (
        "Beine hochlagern statt nicht hochlagern", _anaphylaxis),
    "0bc9d28c5ed602adfa10759631b7331fa662bed638eeae8ffb2ebf6785635c86": (
        "Kühlen bei Kindern und Säuglingen nach AWMF", _burns),
    "05ebb8a98850a24f88c813ac91f9b012a44901ea488996993f9c4888498dd6a2": (
        "Kleines statt Keines Kind", _dehydration),
    "8d74e0edafb84f361cb3699334ba7de1f558abad1dccd97438884e308b5137a9": (
        "unleserliche Zeile nach Oberschenkelbruch entfernt", _fracture),
    "e639cdba00033941f579b599e161bd5977977db268355c53057853addb5edb68": (
        "du statt Sie, Giftnotruf Berlin statt Deutschland", _poisoning),
    "dbf43bf63fc3f857fe8e2831237c3147e87b9bf68ca922b5df2d45903135c370": (
        "blasse, feuchte Haut statt heiße, trockene", _heat),
    "c0d6a84034f26d6ecc1697511fed87ae6f88b9fc0d13ce7264f700ee0f36c6e9": (
        "kratzen statt krazten, Nesselfäden binden nach DLRG", _jellyfish),
    "424fe483fefa133b1b42b08787e513c658a5922e93d0b1312755eab7358aa51b": (
        "Bewusstsein statt Bewussstein, Rucksack statt Ruchsask", _faint),
    "03e113f46cd2e3df83e1874c43130125a429fed995969d56d11654d73460db97": (
        "dabei sein statt dabeisein", _childbirth),
    "4ab3a6bd08a3029f487025cebb9638b6d42a3c82e7ddf958526031d3bab8ffbb": (
        "unterstützen statt unterstützzen", _psychological_first_aid),
    "252a18bec34f4672acd0c74f66db702f414d65f54add5f558527e07c1efca192": (
        "Kinder dürfen 112 rufen; Krankenwagen ohne 1122", _emergency_call),
    "e7f4dfcf707f1bbc9aafc01a4b8f3a2fe0a24f8592f0ab461fa6aad8fd4333af": (
        "erst 112, dann Atmung prüfen; regelmäßig", _unresponsive),
    "1bb7a0b3e529075c0d36487376ed9e1e2d690f1895b1b0275d4f04ceb6652d83": (
        "Pads auf die Brust; Pads nicht auf nasse Haut", _aed),
    "e6fa75adb5cf2eb6c3126d88d7220e0651a6132a04109d7fb6815722cc3b7178": (
        "drei Tippfehler, zwei unleserliche Felder", _drowning),
    "bb7df0ddf5e29ded2765dec7accb34cc133460a6a42f752c6f52950a90298a89": (
        "Fremdstreifen am linken Rand entfernt", _insect_bite),
    "d447d61dcd8d595f04d88c3fcb7d59d591bbf7f4e5807159d9c98018eb752453": (
        "Helles; Augenarzt nach 24 Stunden", _flash_eye),
    "ae4f3a622760d718c13a14677acd2dd8841947c918a642a16472b453eed30b28": (
        "TelefonSeelsorge und telefonseelsorge.de", _suicidal_ideation),
    "20440a995670918c35dd4f8a49b1d2e3df753767aedafe249d8bd37a4da38ed4": (
        "Anzeichen statt Krankzeichen", _fever),
    "e577b63a37bd051c8b852e3be5c16dd9a8c571394ddcab92b87ba8d6521e1843": (
        "umschließen statt umschileßen", _cpr_adult),
    "c6ebd22e70937a494019d6763ab4aa644315f1f6585dc1e9cefc47fe959133bc": (
        "rechter Rand ergänzt, abgeschnittene Zeilen neu; Tetanus wie im Text",
        _cuts_and_grazes),
    "6f5609fb48a544d191889fdf7653c92d085b1ac56079781736fdc5c72249c42b": (
        "Zahn nicht abspülen statt kurz abspülen", _dental_avulsion),
    "ed579bdf60fb514265d3ddd452bede97fb73b2a58b7cdff8a0080467935ab1ba": (
        "Mitatmen 1/3 statt 4-2-6; Verlauf statt 5-4-3-2-1", _anxiety_panic),
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
