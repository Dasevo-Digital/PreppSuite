#!/usr/bin/env python3
"""Draws the picture chart for the recovery position.

    python3 tool/first_aid/recovery_position_chart.py

Run from preppsuite_flutter/, like the generator beside it. Writes
`assets/first_aid/de/recovery-position.webp`; the guide carries
`- chart: true`.

Every other chart came as a finished picture from outside this
repository. For this guide none came, so it is drawn here, after their
model: the red header, numbered panels with one step each, a "Wichtig"
box for the cautions, the "Merke" band. The steps are the guide's seven,
in its words, and the pictures show nothing the steps do not say.

The pictures are flat figures seen from above -- the view in which the
arms and legs lie in the floor's plane, so that "im rechten Winkel"
can be shown as a right angle. The person lies with the head to the
left and the helper, whose red sleeves reach in, kneels at the bottom
edge.

Three parts are taken from other charts so that this one matches them:
the "Merke" band and footer (of `cuts-and-grazes`, its words replaced),
and the icons Hören, Sehen, Fühlen (of `unresponsive`). The header's
picture is the app's own line drawing of the position
(`first_aid_drawings.dart`). Drawing again after one of those charts has
changed takes the changed part along.

Needs Pillow and NumPy, and the macOS fonts that `chart_patches.py`
names.
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

import chart_patches as cp
from chart_patches import (CONDENSED_BOLD, CONDENSED_DEMI, HELVETICA,
                           set_line, text_width)
from infographic import APP, QUALITY

ASSETS = APP / "assets" / "first_aid" / "de"
TARGET = ASSETS / "recovery-position.webp"

HEAVY = ("/System/Library/Fonts/Avenir Next Condensed.ttc", 8)
HELVETICA_BOLD = ("/System/Library/Fonts/HelveticaNeue.ttc", 1)
GEORGIA_BOLD = ("/System/Library/Fonts/Supplemental/Georgia Bold.ttf", 0)

W, H = 1024, 1536
PAGE = (254, 254, 254)
BANNER = (215, 15, 22)
PANEL = (240, 248, 252)
PANEL_EDGE = (212, 228, 238)
NOTE = (220, 236, 251)
GREEN = (16, 98, 64)
NAVY = (0, 10, 78)
INK = (7, 19, 63)
WHITE = (255, 255, 255)
RED = (214, 34, 40)

# The figures.
OUTLINE = (38, 36, 48)
SKIN = (241, 200, 168)
SKIN_SHADE = (224, 172, 140)
LIPS = (176, 96, 86)
HAIR = (110, 68, 38)
HAIR_SHADE = (84, 50, 28)
SHIRT = (56, 118, 186)
SHIRT_SHADE = (44, 96, 156)
JEANS = (52, 66, 102)
JEANS_SHADE = (40, 52, 82)
SHOE = (52, 52, 58)
SOLE = (235, 235, 235)
SLEEVE = (200, 58, 52)
LINE = 2.2


# ---- geometry ---------------------------------------------------------------

def vec(a, b):
    return (b[0] - a[0], b[1] - a[1])


def add(a, b, k=1.0):
    return (a[0] + k * b[0], a[1] + k * b[1])


def unit(a):
    length = math.hypot(*a) or 1
    return (a[0] / length, a[1] / length)


def perp(a):
    return (-a[1], a[0])


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def rot(p, angle):
    c, s = math.cos(angle), math.sin(angle)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c)


def chaikin(points, closed=True):
    """One round of corner cutting: a polygon a little rounder."""
    out = [] if closed else [points[0]]
    n = len(points)
    for i in range(n if closed else n - 1):
        a, b = points[i], points[(i + 1) % n]
        out += [lerp(a, b, 0.25), lerp(a, b, 0.75)]
    return out if closed else out + [points[-1]]


def grown(points, d):
    """A closed polygon pushed outward by about [d]: its outline."""
    n = len(points)
    area = sum(points[i][0] * points[(i + 1) % n][1] - points[(i + 1) % n][0] * points[i][1]
               for i in range(n))
    sign = 1 if area > 0 else -1
    out = []
    for i in range(n):
        a, b, c = points[i - 1], points[i], points[(i + 1) % n]
        n1, n2 = unit(perp(vec(a, b))), unit(perp(vec(b, c)))
        normal = unit(add(n1, n2))
        cos_half = max(0.35, normal[0] * n1[0] + normal[1] * n1[1])
        out.append(add(b, normal, -sign * d / cos_half))
    return out


def reach(shoulder, target, upper, lower, bend=1):
    """Where the elbow is when an arm of [upper] and [lower] reaches
    [target]."""
    d = vec(shoulder, target)
    length = min(math.hypot(*d), upper + lower - 1e-3)
    a = math.atan2(d[1], d[0])
    b = math.acos(max(-1, min(1, (upper ** 2 + length ** 2 - lower ** 2) / (2 * upper * length))))
    return (shoulder[0] + upper * math.cos(a + bend * b),
            shoulder[1] + upper * math.sin(a + bend * b))


class Canvas:
    """Draws at [s] times the size, in figure coordinates that [place]
    turns into the canvas's."""

    def __init__(self, width, height, place, s=4):
        self.s = s
        self.image = Image.new("RGBA", (width * self.s, height * self.s), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)
        self.place = place
        a, b = place((0, 0)), place((1, 0))
        self.unit = math.hypot(b[0] - a[0], b[1] - a[1]) * self.s

    def xy(self, points):
        return [c * self.s for p in points for c in self.place(p)]

    def polygon(self, points, fill, outline=OUTLINE, smooth=0):
        for _ in range(smooth):
            points = chaikin(points)
        if outline:
            self.draw.polygon(self.xy(grown(points, LINE)), fill=outline + (255,))
        self.draw.polygon(self.xy(points), fill=fill + (255,))

    def capsule(self, p1, r1, p2, r2, fill, outline=OUTLINE):
        """The hull of two circles: a limb, thicker at one end."""
        d = vec(p1, p2)
        a = math.atan2(d[1], d[0])
        k = math.acos(max(-1, min(1, (r1 - r2) / (math.hypot(*d) or 1e-6))))

        def hull(e):
            arc1 = [(p1[0] + (r1 + e) * math.cos(t), p1[1] + (r1 + e) * math.sin(t))
                    for t in np.linspace(a + k, a + 2 * math.pi - k, 19)]
            arc2 = [(p2[0] + (r2 + e) * math.cos(t), p2[1] + (r2 + e) * math.sin(t))
                    for t in np.linspace(a - k, a + k, 19)]
            return arc1 + arc2

        if outline:
            self.draw.polygon(self.xy(hull(LINE)), fill=outline + (255,))
        self.draw.polygon(self.xy(hull(0)), fill=fill + (255,))

    def ellipse(self, centre, rx, ry, angle, fill, outline=OUTLINE):
        self.polygon([add(centre, rot((rx * math.cos(t), ry * math.sin(t)), angle))
                      for t in np.linspace(0, 2 * math.pi, 48, endpoint=False)], fill, outline)

    def line(self, points, colour, width, smooth=0):
        for _ in range(smooth):
            points = chaikin(points, closed=False)
        w = width * self.unit
        self.draw.line(self.xy(points), fill=colour + (255,), width=max(1, round(w)), joint="curve")
        for p in (points[0], points[-1]):
            x, y = self.xy([p])
            self.draw.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=colour + (255,))

    def done(self):
        w, h = self.image.size
        return self.image.resize((w // self.s, h // self.s), Image.LANCZOS)


# ---- body parts --------------------------------------------------------------
# Figure coordinates: x along the body from the crown (left) to the feet,
# y across it, the far side up (-y) and the helper's side down (+y).

def hand(c, wrist, toward, palm_up=False, thumb=1, width=17, length=26, colour=SKIN):
    """A mitten of a hand from [wrist] toward [toward], the thumb on side
    [thumb]; with a crease when the palm is up."""
    u = unit(toward)
    n = perp(u)
    tip = add(wrist, u, length - width / 2)
    outline = [add(wrist, n, width / 2 * 0.9), add(add(wrist, n, width / 2), u, length * 0.45)]
    outline += [add(add(tip, n, math.cos(t) * width / 2), u, math.sin(t) * width / 2)
                for t in np.linspace(0, math.pi, 13)]
    outline += [add(add(wrist, n, -width / 2), u, length * 0.45), add(wrist, n, -width / 2 * 0.9)]
    base = add(add(wrist, n, thumb * width * 0.42), u, length * 0.25)
    c.capsule(base, 5, add(add(base, n, thumb * 6), u, 11), 4, colour)
    c.polygon(outline, colour)
    for k in (-0.25, 0.08, 0.38):
        start = add(add(wrist, n, -k * width * thumb), u, length * 0.62)
        c.line([start, add(start, u, length * 0.3)], SKIN_SHADE, 1.0)
    if palm_up:
        c.line([add(add(wrist, n, -width * 0.25), u, length * 0.25),
                add(add(wrist, n, width * 0.2), u, length * 0.4)], SKIN_SHADE, 1.2)


def arm(c, shoulder, elbow, wrist, toward=None, palm_up=False, thumb=1):
    c.capsule(shoulder, 11.5, elbow, 9.5, SHIRT)
    c.capsule(elbow, 9.5, add(wrist, unit(vec(elbow, wrist)), -3), 8, SHIRT)
    hand(c, wrist, toward or vec(elbow, wrist), palm_up, thumb)


def helper_arm(c, at, toward, start, thumb=1):
    """The helper's arm, reaching in from beyond the panel's edge."""
    c.capsule(start, 14, add(at, unit(toward), -6), 10, SLEEVE)
    hand(c, at, toward, False, thumb, width=19, length=28)


def shoe_up(c, ankle, toward):
    """Lying on the back, toes up: the shoe seen from above, short."""
    u = unit(toward)
    c.capsule(add(ankle, u, -2), 11, add(ankle, u, 16), 12.5, SHOE)
    c.capsule(add(ankle, u, 8), 6, add(ankle, u, 17), 7, (90, 90, 98), outline=None)


def shoe_flat(c, ankle, toward):
    """Standing on its sole, seen from above: the whole length, laces."""
    u = unit(toward)
    n = perp(u)
    c.capsule(add(ankle, u, -4), 11, add(ankle, u, 40), 12, SHOE)
    for k in (8, 15, 22):
        c.line([add(add(ankle, u, k), n, -5), add(add(ankle, u, k), n, 5)], (150, 150, 158), 1.4)


def shoe_on_side(c, ankle, toes):
    """Lying on its side, seen from above: the profile, the sole on the
    side away from the body."""
    u = unit(toes)
    n = perp(u)
    c.polygon([add(add(ankle, n, a), u, b) for a, b in
               ((10, -10), (11, 6), (6, 22), (2, 36), (-6, 40), (-11, 30), (-12, -2), (-9, -12))],
              SHOE, smooth=2)
    c.line([add(add(ankle, n, -10), u, -10), add(add(ankle, n, -10.5), u, 30),
            add(add(ankle, n, -5), u, 38)], SOLE, 2.6, smooth=1)
    for t in (4, 12):
        c.line([add(add(ankle, n, 8), u, t), add(add(ankle, n, 3), u, t + 4)], (140, 140, 148), 1.3)


def leg(c, hip, knee, ankle, shoe=True):
    c.capsule(knee, 13, add(ankle, unit(vec(knee, ankle)), -2), 10, JEANS)
    c.capsule(hip, 17, knee, 13.5, JEANS)
    if shoe:
        shoe_up(c, ankle, vec(knee, ankle))


def knee_up(c, hip, knee, ankle):
    """The knee drawn up, the foot flat: seen from above the leg folds
    into a V, the knee on top and a shadow beneath."""
    c.ellipse(add(lerp(hip, ankle, 0.55), (6, 14)), 46, 13, 0, (210, 222, 230), outline=None)
    shoe_flat(c, ankle, (1, 0))
    c.capsule(knee, 12, add(ankle, unit(vec(knee, ankle)), -2), 10, JEANS_SHADE)
    c.capsule(hip, 17, knee, 14, JEANS)
    c.ellipse(knee, 14, 13, 0, JEANS)
    c.ellipse(add(knee, (-2, -2)), 7, 6, 0, (78, 94, 136), outline=None)


def torso_on_back(c):
    half = [(34, 12), (44, 30), (56, 46), (72, 55), (90, 54), (120, 49), (158, 42),
            (190, 45), (206, 40), (214, 24)]
    c.polygon([(x, -y) for x, y in half] + [(218, 0)] + [(x, y) for x, y in reversed(half)] + [(30, 0)],
              SHIRT, smooth=2)
    c.line([(40, -13), (50, 0), (40, 13)], SHIRT_SHADE, 1.6, smooth=1)
    c.polygon([(184, -46), (206, -40), (215, -24), (219, 0), (215, 24), (206, 40), (184, 46), (188, 0)],
              JEANS, smooth=2)


def head_on_back(c, centre, rx=33, ry=25):
    """Face up, crown to the left."""
    x, y = centre
    for side in (-1, 1):
        c.ellipse((x + 4, y + side * (ry + 1)), 7, 5, 0, SKIN)
    c.ellipse(centre, rx, ry, 0, SKIN)
    crown = [(x + rx * math.cos(t) * 1.04, y + ry * math.sin(t) * 1.06)
             for t in np.linspace(math.pi * 0.58, math.pi * 1.42, 25)]
    hairline = [(x - rx * 0.42, y - ry * 0.80), (x - rx * 0.56, y - ry * 0.35),
                (x - rx * 0.48, y + ry * 0.05), (x - rx * 0.58, y + ry * 0.45),
                (x - rx * 0.42, y + ry * 0.80)]
    c.polygon(crown + hairline, HAIR, smooth=2)
    for side in (-1, 1):
        c.line([(x - 4, y + side * 9), (x - 1, y + side * 13.5)], OUTLINE, 1.5)
        c.line([(x - 10, y + side * 8), (x - 9, y + side * 15)], HAIR_SHADE, 1.6)
    c.line([(x + 6, y - 1.5), (x + 11, y + 0.5)], SKIN_SHADE, 2.0)
    c.line([(x + 19, y - 5), (x + 19.5, y + 5)], LIPS, 1.8)


def torso_on_side(c):
    """On the side, facing the helper: the back up, the chest down."""
    c.polygon([(36, 8), (48, -6), (70, -12), (110, -14), (150, -12), (185, -6), (212, 2),
               (222, 22), (214, 46), (190, 54), (160, 56), (120, 62), (86, 62), (62, 54),
               (44, 42), (34, 30)], SHIRT, smooth=2)
    c.polygon([(182, -6), (212, 2), (222, 22), (214, 46), (190, 54), (184, 54), (188, 24)],
              JEANS, smooth=2)
    c.line([(80, -4), (150, -4)], SHIRT_SHADE, 1.4)


def head_on_side(c, centre, tilt=0.0):
    """In profile, crown to the left, face toward the helper. [tilt]
    turns it back: the face toward the crown, the chin from the chest."""
    def at(*points):
        return [add(centre, rot(p, tilt)) for p in points]

    c.capsule(*at((22, 0)), 14, *at((44, 6)), 15, SKIN)
    c.polygon(at((24, -14), (12, -25), (-6, -28), (-22, -21), (-31, -6), (-31, 8), (-26, 18),
                 (-18, 25), (-10, 27.5), (-5, 26), (-1, 27.5), (6, 35), (8.5, 30), (11.5, 30.5),
                 (13, 29), (15.5, 31), (19, 28.5), (24, 31), (29, 26), (31, 14), (30, 0)),
              SKIN, smooth=1)
    c.polygon(at((-26, 18), (-31, 8), (-31, -6), (-22, -21), (-6, -28), (12, -25), (24, -14),
                 (20, -9), (12, -6), (4, -9), (-4, -3), (-10, 3), (-16, 6), (-21, 12)),
              HAIR, smooth=2)
    c.line(at((-24, -4), (-10, -14), (6, -18)), HAIR_SHADE, 1.4, smooth=2)
    c.polygon(at(*[(6 + 6 * math.cos(t), 4 + 8.5 * math.sin(t))
                   for t in np.linspace(0, 2 * math.pi, 24, endpoint=False)]), SKIN)
    c.line(at((8, -1), (5, 3), (7.5, 8)), SKIN_SHADE, 1.6, smooth=1)
    c.line(at((-8, 21.5), (-4, 23), (0, 22)), OUTLINE, 1.5, smooth=1)
    c.line(at((-12, 18), (-6, 18.8), (-1, 18)), HAIR_SHADE, 1.8, smooth=1)
    c.line(at((12.5, 29.5), (9.5, 27.5)), LIPS, 1.5)


def right_angle(c, corner, a, b, size=13):
    p1 = add(corner, unit(a), size)
    c.line([p1, add(p1, unit(b), size), add(corner, unit(b), size)], RED, 2.6)


def arrow(c, points, width=4.0, head=13, smooth=3):
    for _ in range(smooth):
        points = chaikin(points, closed=False)
    tip = points[-1]
    back = unit(vec(points[-1], points[-3]))
    base = add(tip, back, head)
    c.line(points[:-2] + [base], RED, width)
    n = perp(back)
    c.polygon([tip, add(base, n, head * 0.55), add(base, n, -head * 0.55)], RED, outline=None)


# ---- the seven steps ---------------------------------------------------------
FAR_SHOULDER, NEAR_SHOULDER = (62, -46), (62, 46)
FAR_HIP, NEAR_HIP = (200, -24), (200, 24)


def legs_straight(c):
    leg(c, FAR_HIP, (305, -26), (405, -27))
    leg(c, NEAR_HIP, (305, 26), (405, 27))


def arms_by_side(c, near=True):
    arm(c, FAR_SHOULDER, (128, -66), (190, -64), thumb=1)
    if near:
        arm(c, NEAR_SHOULDER, (128, 66), (190, 64), thumb=-1)


def near_arm_up(c):
    """At a right angle to the body, the forearm toward the head, palm up."""
    arm(c, NEAR_SHOULDER, (62, 118), (0, 118), toward=(-1, 0), palm_up=True)


def far_arm_across(c):
    """Over the chest, the back of the hand against the near cheek."""
    wrist = (8, 33)
    elbow = reach(FAR_SHOULDER, wrist, 70, 64, bend=-1)
    c.capsule(FAR_SHOULDER, 11.5, elbow, 9.5, SHIRT)
    c.capsule(elbow, 9.5, wrist, 8, SHIRT)
    hand(c, wrist, (-0.35, -1), thumb=-1)


def kneel_and_straighten(c, helpers=True):
    legs_straight(c)
    arms_by_side(c)
    torso_on_back(c)
    head_on_back(c, (-4, 0))
    if helpers:
        helper_arm(c, (300, 30), (0, -1), (330, 400), thumb=-1)
        helper_arm(c, (372, 30), (0, -1), (402, 400), thumb=-1)


def near_arm(c, helpers=True):
    legs_straight(c)
    arms_by_side(c, near=False)
    near_arm_up(c)
    torso_on_back(c)
    head_on_back(c, (-4, 0))
    arrow(c, [(176, 92), (150, 128), (100, 140), (40, 140)], width=3.6)
    right_angle(c, (74, 57), (0, 1), (1, 0), 15)
    right_angle(c, (52, 106), (0, -1), (-1, 0), 15)


def far_arm(c, helpers=True):
    legs_straight(c)
    near_arm_up(c)
    torso_on_back(c)
    head_on_back(c, (-4, 0))
    far_arm_across(c)
    if helpers:
        helper_arm(c, (-14, 52), (0.25, -1), (-60, 400), thumb=1)


def far_knee(c, helpers=True):
    leg(c, NEAR_HIP, (305, 26), (405, 27))
    knee_up(c, FAR_HIP, (258, -64), (304, -30))
    near_arm_up(c)
    torso_on_back(c)
    head_on_back(c, (-4, 0))
    far_arm_across(c)
    arrow(c, [(292, -78), (320, -40), (318, 30)], width=4.5, head=15)
    if helpers:
        helper_arm(c, (-14, 52), (0.25, -1), (-60, 400), thumb=1)
        helper_arm(c, (250, -50), (-0.25, -1), (330, 400), thumb=-1)


def on_side(c, tilt=0.0):
    """Rolled toward the helper. The lower arm lies at a right angle as
    it was placed; the upper hand is under the cheek; the upper leg is
    bent at hip and knee, the lower one straight."""
    leg(c, (198, 28), (302, 30), (400, 30), shoe=False)
    shoe_on_side(c, (402, 32), (0, 1))
    arm(c, (66, 50), (66, 122), (2, 122), toward=(-1, 0), palm_up=True)
    torso_on_side(c)
    c.capsule((198, 128), 13, (296, 128), 10, JEANS_SHADE)
    shoe_on_side(c, (300, 130), (0, 1))
    c.capsule((196, 18), 17.5, (198, 128), 14, JEANS)
    c.ellipse((198, 128), 14, 13.5, 0, JEANS)
    hand(c, (24, 62), (-1, -0.15), thumb=-1)
    head_on_side(c, (-4, 26), tilt)
    c.capsule((64, 14), 12, (96, 66), 9.5, SHIRT)
    c.capsule((96, 66), 9.5, (27, 62), 8, SHIRT)


def upper_leg(c, helpers=True):
    on_side(c)
    right_angle(c, (212, 114), (0, -1), (1, 0))
    right_angle(c, (179, 58), (-1, 0), (0, 1))


def head_back(c, helpers=True):
    on_side(c, tilt=0.35)
    # Around the face, toward the crown: the way the head turns.
    arrow(c, [add((-4, 26), rot((0, 50), a)) for a in np.linspace(-0.55, 1.05, 16)],
          width=3.2, head=10, smooth=1)


# Close up on the head: (left, top, right, bottom) in figure units, and
# its scale.
head_back.view = (-95, -20, 175, 96)
head_back.scale = 1.4

STEPS = [
    ("Neben der Person knien,", "Beine gerade legen.", kneel_and_straighten),
    ("Nahen Arm im rechten Winkel", "nach oben, Handfläche nach oben.", near_arm),
    ("Fernen Arm über die Brust,", "Handrücken an die nahe Wange.", far_arm),
    ("Fernes Knie anwinkeln, am", "Knie zu dir herüberziehen.", far_knee),
    ("Oberes Bein ausrichten: Hüfte", "und Knie im rechten Winkel.", upper_leg),
    ("Kopf nach hinten neigen:", "Mund ist der tiefste Punkt.", head_back),
]


# ---- the chart ---------------------------------------------------------------

def rounded(image, box, radius, fill, outline=None):
    def paint(d, s, at):
        d.rounded_rectangle(at(*box), radius=radius * s, fill=fill + (255,),
                            outline=outline + (255,) if outline else None, width=s)
    x0, y0, x1, y1 = box
    cp._drawn(image, (x0 - 2, y0 - 2, x1 + 2, y1 + 2), paint)


def disc(image, centre, radius, fill):
    def paint(d, s, at):
        x, y = at(*centre)
        d.ellipse((x - radius * s, y - radius * s, x + radius * s, y + radius * s), fill=fill + (255,))
    cp._drawn(image, (centre[0] - radius - 3, centre[1] - radius - 3,
                      centre[0] + radius + 3, centre[1] + radius + 3), paint)


def number(image, centre, n):
    disc(image, centre, 37, GREEN)
    cp._centred(image, centre[0], centre[1] + 18, str(n), 50, WHITE, HELVETICA_BOLD)


def extent(pose):
    """The figure's extent in figure units, without the helper's arms
    (they reach in from outside)."""
    c = Canvas(1400, 1000, lambda p: (p[0] + 500, p[1] + 500), s=1)
    pose(c, helpers=False)
    alpha = np.asarray(c.image)[..., 3]
    ys, xs = np.nonzero(alpha > 8)
    return xs.min() - 500, ys.min() - 500, xs.max() - 500, ys.max() - 500


def figure(image, panel, pose, area):
    """Draws [pose] into [panel], fitted and centred in [area] (relative
    to the panel), and clipped to the panel's rounded corners."""
    x0, y0, x1, y1 = panel
    ax0, ay0, ax1, ay1 = area
    bx0, by0, bx1, by1 = getattr(pose, "view", None) or extent(pose)
    scale = min(getattr(pose, "scale", 0.72), (ax1 - ax0) / (bx1 - bx0), (ay1 - ay0) / (by1 - by0))
    ox = ax0 + ((ax1 - ax0) - (bx1 - bx0) * scale) / 2 - bx0 * scale
    oy = ay0 + ((ay1 - ay0) - (by1 - by0) * scale) / 2 - by0 * scale
    c = Canvas(x1 - x0, y1 - y0, lambda p: (ox + p[0] * scale, oy + p[1] * scale))
    pose(c)
    layer = c.done()
    mask = Image.new("L", ((x1 - x0) * 4, (y1 - y0) * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, (x1 - x0) * 4 - 1, (y1 - y0) * 4 - 1),
                                           radius=48, fill=255)
    mask = np.asarray(mask.resize((x1 - x0, y1 - y0), Image.LANCZOS)).astype(float) / 255
    layer.putalpha(Image.fromarray((np.asarray(layer)[..., 3] * mask).astype(np.uint8)))
    image.paste(layer, (x0, y0), layer)


def header(image):
    rounded(image, (16, 2, 1008, 148), 13, BANNER)
    set_line(image, 47, 86, "STABILE SEITENLAGE", 90.7, WHITE, face=HEAVY, stretch=0.87)
    set_line(image, 50, 128, "Bewusstlos, aber normale Atmung.", 37, WHITE, face=CONDENSED_DEMI)

    # The app's line drawing of the position, in white: the ground, the
    # head, the back, the arm under the head, the upper leg at right
    # angles, the lower leg straight.
    def drawing(d, s, at):
        k = 1.85
        w = round(6 * s)
        white = WHITE + (255,)

        def path(*points):
            xy = [c for x, y in points for c in at(830 + x * k, -22 + y * k)]
            d.line(xy, fill=white, width=w, joint="curve")
            for x, y in (xy[:2], xy[-2:]):
                d.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=white)

        path((8, 80), (92, 80))
        x, y = at(830 + 24 * k, -22 + 56 * k)
        r = 9 * k * s
        d.ellipse((x - r, y - r, x + r, y + r), outline=white, width=w)
        path(*[((1 - t) ** 2 * 33 + 2 * (1 - t) * t * 50 + t * t * 66,
                (1 - t) ** 2 * 60 + 2 * (1 - t) * t * 52 + t * t * 62)
               for t in np.linspace(0, 1, 16)])
        path((38, 62), (34, 74), (23, 68))
        path((66, 62), (78, 68), (76, 80))
        path((66, 66), (86, 76))

    cp._drawn(image, (820, 4, 1006, 146), drawing)


def steps(image):
    columns = [(18, 506), (518, 1006)]
    rows = [(156, 422), (430, 696), (704, 970)]
    for i, (first, second, pose) in enumerate(STEPS):
        x0, x1 = columns[i % 2]
        y0, y1 = rows[i // 2]
        rounded(image, (x0, y0, x1, y1), 12, PANEL, PANEL_EDGE)
        figure(image, (x0, y0, x1, y1), pose, (14, 96, x1 - x0 - 14, y1 - y0 - 8))
        number(image, (x0 + 46, y0 + 46), i + 1)
        widest = max(text_width(line, 29, CONDENSED_BOLD) for line in (first, second))
        size = min(29, 29 * (x1 - x0 - 106) / widest)
        set_line(image, x0 + 94, y0 + 42, first, size, NAVY, face=CONDENSED_BOLD)
        set_line(image, x0 + 94, y0 + 75, second, size, NAVY, face=CONDENSED_BOLD)


def breathing(image):
    x0, y0, x1, y1 = 18, 978, 1006, 1162
    rounded(image, (x0, y0, x1, y1), 12, PANEL, PANEL_EDGE)
    number(image, (x0 + 46, y0 + 46), 7)
    set_line(image, x0 + 94, y0 + 42, "Atmung weiter beobachten.", 29, NAVY, face=CONDENSED_BOLD)
    for i, line in enumerate(("Hört sie auf oder wird sie unnormal:",
                              "auf den Rücken drehen und mit der",
                              "Wiederbelebung beginnen.")):
        set_line(image, x0 + 94, y0 + 82 + 29 * i, line, 25, INK)
    # Hören, Sehen, Fühlen, from "Bewusstlose Person prüfen": taken as
    # ink, which leaves the pale bubbles between them behind.
    k = cp.ink(Image.open(ASSETS / "unresponsive.webp").convert("RGB"), (722, 352, 1000, 456))
    alpha = Image.fromarray((np.clip((k.alpha - 0.45) / 0.55, 0, 1) * 255).astype(np.uint8))
    alpha = alpha.resize((round(alpha.width * 1.3), round(alpha.height * 1.3)), Image.LANCZOS)
    cp.paste_ink(image, (x0 + 600, y0 + 26), np.asarray(alpha).astype(float) / 255, k.colour)


def cautions(image):
    x0, y0, x1, y1 = 18, 1170, 1006, 1362
    rounded(image, (x0, y0, x1, y1), 14, NOTE)
    middle = (y0 + y1) // 2
    disc(image, (x0 + 52, middle), 34, (27, 92, 163))
    cp._centred(image, x0 + 52, middle + 19, "i", 58, WHITE, GEORGIA_BOLD)
    set_line(image, x0 + 104, middle + 15, "Wichtig", 44, (8, 10, 155), face=HELVETICA_BOLD)
    y = y0 + 52
    for bullet, line in ((True, "Nach spätestens 30 Minuten auf die andere Seite drehen."),
                         (True, "Verdacht auf eine Verletzung der Wirbelsäule: nur drehen,"),
                         (False, "wenn die Atemwege anders nicht frei zu halten sind."),
                         (False, "Freie Atemwege haben Vorrang.")):
        if bullet:
            y += 8
            cp.dot(image, (x0 + 282, y - 8), 4, INK)
        set_line(image, x0 + 300, y, line, 25, INK)
        y += 30


def remember(image):
    band = Image.open(ASSETS / "cuts-and-grazes.webp").convert("RGB").crop((0, 1370, W, H))
    image.paste(band, (0, 1370))
    cp.erase(image, (215, 1396, 1000, 1478))
    for baseline, line in ((1427, "Stabile Seitenlage nur bei normaler Atmung."),
                           (1463, "Die Atmung ständig weiter beobachten.")):
        set_line(image, 226, baseline, line, 29.8, (31, 41, 61), face=HELVETICA)


def chart():
    image = Image.new("RGB", (W, H), PAGE)
    header(image)
    steps(image)
    breathing(image)
    cautions(image)
    remember(image)
    return image


def main():
    chart().save(TARGET, "WEBP", quality=QUALITY, method=6)
    with Image.open(TARGET) as written:
        print(f"{Path(TARGET).relative_to(APP)}  {written.width}x{written.height}  "
              f"{TARGET.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
